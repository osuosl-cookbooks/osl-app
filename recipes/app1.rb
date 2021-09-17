#
# Cookbook:: osl-app
# Recipe:: app1
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

include_recipe 'osl-app::default'

users = search('users', '*:*')

users_manage 'app1' do
  users users
end

openid_secrets = data_bag_item('osl-app', 'openid')

#### Systemd Services ####

osl_app 'openid-staging-unicorn' do
  description 'openid staging app'
  service_after 'network.target'
  wanted_by 'multi-user.target'
  service_type 'forking'
  user 'openid-staging'
  environment 'RAILS_ENV=staging'
  working_directory '/home/openid-staging/current'
  pid_file '/home/openid-staging/current/tmp/pids/unicorn.pid'
  start_cmd '/home/openid-staging/.rvm/bin/rvm 2.5.3 do bundle exec unicorn -c /home/openid-staging/current/config/unicorn/staging.rb -E deployment -D'
  reload_cmd '/bin/kill -USR2 $MAINPID'
end

osl_app 'openid-staging-delayed-job' do
  description 'openid delayed job'
  service_after 'network.target openid-staging-unicorn.service'
  service_wants 'openid-staging-unicorn.service'
  wanted_by 'multi-user.target'
  service_type 'forking'
  user 'openid-staging'
  environment 'RAILS_ENV=staging'
  working_directory '/home/openid-staging/current'
  start_cmd '/home/openid-staging/.rvm/bin/rvm 2.5.3 do bundle exec bin/delayed_job -n 2 start'
  reload_cmd '/home/openid-staging/.rvm/bin/rvm 2.5.3 do bundle exec bin/delayed_job -n 2 restart'
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
  start_cmd '/home/openid-production/.rvm/bin/rvm 2.5.3 do bundle exec unicorn -c /home/openid-production/current/config/unicorn/production.rb -E deployment -D'
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
  start_cmd '/home/openid-production/.rvm/bin/rvm 2.5.3 do bundle exec bin/delayed_job -n 2 start'
  reload_cmd '/home/openid-production/.rvm/bin/rvm 2.5.3 do bundle exec bin/delayed_job -n 2 restart'
end

osl_app 'fenestra' do
  description 'osuosl dashboard'
  start_cmd '/home/fenestra/.rvm/bin/rvm 2.2.5 do bundle exec unicorn -l 8082 -c config/unicorn.rb -E deployment -D'
  working_directory '/home/fenestra/fenestra'
  pid_file '/home/fenestra/pids/unicorn.pid'
  action :delete
end

# Setup logrotate, also make sure that unicorn releases the file handles
# by sending it a USR1 signal, which will cause it reopen its logs
%w(production staging).each do |type|
  logrotate_app "OpenID-#{type}" do
    path "/home/openid-#{type}/shared/log/*.log"
    postrotate "/bin/kill -USR1 $(cat /home/openid-#{type}/current/tmp/pids/unicorn.pid)"
    frequency 'daily'
    su "openid-#{type} openid-#{type}"
    rotate 30
  end
end
