#
# Cookbook:: osl-app
# Recipe:: app3
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
include_recipe 'osl-nginx'

# Save nginx service for later use
service 'nginx' do
  action :nothing
end

users = search('users', '*:*')

users_manage 'app3' do
  users users
end

streamwebs_secrets = data_bag_item('osl-app', 'streamwebs')
ghcr_io = ghcr_io_credentials

docker_registry 'ghcr.io' do
  username ghcr_io['username']
  password ghcr_io['password']
end

docker_image 'streamwebs-develop' do
  repo 'ghcr.io/osuosl/streamwebs'
  tag 'develop'
  notifies :redeploy, 'docker_container[streamwebs-staging.osuosl.org]'
end

docker_image 'streamwebs-master' do
  repo 'ghcr.io/osuosl/streamwebs'
  tag 'master'
  notifies :redeploy, 'docker_container[streamwebs.org]'
end

template '/home/streamwebs-staging/settings.py' do
  variables(secrets: streamwebs_secrets['staging'])
  sensitive true
  notifies :redeploy, 'docker_container[streamwebs-staging.osuosl.org]'
end

template '/home/streamwebs-production/settings.py' do
  variables(secrets: streamwebs_secrets['production'])
  sensitive true
  notifies :redeploy, 'docker_container[streamwebs.org]'
end

docker_container 'streamwebs-staging.osuosl.org' do
  repo 'ghcr.io/osuosl/streamwebs'
  tag 'develop'
  port '8081:8000'
  restart_policy 'always'
  command '/usr/src/app/entrypoint.sh'
  volumes [
    '/home/streamwebs-staging/media:/usr/src/app/media',
    '/home/streamwebs-staging/settings.py:/usr/src/app/streamwebs_frontend/streamwebs_frontend/settings.py',
  ]
end

docker_container 'streamwebs.org' do
  repo 'ghcr.io/osuosl/streamwebs'
  tag 'master'
  port '8080:8000'
  restart_policy 'always'
  command '/usr/src/app/entrypoint.sh'
  volumes [
    '/home/streamwebs-production/media:/usr/src/app/media',
    '/home/streamwebs-production/settings.py:/usr/src/app/streamwebs_frontend/streamwebs_frontend/settings.py',
  ]
end

# Nginx
node.default['osl-app']['nginx'] = {
  'streamwebs.org' => {
    'uri' => '/streamwebs-production/media',
    'folder' => '/home/streamwebs-production/media',
  },
  'streamwebs-staging.osuosl.org' => {
    'uri' => '/streamwebs-staging/media',
    'folder' => '/home/streamwebs-staging/media',
  },
}

# Give nginx access to their homedirs
%w(production staging).each do |env|
  group "streamwebs-#{env}" do
    members 'nginx'
    action :modify
    append true
    notifies :restart, 'service[nginx]'
  end
end

nginx_app 'app3.osuosl.org' do
  template 'app-nginx.erb'
  cookbook 'osl-app'
  notifies :restart, 'service[nginx]'
end

# Docker containers
directory '/data/docker/code.mulgara.org' do
  recursive true
end

mulgara_redmine_creds = data_bag_item('mulgara_redmine', 'mysql_creds')
mulgara_redmine_creds['db_hostname'] = node['ipaddress'] if node['kitchen']

docker_image 'ghcr.io/osuosl/redmine-mulgara' do
  tag 'latest'
  notifies :redeploy, 'docker_container[code.mulgara.org]'
end

docker_container 'code.mulgara.org' do
  repo 'ghcr.io/osuosl/redmine-mulgara'
  tag 'latest'
  port '8084:3000'
  restart_policy 'always'
  volumes ['/data/docker/code.mulgara.org:/usr/src/redmine/files']
  env [
    "REDMINE_DB_MYSQL=#{mulgara_redmine_creds['db_hostname']}",
    "REDMINE_DB_DATABASE=#{mulgara_redmine_creds['db_db']}",
    "REDMINE_DB_USERNAME=#{mulgara_redmine_creds['db_user']}",
    "REDMINE_DB_PASSWORD=#{mulgara_redmine_creds['db_passwd']}",
    'REDMINE_PLUGINS_MIGRATE=1',
  ]
  sensitive true
end

etherpad_osl_secrets = data_bag_item('etherpad', 'osl')
etherpad_osl_secrets['db_hostname'] = node['ipaddress'] if node['kitchen']

docker_image 'etherpad/etherpad' do
  notifies :redeploy, 'docker_container[etherpad-lite.osuosl.org]'
end

docker_image 'ghcr.io/osuosl/etherpad-snowdrift' do
  notifies :redeploy, 'docker_container[etherpad-snowdrift.osuosl.org]'
end

docker_container 'etherpad-lite.osuosl.org' do
  repo 'etherpad/etherpad'
  port '8085:9001'
  restart_policy 'always'
  user 'etherpad'
  env [
    'DB_TYPE=mysql',
    'DB_CHARSET=utf8mb4',
    'DB_COLLECTION=utf8mb4_unicode_ci',
    "DB_HOST=#{etherpad_osl_secrets['db_hostname']}",
    "DB_NAME=#{etherpad_osl_secrets['db_db']}",
    "DB_USER=#{etherpad_osl_secrets['db_user']}",
    "DB_PASS=#{etherpad_osl_secrets['db_passwd']}",
    "ADMIN_PASSWORD=#{etherpad_osl_secrets['admin_passwd']}",
  ]
  sensitive true
end

etherpad_snowdrift_secrets = data_bag_item('etherpad', 'snowdrift')
etherpad_snowdrift_secrets['db_hostname'] = node['ipaddress'] if node['kitchen']

docker_container 'etherpad-snowdrift.osuosl.org' do
  repo 'ghcr.io/osuosl/etherpad-snowdrift'
  port '8086:9001'
  restart_policy 'always'
  user 'etherpad'
  env [
    'DB_TYPE=mysql',
    'DB_CHARSET=utf8mb4',
    'DB_COLLECTION=utf8mb4_unicode_ci',
    "DB_HOST=#{etherpad_snowdrift_secrets['db_hostname']}",
    "DB_NAME=#{etherpad_snowdrift_secrets['db_db']}",
    "DB_USER=#{etherpad_snowdrift_secrets['db_user']}",
    "DB_PASS=#{etherpad_snowdrift_secrets['db_passwd']}",
    "ADMIN_PASSWORD=#{etherpad_snowdrift_secrets['admin_passwd']}",
  ]
  sensitive true
end

# EEC Walkthrough React - Staging
eec_secrets = data_bag_item('osl-app', 'eec_walkthrough_staging')
eec_secrets['db_host'] = node['ipaddress'] if node['kitchen']

docker_image 'eec-walkthrough-react-dev' do
  repo 'ghcr.io/osu-cass/eec-walkthrough-react'
  tag 'dev'
  notifies :redeploy, 'docker_container[eec-walkthrough-staging.cass.oregonstate.edu]'
end

directory '/home/eec-walkthrough-staging/secrets' do
  recursive true
end

directory '/home/eec-walkthrough-staging/uploads' do
  recursive true
end

directory '/home/eec-walkthrough-staging/public-uploads' do
  recursive true
end

file '/home/eec-walkthrough-staging/secrets/mysql_password.txt' do
  mode '0400'
  content eec_secrets['db_passwd']
  sensitive true
  notifies :redeploy, 'docker_container[eec-walkthrough-staging.cass.oregonstate.edu]'
end

file '/home/eec-walkthrough-staging/secrets/jwt_secret_key.txt' do
  mode '0400'
  content eec_secrets['jwt_secret_key']
  sensitive true
  notifies :redeploy, 'docker_container[eec-walkthrough-staging.cass.oregonstate.edu]'
end

file '/home/eec-walkthrough-staging/secrets/sentry_dsn.txt' do
  mode '0400'
  content eec_secrets['sentry_dsn']
  sensitive true
  notifies :redeploy, 'docker_container[eec-walkthrough-staging.cass.oregonstate.edu]'
end

docker_container 'eec-walkthrough-staging.cass.oregonstate.edu' do
  repo 'ghcr.io/osu-cass/eec-walkthrough-react'
  tag 'dev'
  port ['8090:1111', '8091:2222']
  restart_policy 'always'
  env [
    'API_PORT=1111',
    'FILE_PORT=2222',
    'NODE_ENV=production',
    "MYSQL_DB_NAME=#{eec_secrets['db_db']}",
    "MYSQL_HOST=#{eec_secrets['db_host']}",
    'MYSQL_PORT=3306',
    "MYSQL_USER=#{eec_secrets['db_user']}",
    'MYSQL_PASSWORD_FILE=/run/secrets/mysql_password',
    'JWT_SECRET_KEY_FILE=/run/secrets/jwt_secret_key',
    'SENTRY_DSN_FILE=/run/secrets/sentry_dsn',
    "SENTRY_CLIENT_DSN=#{eec_secrets['sentry_client_dsn']}",
    'SENTRY_ENVIRONMENT=staging',
  ]
  volumes [
    '/home/eec-walkthrough-staging/secrets/mysql_password.txt:/run/secrets/mysql_password:ro',
    '/home/eec-walkthrough-staging/secrets/jwt_secret_key.txt:/run/secrets/jwt_secret_key:ro',
    '/home/eec-walkthrough-staging/secrets/sentry_dsn.txt:/run/secrets/sentry_dsn:ro',
    '/home/eec-walkthrough-staging/uploads:/app/client/files/uploads',
    '/home/eec-walkthrough-staging/public-uploads:/app/client/public/uploads',
  ]
  sensitive true
end

osl_app_docker_wrapper 'eec-walkthrough-staging.cass.oregonstate.edu' do
  user 'eec-walkthrough-staging'
end

# EEC Walkthrough React - Production
eec_production_secrets = data_bag_item('osl-app', 'eec_walkthrough_production')
eec_production_secrets['db_host'] = node['ipaddress'] if node['kitchen']

docker_image 'eec-walkthrough-react-main' do
  repo 'ghcr.io/osu-cass/eec-walkthrough-react'
  tag 'main'
  notifies :redeploy, 'docker_container[walkthrough.eec.oregonstate.edu]'
end

directory '/home/eec-walkthrough-production/secrets' do
  recursive true
end

directory '/home/eec-walkthrough-production/uploads' do
  recursive true
end

directory '/home/eec-walkthrough-production/public-uploads' do
  recursive true
end

file '/home/eec-walkthrough-production/secrets/mysql_password.txt' do
  mode '0400'
  content eec_production_secrets['db_passwd']
  sensitive true
  notifies :redeploy, 'docker_container[walkthrough.eec.oregonstate.edu]'
end

file '/home/eec-walkthrough-production/secrets/jwt_secret_key.txt' do
  mode '0400'
  content eec_production_secrets['jwt_secret_key']
  sensitive true
  notifies :redeploy, 'docker_container[walkthrough.eec.oregonstate.edu]'
end

file '/home/eec-walkthrough-production/secrets/sentry_dsn.txt' do
  mode '0400'
  content eec_production_secrets['sentry_dsn']
  sensitive true
  notifies :redeploy, 'docker_container[walkthrough.eec.oregonstate.edu]'
end

docker_container 'walkthrough.eec.oregonstate.edu' do
  repo 'ghcr.io/osu-cass/eec-walkthrough-react'
  tag 'main'
  port ['8092:1111', '8093:2222']
  restart_policy 'always'
  env [
    'API_PORT=1111',
    'FILE_PORT=2222',
    'NODE_ENV=production',
    "MYSQL_DB_NAME=#{eec_production_secrets['db_db']}",
    "MYSQL_HOST=#{eec_production_secrets['db_host']}",
    'MYSQL_PORT=3306',
    "MYSQL_USER=#{eec_production_secrets['db_user']}",
    'MYSQL_PASSWORD_FILE=/run/secrets/mysql_password',
    'JWT_SECRET_KEY_FILE=/run/secrets/jwt_secret_key',
    'SENTRY_DSN_FILE=/run/secrets/sentry_dsn',
    "SENTRY_CLIENT_DSN=#{eec_production_secrets['sentry_client_dsn']}",
    'SENTRY_ENVIRONMENT=production',
  ]
  volumes [
    '/home/eec-walkthrough-production/secrets/mysql_password.txt:/run/secrets/mysql_password:ro',
    '/home/eec-walkthrough-production/secrets/jwt_secret_key.txt:/run/secrets/jwt_secret_key:ro',
    '/home/eec-walkthrough-production/secrets/sentry_dsn.txt:/run/secrets/sentry_dsn:ro',
    '/home/eec-walkthrough-production/uploads:/app/client/files/uploads',
    '/home/eec-walkthrough-production/public-uploads:/app/client/public/uploads',
  ]
  sensitive true
end

osl_app_docker_wrapper 'walkthrough.eec.oregonstate.edu' do
  user 'eec-walkthrough-production'
end

# Oregon Invasives Hotline
invasives_staging = '/home/invasives-staging/oregoninvasiveshotline'
invasives_secrets = data_bag_item('osl-app', 'invasives')
invasives_secrets['staging']['db_host'] = node['ipaddress'] if node['kitchen']

git invasives_staging do
  repository 'https://github.com/osu-cass/oregoninvasiveshotline.git'
  revision 'develop'
  notifies :rebuild, 'osl_dockercompose[invasives-staging]'
end

template "#{invasives_staging}/.env" do
  source 'oregoninvasiveshotline-env.erb'
  mode '0400'
  variables(
    allowed_hosts: %w(staging.oregoninvasiveshotline.org),
    app_port: '8087',
    db_host: invasives_secrets['staging']['db_host'],
    db_name: invasives_secrets['staging']['db_name'],
    db_user: invasives_secrets['staging']['db_user'],
    email_host: 'mailpit',
    mailpit_port: '8088',
    mailpit_ui_auth: invasives_secrets['staging']['mailpit_ui_auth'],
    env: 'staging',
    image: 'develop',
    load_balancer_ips: "140.211.9.50,140.211.9.52,140.211.9.53,#{node['ipaddress']}",
    sentry_dsn: invasives_secrets['staging']['sentry_dsn'],
    sentry_sample_rate: '0.5',
    user_id: lazy { user_uid('invasives-staging') },
    volume_path: '/home/invasives-staging/volume'
  )
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-staging]'
end

directory "#{invasives_staging}/docker/secrets"

directory '/home/invasives-staging/volume/media' do
  owner 1000
  group 1000
  recursive true
end

directory '/home/invasives-staging/volume/static' do
  owner 1000
  group 1000
  recursive true
end

file "#{invasives_staging}/docker/secrets/secret_key.txt" do
  owner 1000
  group 1000
  mode '0400'
  content invasives_secrets['staging']['secret_key']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-staging]'
end

file "#{invasives_staging}/docker/secrets/db_password.txt" do
  owner 1000
  group 1000
  mode '0400'
  content invasives_secrets['staging']['db_pass']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-staging]'
end

file "#{invasives_staging}/docker/secrets/google_api_key.txt" do
  owner 1000
  group 1000
  mode '0400'
  content invasives_secrets['staging']['google_api_key']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-staging]'
end

file "#{invasives_staging}/docker/secrets/google_map_id.txt" do
  owner 1000
  group 1000
  mode '0400'
  content invasives_secrets['staging']['google_map_id']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-staging]'
end

docker_image 'ghcr.io/osu-cass/oregoninvasiveshotline-develop' do
  repo 'ghcr.io/osu-cass/oregoninvasiveshotline'
  tag 'develop'
  notifies :rebuild, 'osl_dockercompose[invasives-staging]'
end

osl_dockercompose 'invasives-staging' do
  directory invasives_staging
  config_files %w(docker-compose.deploy.yml docker-compose.mailpit.yml)
end

osl_app_dockercompose_wrapper 'invasives-staging' do
  directory invasives_staging
  config_files %w(docker-compose.deploy.yml docker-compose.mailpit.yml)
  user 'invasives-staging'
end

# Oregon Invasives Hotline - Production
invasives_production = '/home/invasives-production/oregoninvasiveshotline'
invasives_secrets['production']['db_host'] = node['ipaddress'] if node['kitchen']

git invasives_production do
  repository 'https://github.com/osu-cass/oregoninvasiveshotline.git'
  revision 'main'
  notifies :rebuild, 'osl_dockercompose[invasives-production]'
end

template "#{invasives_production}/.env" do
  source 'oregoninvasiveshotline-env.erb'
  mode '0400'
  variables(
    allowed_hosts: %w(oregoninvasiveshotline.org production.oregoninvasiveshotline.org),
    app_port: '8089',
    db_host: invasives_secrets['production']['db_host'],
    db_name: invasives_secrets['production']['db_name'],
    db_user: invasives_secrets['production']['db_user'],
    email_host: 'smtp.osuosl.org',
    env: 'production',
    image: 'main',
    load_balancer_ips: "140.211.9.50,140.211.9.52,140.211.9.53,#{node['ipaddress']}",
    sentry_dsn: invasives_secrets['production']['sentry_dsn'],
    sentry_sample_rate: '1.0',
    user_id: lazy { user_uid('invasives-production') },
    volume_path: '/home/invasives-production/volume'
  )
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-production]'
end

directory "#{invasives_production}/docker/secrets"

directory '/home/invasives-production/volume/media' do
  owner 1000
  group 1000
  recursive true
end

directory '/home/invasives-production/volume/static' do
  owner 1000
  group 1000
  recursive true
end

file "#{invasives_production}/docker/secrets/secret_key.txt" do
  owner 1000
  group 1000
  mode '0400'
  content invasives_secrets['production']['secret_key']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-production]'
end

file "#{invasives_production}/docker/secrets/db_password.txt" do
  owner 1000
  group 1000
  mode '0400'
  content invasives_secrets['production']['db_pass']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-production]'
end

file "#{invasives_production}/docker/secrets/google_api_key.txt" do
  owner 1000
  group 1000
  mode '0400'
  content invasives_secrets['production']['google_api_key']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-production]'
end

file "#{invasives_production}/docker/secrets/google_map_id.txt" do
  owner 1000
  group 1000
  mode '0400'
  content invasives_secrets['production']['google_map_id']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[invasives-production]'
end

docker_image 'ghcr.io/osu-cass/oregoninvasiveshotline-main' do
  repo 'ghcr.io/osu-cass/oregoninvasiveshotline'
  tag 'main'
  notifies :rebuild, 'osl_dockercompose[invasives-production]'
end

osl_dockercompose 'invasives-production' do
  directory invasives_production
  config_files %w(docker-compose.deploy.yml)
end

osl_app_dockercompose_wrapper 'invasives-production' do
  directory invasives_production
  config_files %w(docker-compose.deploy.yml)
  user 'invasives-production'
end

# HempDB - Staging
hempdb_staging = '/home/hemp-db-staging/hemp-db'
hempdb_staging_fqdn = 'hempdb-staging.cass.oregonstate.edu'
hempdb_secrets = data_bag_item('osl-app', 'hempdb')
hempdb_secrets['staging']['db_host'] = node['ipaddress'] if node['kitchen']

git hempdb_staging do
  repository 'https://github.com/osu-cass/hemp-db.git'
  revision 'dev'
  notifies :rebuild, 'osl_dockercompose[hempdb-staging]'
end

template "#{hempdb_staging}/.env" do
  source 'hemp-db-env.erb'
  mode '0400'
  variables(
    allowed_hosts: [hempdb_staging_fqdn, node['ipaddress']],
    app_port: '8094',
    database_ssl: !node['kitchen'],
    image: 'dev',
    mailpit_port: '8095',
    mailpit_ui_auth: hempdb_secrets['staging']['mailpit_ui_auth'],
    production_url: hempdb_staging_fqdn,
    sentry_dsn: hempdb_secrets['staging']['sentry_dsn']
  )
  sensitive true
  notifies :rebuild, 'osl_dockercompose[hempdb-staging]'
end

directory "#{hempdb_staging}/docker/secrets"

file "#{hempdb_staging}/docker/secrets/secret_key" do
  owner 1000
  group 1000
  mode '0400'
  content hempdb_secrets['staging']['secret_key']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[hempdb-staging]'
end

file "#{hempdb_staging}/docker/secrets/database_url" do
  owner 1000
  group 1000
  mode '0400'
  content 'mysql://' \
    "#{hempdb_secrets['staging']['db_user']}:#{hempdb_secrets['staging']['db_pass']}" \
    "@#{hempdb_secrets['staging']['db_host']}:3306/#{hempdb_secrets['staging']['db_name']}"
  sensitive true
  notifies :rebuild, 'osl_dockercompose[hempdb-staging]'
end

docker_image 'ghcr.io/osu-cass/hemp-db-dev' do
  repo 'ghcr.io/osu-cass/hemp-db'
  tag 'dev'
  notifies :rebuild, 'osl_dockercompose[hempdb-staging]'
end

osl_dockercompose 'hempdb-staging' do
  directory hempdb_staging
  config_files %w(compose.deploy.yaml compose.staging.yaml)
end

osl_app_dockercompose_wrapper 'hempdb-staging' do
  directory hempdb_staging
  config_files %w(compose.deploy.yaml compose.staging.yaml)
  user 'hemp-db-staging'
end

# HempDB - Production
hempdb_production = '/home/hemp-db-production/hemp-db'
hempdb_production_fqdn = 'hempdb.cass.oregonstate.edu'
hempdb_production_compose = %w(compose.deploy.yaml compose.prod.yaml)
hempdb_secrets['production']['db_host'] = node['ipaddress'] if node['kitchen']

git hempdb_production do
  repository 'https://github.com/osu-cass/hemp-db.git'
  revision 'main'
  notifies :rebuild, 'osl_dockercompose[hempdb-production]'
end

template "#{hempdb_production}/.env" do
  source 'hemp-db-env.erb'
  mode '0400'
  variables(
    allowed_hosts: [hempdb_production_fqdn, node['ipaddress']],
    app_port: '8096',
    database_ssl: !node['kitchen'],
    default_from_email: "noreply@#{hempdb_production_fqdn}",
    image: 'main',
    production_url: hempdb_production_fqdn,
    sentry_dsn: hempdb_secrets['production']['sentry_dsn']
  )
  sensitive true
  notifies :rebuild, 'osl_dockercompose[hempdb-production]'
end

directory "#{hempdb_production}/docker/secrets"

file "#{hempdb_production}/docker/secrets/secret_key" do
  owner 1000
  group 1000
  mode '0400'
  content hempdb_secrets['production']['secret_key']
  sensitive true
  notifies :rebuild, 'osl_dockercompose[hempdb-production]'
end

file "#{hempdb_production}/docker/secrets/database_url" do
  owner 1000
  group 1000
  mode '0400'
  content 'mysql://' \
    "#{hempdb_secrets['production']['db_user']}:#{hempdb_secrets['production']['db_pass']}" \
    "@#{hempdb_secrets['production']['db_host']}:3306/#{hempdb_secrets['production']['db_name']}"
  sensitive true
  notifies :rebuild, 'osl_dockercompose[hempdb-production]'
end

docker_image 'ghcr.io/osu-cass/hemp-db-main' do
  repo 'ghcr.io/osu-cass/hemp-db'
  tag 'main'
  notifies :rebuild, 'osl_dockercompose[hempdb-production]'
end

osl_dockercompose 'hempdb-production' do
  directory hempdb_production
  config_files hempdb_production_compose
end

osl_app_dockercompose_wrapper 'hempdb-production' do
  directory hempdb_production
  config_files hempdb_production_compose
  user 'hemp-db-production'
end

# Daily poll of the one-shot cron service; the app decides when the audit runs.
cron 'hempdb-production-cron' do
  minute '0'
  hour '3'
  command "cd #{hempdb_production} && /usr/bin/docker compose -p hempdb-production " \
    "#{hempdb_production_compose.map { |f| "-f #{f}" }.join(' ')} run --rm --no-deps cron > /dev/null"
end
