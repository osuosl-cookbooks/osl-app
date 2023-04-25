#
# Cookbook:: osl-app
# Recipe:: app2
#
# Copyright:: 2016-2023, Oregon State University
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
include_recipe 'osl-docker'

users = search('users', '*:*')

users_manage 'app2' do
  users users
end

#### Apps ####

directory '/formsender'

git '/var/lib/formsender' do
  repository 'https://github.com/osuosl/formsender.git'
  revision 'antoniagaete/RT_api'
end

docker_image 'formsender' do
  tag 'latest'
  source '/var/lib/formsender'
  action :nothing
end

git '/var/lib/formsender' do
  action :nothing
  notifies :build, 'docker_image[formsender]', :immediately
end

formsender_env = data_bag_item('osl-app', 'formsender')

docker_container 'support.osuosl.org' do
  repo 'formsender'
  tag 'latest'
  port '8086:5000'
  restart_policy 'always'
  env [
    "TOKEN=#{formsender_env['token']}",
    "RECAPTCHA_SECRET=#{formsender_env['recaptcha_secret']}",
  ]
end

osl_app 'iam-staging' do
  description 'osuosl metrics'
  start_cmd '/home/iam-staging/.rvm/bin/rvm 2.3.0 do bundle exec unicorn -l 8084 -c unicorn.rb -E deployment -D'
  pid_file '/home/iam-staging/pids/unicorn.pid'
  working_directory '/home/iam-staging/iam'
end

osl_app 'iam-production' do
  description 'osuosl metrics'
  start_cmd '/home/iam-production/.rvm/bin/rvm 2.3.0 do bundle exec unicorn -l 8083 -c unicorn.rb -E deployment -D'
  working_directory '/home/iam-production/iam'
  pid_file '/home/iam-production/pids/unicorn.pid'
end

osl_app 'timesync-staging' do
  description 'Time tracker'
  # Port 8089 (set in env file)
  start_cmd '/usr/bin/node /home/timesync-staging/timesync/src/app.js'
  environment_file '/home/timesync-staging/timesync.env'
  working_directory '/home/timesync-staging/timesync'
  pid_file '/home/timesync-staging/pids/timesync.pid'
  service_type 'simple'
end

osl_app 'timesync-production' do
  description 'Time tracker'
  # Port 8088 (set in env file)
  start_cmd '/usr/bin/node /home/timesync-production/timesync/src/app.js'
  environment_file '/home/timesync-production/timesync.env'
  working_directory '/home/timesync-production/timesync'
  pid_file '/home/timesync-production/pids/timesync.pid'
  service_type 'simple'
end

# Docker containers
directory '/data/docker/redmine.replicant.us' do
  recursive true
end

docker_image 'osuosl/redmine-replicant' do
  tag '4.2.3-2022.01.14.1907'
  action :pull
end

replicant_dbcreds = data_bag_item('replicant_redmine', 'mysql_creds')
replicant_dbcreds['db_hostname'] = node['ipaddress'] if node['kitchen']

docker_container 'redmine.replicant.us' do
  repo 'osuosl/redmine-replicant'
  tag '4.2.3-2022.01.14.1907'
  port '8090:3000'
  restart_policy 'always'
  volumes ['/data/docker/redmine.replicant.us:/usr/src/redmine/files']
  env [
    "REDMINE_DB_MYSQL=#{replicant_dbcreds['db_hostname']}",
    "REDMINE_DB_DATABASE=#{replicant_dbcreds['db_db']}",
    "REDMINE_DB_USERNAME=#{replicant_dbcreds['db_user']}",
    "REDMINE_DB_PASSWORD=#{replicant_dbcreds['db_passwd']}",
    'REDMINE_PLUGINS_MIGRATE=1',
  ]
  sensitive true
end
