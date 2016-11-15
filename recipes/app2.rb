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
                          timesync-staging timesync-production)

#### Sudo Privs ####

sudo 'formsender-production' do
  user 'formsender-production'
  commands sudo_commands('formsender-production-gunicorn')
  nopasswd true
end

sudo 'formsender-staging' do
  user 'formsender-staging'
  commands sudo_commands('formsender-staging-gunicorn')
  nopasswd true
end

sudo 'iam-staging' do
  user 'iam-staging'
  commands sudo_commands('iam-staging')
  nopasswd true
end

sudo 'iam-production' do
  user 'iam-production'
  commands sudo_commands('iam-production')
  nopasswd true
end

sudo 'timesync-production' do
  user 'timesync-production'
  commands sudo_commands('timesync-production')
  nopasswd true
end

sudo 'timesync-staging' do
  user 'timesync-staging'
  commands sudo_commands('timesync-staging')
  nopasswd true
end

#### Systemd Services ####

systemd_service 'formsender-staging-gunicorn' do
  description 'formsender staging app'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'formsender-staging'
    environment 'PATH' => '/home/formsender-staging/venv/bin'
    working_directory '/home/formsender-staging/formsender'
    pid_file '/home/formsender-staging/tmp/pids/gunicorn.pid'
    exec_start '/home/formsender-staging/venv/bin/gunicorn -b 0.0.0.0:8086 '\
      '-D --pid /home/formsender-staging/tmp/pids/gunicorn.pid '\
      'formsender.wsgi:application'
    exec_reload '/bin/kill -USR2 $MAINPID'
  end
end

systemd_service 'formsender-production-gunicorn' do
  description 'formsender production app'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'formsender-production'
    environment 'PATH' => '/home/formsender-production/venv/bin'
    working_directory '/home/formsender-production/formsender'
    pid_file '/home/formsender-production/tmp/pids/gunicorn.pid'
    exec_start '/home/formsender-production/venv/bin/gunicorn -b 0.0.0.0:8085 '\
      '-D --pid /home/formsender-production/tmp/pids/gunicorn.pid '\
      'formsender.wsgi:application'
    exec_reload '/bin/kill -USR2 $MAINPID'
  end
end

systemd_service 'iam-staging' do
  description 'osuosl metrics'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'iam-staging'
    working_directory '/home/iam-staging/iam'
    pid_file '/home/iam-staging/pids/unicorn.pid'
    exec_start '/home/iam-staging/.rvm/bin/rvm 2.3.0 do bundle exec '\
      'unicorn -l 8083 -c config/unicorn.rb -E deployment -D'
  end
end

systemd_service 'iam-production' do
  description 'osuosl metrics'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'forking'
    user 'iam-production'
    working_directory '/home/iam-production/iam'
    pid_file '/home/iam-production/pids/unicorn.pid'
    exec_start '/home/iam-production/.rvm/bin/rvm 2.3.0 do bundle exec '\
      'unicorn -l 8084 -c config/unicorn.rb -E deployment -D'
  end
end

systemd_service 'timesync-staging' do
  description 'Time tracker'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    environment_file '/home/timesync-staging/timesync.env'
    user 'timesync-staging'
    working_directory '/home/timesync-staging/timesync'
    pid_file '/home/timesync-staging/pids/timesync.pid'
    # Port 8089 (set in env file)
    exec_start '/usr/local/bin/node /home/timesync-staging/timesync/src/app.js'
  end
end

systemd_service 'timesync-production' do
  description 'Time tracker'
  after %w(network.target)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    environment_file '/home/timesync-production/timesync.env'
    user 'timesync-production'
    working_directory '/home/timesync-production/timesync'
    pid_file '/home/timesync-production/pids/timesync.pid'
    # Port 8088 (set in env file)
    exec_start '/usr/local/bin/node ' \
      '/home/timesync-production/timesync/src/app.js'
  end
end
