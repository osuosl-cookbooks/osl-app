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

users = search('users', '*:*')

users_manage 'app1' do
  users users
end

openid_secrets = data_bag_item('osl-app', 'openid')
openid_db_host = node['kitchen'] ? node['ipaddress'] : openid_secrets['db_host']

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

# docker_image 'oidf-members-master' do
#   repo 'ghcr.io/openid-foundation/oidf-members'
#   tag 'master'
#   notifies :redeploy, 'docker_container[openid-production-website]'
#   notifies :redeploy, 'docker_container[openid-production-delayed-job]'
# end

docker_container 'openid-staging-website' do
  repo 'ghcr.io/openid-foundation/oidf-members'
  tag 'develop'
  port '8080:8080'
  restart_policy 'always'
  command "sh -c 'bundle exec rake db:migrate && bundle exec unicorn -c config/unicorn.rb'"
  env [
    'RAILS_ENV=staging',
    "DB_PASSWORD=#{openid_secrets['db_password']}",
    "DB_HOST=#{openid_db_host}",
  ]
  sensitive true
end

# docker_container 'openid-production-website' do
#   repo 'ghcr.io/openid-foundation/oidf-members'
#   tag 'master'
#   port '8081:8080'
#   restart_policy 'always'
#   command "sh -c 'bundle exec rake db:migrate && bundle exec unicorn -c config/unicorn.rb'"
#   env [
#     'RAILS_ENV=production',
#     "DB_PASSWORD=#{openid_secrets['db_password']}",
#     "DB_HOST=#{openid_db_host}",
#     "SECRET_KEY_BASE=#{openid_secrets['secret_key_base']}",
#     "BRAINTREE_ACCESS_TOKEN=#{openid_secrets['braintree_access_token']}",
#     "RECAPTCHA_SITE_KEY=#{openid_secrets['recaptcha_site_key']}",
#     "RECAPTCHA_SECRET_KEY=#{openid_secrets['recaptcha_secret_key']}",
#   ]
#   sensitive true
# end

docker_container 'openid-staging-delayed-job' do
  repo 'ghcr.io/openid-foundation/oidf-members'
  tag 'develop'
  restart_policy 'always'
  command 'bundle exec bin/delayed_job -n 2 run'
  env [
    'RAILS_ENV=staging',
    "DB_PASSWORD=#{openid_secrets['db_password']}",
    "DB_HOST=#{openid_db_host}",
  ]
  sensitive true
end

# docker_container 'openid-production-delayed-job' do
#   repo 'ghcr.io/openid-foundation/oidf-members'
#   tag 'master'
#   restart_policy 'always'
#   command 'bundle exec bin/delayed_job -n 2 run'
#   env [
#     'RAILS_ENV=production',
#     "DB_PASSWORD=#{openid_secrets['db_password']}",
#     "DB_HOST=#{openid_db_host}",
#   ]
#   sensitive true
# end

osl_app_docker_wrapper 'openid-staging-website' do
  user 'openid-staging'
end

osl_app_docker_wrapper 'openid-staging-delayed-job' do
  user 'openid-staging'
end

osl_app 'openid-production-unicorn' do
  description 'openid production app'
  service_after 'network.target'
  wanted_by 'multi-user.target'
  service_type 'forking'
  user 'openid-production'
  environment(
    'RAILS_ENV=production '\
    "SECRET_KEY_BASE=#{openid_secrets['secret_key_base']} "\
    "BRAINTREE_ACCESS_TOKEN=#{openid_secrets['braintree_access_token']} "\
    "RECAPTCHA_SITE_KEY=#{openid_secrets['recaptcha_site_key']} "\
    "RECAPTCHA_SECRET_KEY=#{openid_secrets['recaptcha_secret_key']}"
  )
  working_directory '/home/openid-production/current'
  pid_file '/home/openid-production/current/tmp/pids/unicorn.pid'
  start_cmd '/home/openid-production/.rvm/bin/rvm 3.1.4 do bundle exec unicorn -c /home/openid-production/current/config/unicorn/production.rb -E deployment -D'
  reload_cmd '/bin/kill -USR2 $MAINPID'
end

osl_app 'openid-production-delayed-job' do
  description 'openid delayed job'
  service_after 'network.target openid-production-unicorn.service'
  service_wants 'openid-production-unicorn.service'
  wanted_by 'multi-user.target'
  service_type 'forking'
  user 'openid-production'
  environment 'RAILS_ENV=production'
  working_directory '/home/openid-production/current'
  start_cmd '/home/openid-production/.rvm/bin/rvm 3.1.4 do bundle exec bin/delayed_job -n 2 start'
  reload_cmd '/home/openid-production/.rvm/bin/rvm 3.1.4 do bundle exec bin/delayed_job -n 2 restart'
end
