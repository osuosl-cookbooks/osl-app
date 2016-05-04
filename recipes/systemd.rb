#
# Cookbook Name:: osl-app
# Recipe:: systemd
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

secrets = data_bag_item('osl-app', 'openid')

# Keep systemd services private from non-root users
directory '/etc/systemd/system' do
  mode 0750
end

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
    exec_start '/home/openid-staging/.rvm/bin/rvm 2.2.4 do bundle exec '\
    'unicorn -c /home/openid-staging/current/config/unicorn/staging.rb -E '\
    'deployment -D'
    exec_reload '/bin/kill -USR2 $MAINPID'
  end
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
    exec_start '/home/openid-staging/.rvm/bin/rvm 2.2.4 do bundle exec '\
    'bin/delayed_job -n 2 start'
    exec_reload '/home/openid-staging/.rvm/bin/rvm 2.2.4 do bundle exec '\
    'bin/delayed_job -n 2 restart'
  end
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
                SECRET_KEY_BASE: secrets['secret_key_base'])
    working_directory '/home/openid-production/current'
    pid_file '/home/openid-production/current/tmp/pids/unicorn.pid'
    exec_start '/home/openid-production/.rvm/bin/rvm 2.2.4 do bundle exec '\
    'unicorn -c /home/openid-production/current/config/unicorn/production.rb '\
    '-E deployment -D'
    exec_reload '/bin/kill -USR2 $MAINPID'
  end
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
end
