#
# Cookbook:: osl-app
# Recipe:: default
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
include_recipe 'osl-repos::centos'
include_recipe 'osl-repos::epel'
include_recipe 'osl-mysql::client'
include_recipe 'base::python'

node.override['user']['home_dir_mode'] = '2750'

# WARNING!
# If this gets updated, all NodeJS apps running will need to have their
# node_modules directories completely removed and `npm install` run again to
# update the modules to match the new Node version's ABI.
node.override['nodejs']['version'] = '6.9.1'
node.override['nodejs']['install_method'] = 'binary'
node.override['nodejs']['binary']['checksum']['linux_x64'] =
  'a9d9e6308931fa2a2b0cada070516d45b76d752430c31c9198933c78f8d54b17'

# rvm package depends
package %w(
  automake
  ImageMagick-devel
  libffi-devel
  libtool
  libyaml-devel
  openssl-devel
  postgresql-devel
  readline-devel
  sqlite-devel
  zlib-devel
)

package 'osl-app packages' do
  package_name osl_app_packages
end
package 'python-psycopg2' do
  package_name 'python2-psycopg2' if node['platform_version'].to_i >= 8
end

# Keep systemd services private from non-root users
directory '/etc/systemd/system' do
  mode '750'
end

# rewind the sudoers template to support sudoers_d
temp = resources(template: '/etc/sudoers')
temp.variables['include_sudoers_d'] = true

build_essential 'install tools'

include_recipe 'git'
include_recipe 'osl-nodejs'
include_recipe 'user::data_bag'

osl_firewall_port 'unicorn' do
  osl_only true
end
