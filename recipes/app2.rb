#
# Cookbook:: osl-app
# Recipe:: app2
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

users = search('users', '*:*')

users_manage 'app2' do
  users users
end

ghcr_io = ghcr_io_credentials

docker_registry 'ghcr.io' do
  username ghcr_io['username']
  password ghcr_io['password']
end

#### Apps ####

# Docker containers
directory '/data/docker/redmine.replicant.us' do
  recursive true
end

docker_image 'osuosl/redmine-replicant' do
  tag '4.2.3-2022.01.14.1907'
  notifies :redeploy, 'docker_container[redmine.replicant.us]'
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

docker_image 'ghcr.io/osuosl/formsender' do
  tag 'master'
  notifies :redeploy, 'docker_container[formsender]'
end

formsender_env = data_bag_item('osl-app', 'formsender')

docker_container 'formsender' do
  repo 'ghcr.io/osuosl/formsender'
  tag 'master'
  port '8085:5000'
  restart_policy 'always'
  env [
    "TOKEN=#{formsender_env['token']}",
    "RT_TOKEN=#{formsender_env['rt_token']}",
    "RECAPTCHA_SECRET=#{formsender_env['recaptcha_secret']}",
    "SENTRY_URI=#{formsender_env['sentry_uri']}",
  ]
  sensitive true
end
