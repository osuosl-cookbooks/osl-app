#
# Cookbook Name:: osl-app
# Recipe:: app2
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

node.normal['users'] = %w(formsender-production formsender-staging
                          iam-staging iam-production
                          timesync-staging timesync-production replicant)

#### Apps ####

# this app's service depends on the logs/ directory being present inside
# ~formsender-staging/
osl_app 'formsender-staging-gunicorn' do
  description 'formsender staging app'
  user 'formsender-staging'
  start_cmd '/home/formsender-staging/venv/bin/gunicorn -b 0.0.0.0:8086 '\
    '-D --pid /home/formsender-staging/tmp/pids/gunicorn.pid '\
    '--access-logfile /home/formsender-staging/logs/access.log '\
    '--error-logfile /home/formsender-staging/logs/error.log '\
    '--log-level debug '\
    'formsender.wsgi:application'
  environment 'PATH' => '/home/formsender-staging/venv/bin'
  working_directory '/home/formsender-staging/formsender'
end

# this service depends on the logs/ directory being present inside
# ~formsender-production/
osl_app 'formsender-production-gunicorn' do
  description 'formsender production app'
  user 'formsender-production'
  start_cmd '/home/formsender-production/venv/bin/gunicorn -b 0.0.0.0:8085 '\
    '-D --pid /home/formsender-production/tmp/pids/gunicorn.pid '\
    '--access-logfile /home/formsender-production/logs/access.log '\
    '--error-logfile /home/formsender-production/logs/error.log '\
    '--log-level debug '\
    'formsender.wsgi:application'
  environment 'PATH' => '/home/formsender-production/venv/bin'
  working_directory '/home/formsender-production/formsender'
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
  start_cmd '/usr/local/bin/node /home/timesync-staging/timesync/src/app.js'
  environment_file '/home/timesync-staging/timesync.env'
  working_directory '/home/timesync-staging/timesync'
  pid_file '/home/timesync-staging/pids/timesync.pid'
end

osl_app 'timesync-production' do
  description 'Time tracker'
  # Port 8088 (set in env file)
  start_cmd '/usr/local/bin/node /home/timesync-production/timesync/src/app.js'
  environment_file '/home/timesync-production/timesync.env'
  working_directory '/home/timesync-production/timesync'
  pid_file '/home/timesync-production/pids/timesync.pid'
end

osl_app 'replicant-redmine-unicorn' do
  user 'replicant'
  description 'Replicant Redmine'
  start_cmd '/home/replicant/.rvm/bin/rvm 2.3.0 do bundle exec unicorn -l 8090 -c unicorn.rb -E production -D'
  service_type 'simple'
  environment 'RAILS_ENV' => 'production'
  working_directory '/home/replicant/redmine'
  pid_file '/home/replicant/redmine/pids/unicorn.pid'
end
