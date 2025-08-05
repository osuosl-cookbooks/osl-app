#
# Cookbook:: osl-app
# Recipe:: app3
#
# Copyright:: 2016-2025, Oregon State University
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
  links ['pg_streamwebs_staging:postgres_host'] if node['kitchen']
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
  links ['pg_streamwebs_production:postgres_host'] if node['kitchen']
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

docker_image 'library/redmine' do
  tag '5.1.4'
  notifies :redeploy, 'docker_container[code.mulgara.org]'
end

docker_container 'code.mulgara.org' do
  repo 'redmine'
  tag '5.1.4'
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

docker_image 'elestio/etherpad' do
  notifies :redeploy, 'docker_container[etherpad-lite.osuosl.org]'
end

docker_image 'ghcr.io/osuosl/etherpad-snowdrift' do
  notifies :redeploy, 'docker_container[etherpad-snowdrift.osuosl.org]'
end

docker_container 'etherpad-lite.osuosl.org' do
  repo 'elestio/etherpad'
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
