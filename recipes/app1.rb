#
# Cookbook:: osl-app
# Recipe:: app1
#
# Copyright:: 2016-2024, Oregon State University
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
    "BRAINTREE_ACCESS_TOKEN=#{openid_secrets['braintree_access_token']}",
    "RECAPTCHA_SITE_KEY=#{openid_secrets['recaptcha_site_key']}",
    "RECAPTCHA_SECRET_KEY=#{openid_secrets['recaptcha_secret_key']}",
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

docker_container 'registry.osuosl.org' do
  repo 'registry'
  tag '2'
  restart_policy 'always'
  sensitive true
  env [
    'REGISTRY_STORAGE=s3',
    "REGISTRY_STORAGE_S3_ACCESSKEY=#{registry_secrets['access_key']}",
    "REGISTRY_STORAGE_S3_SECRETKEY=#{registry_secrets['secret_key']}",
    'REGISTRY_STORAGE_S3_REGION=us-east-1',
    'REGISTRY_STORAGE_S3_BUCKET=osuosl-registry',
    'REGISTRY_STORAGE_S3_ENDPOINT=s3.osuosl.org',
    'REGISTRY_AUTH=htpasswd',
    'REGISTRY_AUTH_HTPASSWD_REALM="Registry Realm"',
    'REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd',
    'REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io',
    "REGISTRY_PROXY_USERNAME=#{registry_secrets['docker_username']}",
    "REGISTRY_PROXY_PASSWORD=#{registry_secrets['docker_password']}",
  ]
  volumes ['/usr/local/etc/registry.osuosl.org:/auth']
  port '8082:5000'
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
