#
# Cookbook Name:: osl-app
# Recipe:: app1
#
# Copyright 2016 Oregon State University
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

node.normal['users'] = %w(openid-staging openid-production fenestra)

openid_secrets = data_bag_item('osl-app', 'openid')

#### Sudo Privs ####

sudo 'openid-staging' do
  user 'openid-staging'
  commands sudo_commands('openid-staging-unicorn', 'openid-staging-delayed-job')
  nopasswd true
end

sudo 'openid-production' do
  user 'openid-production'
  commands sudo_commands('openid-production-unicorn',
                         'openid-production-delayed-job')
  nopasswd true
end

#### Systemd Services ####

systemd_service 'openid-staging-unicorn' do
  description 'openid staging app'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'openid-staging'
    environment 'RAILS_ENV' => 'staging'
    working_directory '/home/openid-staging/current'
    pid_file '/home/openid-staging/current/tmp/pids/unicorn.pid'
    exec_start '/home/openid-staging/.rvm/bin/rvm 2.5.3 do bundle exec '\
    'unicorn -c /home/openid-staging/current/config/unicorn/staging.rb -E '\
    'deployment -D'
    exec_reload '/bin/kill -USR2 $MAINPID'
  end
  action [:create, :enable]
end

systemd_service 'openid-staging-delayed-job' do
  description 'openid delayed job'
  after %w(network.target openid-staging-unicorn.service)
  wants %w(openid-staging-unicorn.service)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'openid-staging'
    environment 'RAILS_ENV' => 'staging'
    working_directory '/home/openid-staging/current'
    exec_start '/home/openid-staging/.rvm/bin/rvm 2.5.3 do bundle exec '\
    'bin/delayed_job -n 2 start'
    exec_reload '/home/openid-staging/.rvm/bin/rvm 2.5.3 do bundle exec '\
    'bin/delayed_job -n 2 restart'
  end
  action [:create, :enable]
end

systemd_service 'openid-production-unicorn' do
  description 'openid production app'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'openid-production'
    environment(RAILS_ENV: 'production',
                SECRET_KEY_BASE: openid_secrets['secret_key_base'],
                BRAINTREE_ACCESS_TOKEN: openid_secrets['braintree_access_token'])
    working_directory '/home/openid-production/current'
    pid_file '/home/openid-production/current/tmp/pids/unicorn.pid'
    exec_start '/home/openid-production/.rvm/bin/rvm 2.2.4 do bundle exec '\
    'unicorn -c /home/openid-production/current/config/unicorn/production.rb '\
    '-E deployment -D'
    exec_reload '/bin/kill -USR2 $MAINPID'
  end
  action [:create, :enable]
end

systemd_service 'openid-production-delayed-job' do
  description 'openid delayed job'
  after %w(network.target openid-production-unicorn.service)
  wants %w(openid-production-unicorn.service)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'openid-production'
    environment 'RAILS_ENV' => 'production'
    working_directory '/home/openid-production/current'
    exec_start '/home/openid-production/.rvm/bin/rvm 2.2.4 do bundle exec '\
    'bin/delayed_job -n 2 start'
    exec_reload '/home/openid-production/.rvm/bin/rvm 2.2.4 do bundle exec '\
    'bin/delayed_job -n 2 restart'
  end
  action [:create, :enable]
end

osl_app 'fenestra' do
  description 'osuosl dashboard'
  start_cmd '/home/fenestra/.rvm/bin/rvm 2.2.5 do bundle exec unicorn -l 8082 -c config/unicorn.rb -E deployment -D'
  working_directory '/home/fenestra/fenestra'
  pid_file '/home/fenestra/pids/unicorn.pid'
end

# Setup logrotate, also make sure that unicorn releases the file handles
# by sending it a USR1 signal, which will cause it reopen its logs
%w(production staging).each do |type|
  logrotate_app "OpenID-#{type}" do
    path "/home/openid-#{type}/shared/log/*.log"
    postrotate "/bin/kill -USR1 /home/openid-#{type}/current/tmp/pids/unicorn.pid"
    frequency 'daily'
    su "openid-#{type} openid-#{type}"
    rotate 30
  end
end
