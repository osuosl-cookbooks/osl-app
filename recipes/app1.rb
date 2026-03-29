#
# Cookbook:: osl-app
# Recipe:: app1
#
# Copyright:: 2016-2026, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'osl-app::default'
include_recipe 'htpasswd'

users = search('users', '*:*')

users_manage 'app1' do
  users users
end

openid_secrets = data_bag_item('osl-app', 'openid')
openid_db_host = node['kitchen'] ? node['ipaddress'] : openid_secrets['db_host']
registry_secrets = data_bag_item('osl-app', 'registry')

ghcr_io = ghcr_io_credentials

docker_registry 'ghcr.io' do
  username ghcr_io['username']
  password ghcr_io['password']
end

docker_image 'oidf-members-develop' do
  repo 'ghcr.io/openid-foundation/oidf-members'
  tag 'develop'
  notifies :redeploy, 'docker_container[openid-staging-website]'
  notifies :redeploy, 'docker_container[openid-staging-delayed-job]'
end

docker_image 'oidf-members-master' do
  repo 'ghcr.io/openid-foundation/oidf-members'
  tag 'master'
  notifies :redeploy, 'docker_container[openid-production-website]'
  notifies :redeploy, 'docker_container[openid-production-delayed-job]'
end

docker_image 'registry' do
  tag '2'
  notifies :redeploy, 'docker_container[registry.osuosl.org]'
end

docker_container 'openid-staging-website' do
  repo 'ghcr.io/openid-foundation/oidf-members'
  tag 'develop'
  port '8080:8080'
  restart_policy 'always'
  init true
  command '/usr/src/app/entrypoint.sh'
  env [
    'RAILS_ENV=staging',
    "DB_PASSWORD=#{openid_secrets['db_password']}",
    "DB_HOST=#{openid_db_host}",
    'BRAINTREE_ENV=sandbox',
    "SECRET_KEY_BASE=#{openid_secrets['secret_key_base']}",
    "BRAINTREE_ACCESS_TOKEN=#{openid_secrets['braintree_access_token']}",
    "RECAPTCHA_SITE_KEY=#{openid_secrets['recaptcha_site_key']}",
    "RECAPTCHA_SECRET_KEY=#{openid_secrets['recaptcha_secret_key']}",
    'HELLO_ISSUER=https://issuer.hello.coop',
    "HELLO_CLIENT_ID=#{openid_secrets['staging']['hello_client_id']}",
    "HELLO_CLIENT_SECRET=#{openid_secrets['staging']['hello_client_secret']}",
  ]
  sensitive true
end

docker_container 'openid-production-website' do
  repo 'ghcr.io/openid-foundation/oidf-members'
  tag 'master'
  port '8081:8080'
  restart_policy 'always'
  init true
  command '/usr/src/app/entrypoint.sh'
  env [
    'RAILS_ENV=production',
    "DB_PASSWORD=#{openid_secrets['db_password']}",
    "DB_HOST=#{openid_db_host}",
    "SECRET_KEY_BASE=#{openid_secrets['secret_key_base']}",
    'BRAINTREE_ENV=production',
    "BRAINTREE_ACCESS_TOKEN=#{openid_secrets['braintree_access_token']}",
    "RECAPTCHA_SITE_KEY=#{openid_secrets['recaptcha_site_key']}",
    "RECAPTCHA_SECRET_KEY=#{openid_secrets['recaptcha_secret_key']}",
    'HELLO_ISSUER=https://issuer.hello.coop',
    "HELLO_CLIENT_ID=#{openid_secrets['production']['hello_client_id']}",
    "HELLO_CLIENT_SECRET=#{openid_secrets['production']['hello_client_secret']}",
  ]
  sensitive true
end

docker_container 'openid-staging-delayed-job' do
  repo 'ghcr.io/openid-foundation/oidf-members'
  tag 'develop'
  restart_policy 'always'
  command '/usr/src/app/entrypoint-delayed-job.sh'
  env [
    'RAILS_ENV=staging',
    "DB_PASSWORD=#{openid_secrets['db_password']}",
    "DB_HOST=#{openid_db_host}",
    "SECRET_KEY_BASE=#{openid_secrets['secret_key_base']}",
  ]
  sensitive true
end

docker_container 'openid-production-delayed-job' do
  repo 'ghcr.io/openid-foundation/oidf-members'
  tag 'master'
  restart_policy 'always'
  command '/usr/src/app/entrypoint-delayed-job.sh'
  env [
    'RAILS_ENV=production',
    "DB_PASSWORD=#{openid_secrets['db_password']}",
    "DB_HOST=#{openid_db_host}",
  ]
  sensitive true
end

directory '/usr/local/etc/registry.osuosl.org' do
  recursive true
end

registry_secrets['htpasswds'].each do |u|
  htpasswd "#{u['username']} in /usr/local/etc/registry.osuosl.org/htpasswd" do
    file '/usr/local/etc/registry.osuosl.org/htpasswd'
    user u['username']
    password u['password']
    type u['type'] if u['type']
    notifies :redeploy, 'docker_container[registry.osuosl.org]'
  end
end

# Valkey for registry blob descriptor cache
docker_image 'valkey' do
  repo 'valkey/valkey'
  tag '8-alpine'
  notifies :redeploy, 'docker_container[registry-valkey]'
end

docker_container 'registry-valkey' do
  repo 'valkey/valkey'
  tag '8-alpine'
  restart_policy 'always'
  command 'valkey-server --appendonly yes --maxmemory 256mb --maxmemory-policy allkeys-lru'
  volumes ['registry-valkey-data:/data']
  health_check(
    'Test' => %w(CMD valkey-cli ping),
    'Interval' => 30_000_000_000,
    'Timeout' => 10_000_000_000,
    'Retries' => 3
  )
end

# Use filesystem for testing, S3 for production
registry_storage_env = if kitchen?
                         [
                           'REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry',
                         ]
                       else
                         [
                           'REGISTRY_STORAGE=s3',
                           "REGISTRY_STORAGE_S3_ACCESSKEY=#{registry_secrets['access_key']}",
                           "REGISTRY_STORAGE_S3_SECRETKEY=#{registry_secrets['secret_key']}",
                           'REGISTRY_STORAGE_S3_REGION=us-east-1',
                           'REGISTRY_STORAGE_S3_BUCKET=osuosl-registry',
                           'REGISTRY_STORAGE_S3_REGIONENDPOINT=s3.osuosl.org',
                           # 100MB chunks (up from 5MB default) - reduces S3 API calls for large layers
                           'REGISTRY_STORAGE_S3_CHUNKSIZE=104857600',
                           # 100MB multipart copy chunks - improves cross-repo blob mounting performance
                           'REGISTRY_STORAGE_S3_MULTIPARTCOPYCHUNKSIZE=104857600',
                           # 32 concurrent uploads (up from 100 default) - balances throughput vs memory usage
                           'REGISTRY_STORAGE_S3_MULTIPARTCOPYMAXCONCURRENCY=32',
                         ]
                       end

docker_container 'registry.osuosl.org' do
  repo 'registry'
  tag '2'
  restart_policy 'always'
  sensitive true
  links ['registry-valkey:redis']
  env registry_storage_env + [
    # Redis/Valkey cache for blob descriptors (persistent, survives restarts)
    'REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=redis',
    'REGISTRY_REDIS_ADDR=redis:6379',
    # Proxy/mirror configuration
    'REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io',
    "REGISTRY_PROXY_USERNAME=#{registry_secrets['docker_username']}",
    "REGISTRY_PROXY_PASSWORD=#{registry_secrets['docker_password']}",
    # HTTP performance settings
    'REGISTRY_HTTP_DRAINTIMEOUT=60s',
  ]
  volumes ['/usr/local/etc/registry.osuosl.org:/auth']
  port '8082:5000'
  health_check(
    'Test' => ['CMD', 'wget', '--spider', '-q', 'http://localhost:5000/v2/'],
    'Interval' => 30_000_000_000,
    'Timeout' => 10_000_000_000,
    'Retries' => 3
  )
end

osl_app_docker_wrapper 'openid-staging-website' do
  user 'openid-staging'
end

osl_app_docker_wrapper 'openid-staging-delayed-job' do
  user 'openid-staging'
end

osl_app_docker_wrapper 'openid-production-website' do
  user 'openid-production'
end

osl_app_docker_wrapper 'openid-production-delayed-job' do
  user 'openid-production'
end
