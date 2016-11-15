#
# Cookbook Name:: osl-app
# Recipe:: app3
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

node.normal['users'] = %w(streamwebs-production streamwebs-staging)

#### Sudo Privs ####

sudo 'streamwebs-production' do
  user 'streamwebs-production'
  commands sudo_commands('streamwebs-production-gunicorn')
  nopasswd true
end

sudo 'streamwebs-staging' do
  user 'streamwebs-staging'
  commands sudo_commands('streamwebs-staging-gunicorn')
  nopasswd true
end

#### Systemd Services ####

systemd_service 'streamwebs-staging-gunicorn' do
  description 'streamwebs staging app'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'streamwebs-staging'
    environment 'PATH' => '/home/streamwebs-staging/venv/bin'
    working_directory '/home/streamwebs-staging/streamwebs'
    pid_file '/home/streamwebs-staging/tmp/pids/gunicorn.pid'
    exec_start '/home/streamwebs-staging/venv/bin/gunicorn -b 0.0.0.0:8080 '\
      '-D --pid /home/streamwebs-staging/tmp/pids/gunicorn.pid '\
      'streamwebs.wsgi:application'
    exec_reload '/bin/kill -USR2 $MAINPID'
  end
end

systemd_service 'streamwebs-production-gunicorn' do
  description 'streamwebs production app'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'streamwebs-production'
    environment 'PATH' => '/home/streamwebs-production/venv/bin'
    working_directory '/home/streamwebs-production/streamwebs'
    pid_file '/home/streamwebs-production/tmp/pids/gunicorn.pid'
    exec_start '/home/streamwebs-production/venv/bin/gunicorn -b 0.0.0.0:8081 '\
      '-D --pid /home/streamwebs-production/tmp/pids/gunicorn.pid '\
      'streamwebs.wsgi:application'
    exec_reload '/bin/kill -USR2 $MAINPID'
  end
end