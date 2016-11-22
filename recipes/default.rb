#
# Cookbook Name:: osl-app
# Recipe:: default
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

node.override['user']['home_dir_mode'] = '2750'
node.default['poise-python']['provider'] = 'system'

# WARNING!
# If this gets updated, all NodeJS apps running will need to have their
# node_modules directories completely removed and `npm install` run again to
# update the modules to match the new Node version's ABI.
node.override['nodejs']['version'] = '6.9.1'
node.override['nodejs']['install_method'] = 'binary'
node.override['nodejs']['binary']['checksum']['linux_x64'] = 'd4eb161e4715e1' \
'1bbef816a6c577974271e2bddae9cf008744627676ff00036a'

# rvm package depends
%w(sqlite-devel libyaml-devel readline-devel zlib-devel libffi-devel
   openssl-devel automake libtool mariadb-devel ImageMagick-devel
   postgresql-devel).each do |p|
  package p
end

# geo-django depends
%w(gdal-python geos-python proj proj-nad postgresql-devel freetype-devel
   libjpeg-devel libpng-devel).each do |p|
  package p
end

python_runtime '2'

# Keep systemd services private from non-root users
directory '/etc/systemd/system' do
  mode 0750
end

# rewind the sudoers template to support sudoers_d
temp = resources(template: '/etc/sudoers')
temp.variables['include_sudoers_d'] = true

include_recipe 'user::data_bag'
include_recipe 'build-essential'
include_recipe 'nodejs'
include_recipe 'firewall::unicorn'
include_recipe 'git'
