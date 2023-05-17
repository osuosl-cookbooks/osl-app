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

include_recipe 'osl-app::default'

users = search('users', '*:*')

users_manage 'app2' do
  users users
end

#### Apps ####

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
