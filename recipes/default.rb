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

node.default['users'] = node['users'] + %w(openid-staging)
node.default['poise-python']['provider'] = 'system'

node.override['nodejs']['version'] = '4.4.1'
node.override['nodejs']['install_method'] = 'binary'
node.override['nodejs']['binary']['checksum']['linux_x64'] = 'f0a53527f52dbcab'\
'3b98921a6cfe8613e5fe26fb796624988f6d615c30305a95'

# rvm package depends
%w(sqlite-devel libyaml-devel readline-devel zlib-devel libffi-devel
   openssl-devel automake libtool).each { |p| package p }

python_runtime '2'

include_recipe 'user::data_bag'
include_recipe 'build-essential'
include_recipe 'nodejs'
include_recipe 'firewall::unicorn'
include_recipe 'git'
include_recipe 'osl-app::sudo'
include_recipe 'osl-app::systemd'
