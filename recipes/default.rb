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
include_recipe 'yum-epel'
include_recipe 'osl-mysql::client'

node.override['user']['home_dir_mode'] = '2750'
node.default['poise-python']['provider'] = 'system'

# WARNING!
# If this gets updated, all NodeJS apps running will need to have their
# node_modules directories completely removed and `npm install` run again to
# update the modules to match the new Node version's ABI.
node.override['nodejs']['version'] = '6.9.1'
node.override['nodejs']['install_method'] = 'binary'
node.override['nodejs']['binary']['checksum']['linux_x64'] =
  'a9d9e6308931fa2a2b0cada070516d45b76d752430c31c9198933c78f8d54b17'

# rvm package depends
%w(sqlite-devel libyaml-devel readline-devel zlib-devel libffi-devel
   openssl-devel automake libtool ImageMagick-devel postgresql-devel
).each do |p|
  package p
end

# geo-django depends
%w(gdal-python geos-python proj proj-nad postgresql-devel
   freetype-devel libpng-devel libjpeg-turbo-devel postgis
   python-psycopg2).each do |p|
  package p
end

python_runtime '2' do
  pip_version '18.0' if node['platform_version'].to_i >= 7
end

# Keep systemd services private from non-root users
directory '/etc/systemd/system' do
  mode 0750
end

# rewind the sudoers template to support sudoers_d
temp = resources(template: '/etc/sudoers')
temp.variables['include_sudoers_d'] = true

build_essential 'install tools'

include_recipe 'user::data_bag'
include_recipe 'osl-nodejs'
include_recipe 'firewall::unicorn'
include_recipe 'git'
