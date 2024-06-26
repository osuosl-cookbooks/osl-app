#
# Cookbook:: osl-app
# Recipe:: default
#
# Copyright:: 2016-2024, Oregon State University
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

include_recipe 'osl-git'

if node['platform_version'].to_i < 8
  include_recipe 'osl-repos::centos'
  include_recipe 'osl-repos::epel'
  include_recipe 'osl-mysql::client'
  include_recipe 'base::python'

  # WARNING!
  # If this gets updated, all NodeJS apps running will need to have their
  # node_modules directories completely removed and `npm install` run again to
  # update the modules to match the new Node version's ABI.
  node.override['nodejs']['repo'] = 'https://rpm.nodesource.com/pub_6.x/el/$releasever/$basearch'

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

  package 'python-psycopg2'

  # Keep systemd services private from non-root users
  directory '/etc/systemd/system' do
    mode '750'
  end

  # rewind the sudoers template to support sudoers_d
  temp = resources(template: '/etc/sudoers')
  temp.variables['include_sudoers_d'] = true

  build_essential 'install tools'
  include_recipe 'osl-nodejs'

end

osl_firewall_port 'unicorn' do
  osl_only true
end

# Enable live-restore to keep containers running when docker restarts
node.override['osl-docker']['service'] = { misc_opts: '--live-restore' }

include_recipe 'osl-docker'
