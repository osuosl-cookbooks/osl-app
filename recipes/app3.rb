#
# Cookbook:: osl-app
# Recipe:: app3
#
# Copyright:: 2016-2021, Oregon State University
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

# Enable live-restore to keep containers running when docker restarts
node.override['osl-docker']['service'] = { misc_opts: '--live-restore' }

include_recipe 'osl-app::default'
include_recipe 'osl-nginx'
include_recipe 'osl-docker'

# Save nginx service for later use
service 'nginx' do
  action :nothing
end

users = search('users', '*:*')

users_manage 'app3' do
  users users
end

#### Apps ####

osl_app 'streamwebs-staging-gunicorn' do
  description 'streamwebs staging app'
  user 'streamwebs-staging'
  start_cmd '/home/streamwebs-staging/venv/bin/gunicorn -b 0.0.0.0:8081 '\
    '-D --pid /home/streamwebs-staging/tmp/pids/gunicorn.pid '\
    '--access-logfile /home/streamwebs-staging/logs/access.log '\
    '--error-logfile /home/streamwebs-staging/logs/error.log ' \
    'streamwebs_frontend.wsgi:application'
  environment 'PATH=/home/streamwebs-staging/venv/bin'
  working_directory '/home/streamwebs-staging/streamwebs/streamwebs_frontend'
  pid_file '/home/streamwebs-staging/tmp/pids/gunicorn.pid'
end

osl_app 'streamwebs-production-gunicorn' do
  description 'streamwebs production app'
  user 'streamwebs-production'
  start_cmd '/home/streamwebs-production/venv/bin/gunicorn -b 0.0.0.0:8080 '\
    '-D --pid /home/streamwebs-production/tmp/pids/gunicorn.pid '\
    '--access-logfile /home/streamwebs-production/logs/access.log '\
    '--error-logfile /home/streamwebs-production/logs/error.log ' \
    'streamwebs_frontend.wsgi:application'
  environment 'PATH=/home/streamwebs-production/venv/bin'
  working_directory '/home/streamwebs-production/streamwebs/streamwebs_frontend'
  pid_file '/home/streamwebs-production/tmp/pids/gunicorn.pid'
end

osl_app 'timesync-web-staging' do
  description 'timesync-web staging app'
  start_cmd '/home/timesync-web-staging/venv/bin/gunicorn -b 0.0.0.0:8082 '\
    '-D --pid /home/timesync-web-staging/tmp/pids/gunicorn.pid wsgi:app'
  environment 'PATH=/home/timesync-web-staging/venv/bin'
  working_directory '/home/timesync-web-staging/timesync-web'
  pid_file '/home/timesync-web-staging/tmp/pids/gunicorn.pid'
end

osl_app 'timesync-web-production' do
  description 'timesync-web production app'
  start_cmd '/home/timesync-web-production/venv/bin/gunicorn '\
    '-b 0.0.0.0:8083 '\
    '-D --pid /home/timesync-web-production/tmp/pids/gunicorn.pid wsgi:app'
  environment 'PATH=/home/timesync-web-production/venv/bin'
  working_directory '/home/timesync-web-production/timesync-web'
  pid_file '/home/timesync-web-production/tmp/pids/gunicorn.pid'
end

# Nginx
node.default['osl-app']['nginx'] = {
  'streamwebs.org' => {
    'uri' => '/streamwebs-production/media',
    'folder' => '/home/streamwebs-production/streamwebs/streamwebs_frontend/media',
  },
  'streamwebs-staging.osuosl.org' => {
    'uri' => '/streamwebs-staging/media',
    'folder' => '/home/streamwebs-staging/streamwebs/streamwebs_frontend/media',
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
end

# Docker containers
directory '/data/docker/code.mulgara.org' do
  recursive true
end

mulgara_redmine_creds = data_bag_item('mulgara_redmine', 'mysql_creds')
mulgara_redmine_creds['db_hostname'] = node['ipaddress'] if node['kitchen']
mulgara_redmine_tag = '4.1.1'

docker_image 'library/redmine' do
  tag mulgara_redmine_tag
  action :pull
end

docker_container 'code.mulgara.org' do
  repo 'redmine'
  tag mulgara_redmine_tag
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
etherpad_osl_tag = '1.8.6-2020.11.13.2015'

docker_image 'osuosl/etherpad' do
  tag etherpad_osl_tag
  action :pull
end

docker_container 'etherpad-lite.osuosl.org' do
  repo 'osuosl/etherpad'
  tag etherpad_osl_tag
  port '8085:9001'
  restart_policy 'always'
  user 'etherpad'
  env [
    'DB_TYPE=mysql',
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
etherpad_snowdrift_tag = '1.8.6-2020.11.13.2015'

docker_image 'osuosl/etherpad-snowdrift' do
  tag etherpad_snowdrift_tag
  action :pull
end

docker_container 'etherpad-snowdrift.osuosl.org' do
  repo 'osuosl/etherpad-snowdrift'
  tag etherpad_snowdrift_tag
  port '8086:9001'
  restart_policy 'always'
  user 'etherpad'
  env [
    'DB_TYPE=mysql',
    "DB_HOST=#{etherpad_snowdrift_secrets['db_hostname']}",
    "DB_NAME=#{etherpad_snowdrift_secrets['db_db']}",
    "DB_USER=#{etherpad_snowdrift_secrets['db_user']}",
    "DB_PASS=#{etherpad_snowdrift_secrets['db_passwd']}",
    "ADMIN_PASSWORD=#{etherpad_snowdrift_secrets['admin_passwd']}",
  ]
  sensitive true
end
