#
# Cookbook:: osl-app
# Recipe:: app3
#
# Copyright:: 2016-2020, Oregon State University
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

node.default['users'] = %w(streamwebs-production streamwebs-staging
                           timesync-web-staging timesync-web-production)

#### Apps ####

osl_app 'streamwebs-staging-gunicorn' do
  description 'streamwebs staging app'
  user 'streamwebs-staging'
  start_cmd '/home/streamwebs-staging/venv/bin/gunicorn -b 0.0.0.0:8081 '\
    '-D --pid /home/streamwebs-staging/tmp/pids/gunicorn.pid '\
    '--access-logfile /home/streamwebs-staging/logs/access.log '\
    '--error-logfile /home/streamwebs-staging/logs/error.log ' \
    'streamwebs_frontend.wsgi:application'
  environment 'PATH' => '/home/streamwebs-staging/venv/bin'
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
  environment 'PATH' => '/home/streamwebs-production/venv/bin'
  working_directory '/home/streamwebs-production/streamwebs/streamwebs_frontend'
  pid_file '/home/streamwebs-production/tmp/pids/gunicorn.pid'
end

osl_app 'timesync-web-staging' do
  description 'timesync-web staging app'
  start_cmd '/home/timesync-web-staging/venv/bin/gunicorn -b 0.0.0.0:8082 '\
    '-D --pid /home/timesync-web-staging/tmp/pids/gunicorn.pid wsgi:app'
  environment 'PATH' => '/home/timesync-web-staging/venv/bin'
  working_directory '/home/timesync-web-staging/timesync-web'
  pid_file '/home/timesync-web-staging/tmp/pids/gunicorn.pid'
end

osl_app 'timesync-web-production' do
  description 'timesync-web production app'
  start_cmd '/home/timesync-web-production/venv/bin/gunicorn '\
    '-b 0.0.0.0:8083 '\
    '-D --pid /home/timesync-web-production/tmp/pids/gunicorn.pid wsgi:app'
  environment 'PATH' => '/home/timesync-web-production/venv/bin'
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
    members ["streamwebs-#{env}", 'nginx']
    action :modify
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

docker_image 'library/redmine' do
  tag '4.1.1'
  action :pull
end

# Check if attribute is set for testing
mulgara_db_host = node['osl-app'].attribute?('db_hostname') ? node['osl-app']['db_hostname'] : mulgara_redmine_creds['db_hostname']

docker_container 'code.mulgara.org' do
  repo 'redmine'
  tag '4.1.1'
  port '8084:3000'
  restart_policy 'always'
  volumes ['/data/docker/code.mulgara.org:/usr/src/redmine/files']
  env [
    "REDMINE_DB_MYSQL=#{mulgara_db_host}",
    "REDMINE_DB_DATABASE=#{mulgara_redmine_creds['db_db']}",
    "REDMINE_DB_USERNAME=#{mulgara_redmine_creds['db_user']}",
    "REDMINE_DB_PASSWORD=#{mulgara_redmine_creds['db_passwd']}",
    'REDMINE_PLUGINS_MIGRATE=1',
  ]
  sensitive true
end

# Check if attribute is set for testing

etherpad_tag = '1.8.6-2020.11.13.2015'
etherpad_snowdrift_tag = '1.8.6-2020.11.13.2015'

etherpad_creds = data_bag_item('etherpad', 'mysql_creds_osl')
etherpad_snowdrift_creds = data_bag_item('etherpad', 'mysql_creds_snowdrift')

etherpad_db_host = node['osl-app'].attribute?('db_hostname') ? node['osl-app']['db_hostname'] : etherpad_creds['db_hostname']
etherpad_snowdrift_db_host = node['osl-app'].attribute?('db_hostname') ? node['osl-app']['db_hostname'] : etherpad_snowdrift_creds['db_hostname']

docker_image 'osuosl/etherpad' do
  tag etherpad_tag
  action :pull
end

docker_container 'etherpad-lite.osuosl.org' do
  repo 'osuosl/etherpad'
  tag etherpad_tag
  port '8085:9001'
  restart_policy 'always'
  env [
    'DB_TYPE=mysql',
    "DB_HOST=#{etherpad_db_host}",
    "DB_NAME=#{etherpad_creds['db_db']}",
    "DB_USER=#{etherpad_creds['db_user']}",
    "DB_PASS=#{etherpad_creds['db_passwd']}",
  ]
  sensitive true
end

docker_image 'osuosl/etherpad-snowdrift' do
  tag etherpad_snowdrift_tag
  action :pull
end

docker_container 'etherpad-snowdrift.osuosl.org' do
  repo 'osuosl/etherpad-snowdrift'
  tag etherpad_snowdrift_tag
  port '8086:9001'
  restart_policy 'always'
  env [
    'DB_TYPE=mysql',
    "DB_HOST=#{etherpad_snowdrift_db_host}",
    "DB_NAME=#{etherpad_snowdrift_creds['db_db']}",
    "DB_USER=#{etherpad_snowdrift_creds['db_user']}",
    "DB_PASS=#{etherpad_snowdrift_creds['db_passwd']}",
  ]
  sensitive true
end
