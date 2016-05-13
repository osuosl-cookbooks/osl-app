#
# Cookbook Name:: osl-app
# Recipe:: sudo
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

# rewind the sudoers template to support sudoers_d
temp = resources(template: '/etc/sudoers')
temp.variables['include_sudoers_d'] = true

sudo 'openid-staging' do
  user 'openid-staging'
  commands sudo_commands(%w(openid-staging-unicorn openid-staging-delayed-job))
  nopasswd true
end

sudo 'openid-production' do
  user 'openid-production'
  commands sudo_commands(%w(openid-production-unicorn
                            openid-production-delayed-job))
  nopasswd true
end

sudo 'fenestra' do
  user 'fenestra'
  commands sudo_commands(%w(fenestra))
  nopasswd true
end
