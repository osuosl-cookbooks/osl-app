#
# Cookbook:: osl-app
# Recipe:: default
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

  include_recipe 'git'
  include_recipe 'osl-nodejs'

end

osl_firewall_port 'unicorn' do
  osl_only true
end

# Enable live-restore to keep containers running when docker restarts
node.override['osl-docker']['service'] = { misc_opts: '--live-restore' }

include_recipe 'osl-docker'

# Docker containers - app2
directory '/data/docker/redmine.replicant.us' do
  recursive true
end

docker_image 'osuosl/redmine-replicant' do
  tag '4.2.3-2022.01.14.1907'
  action :pull
end

replicant_dbcreds = data_bag_item('replicant_redmine', 'mysql_creds')
replicant_dbcreds['db_hostname'] = node['ipaddress'] if node['kitchen']

docker_container 'redmine.replicant.us' do
  repo 'osuosl/redmine-replicant'
  tag '4.2.3-2022.01.14.1907'
  port '8090:3000'
  restart_policy 'always'
  volumes ['/data/docker/redmine.replicant.us:/usr/src/redmine/files']
  env [
    "REDMINE_DB_MYSQL=#{replicant_dbcreds['db_hostname']}",
    "REDMINE_DB_DATABASE=#{replicant_dbcreds['db_db']}",
    "REDMINE_DB_USERNAME=#{replicant_dbcreds['db_user']}",
    "REDMINE_DB_PASSWORD=#{replicant_dbcreds['db_passwd']}",
    'REDMINE_PLUGINS_MIGRATE=1',
  ]
  sensitive true
end

git '/var/lib/formsender' do
  repository 'https://github.com/osuosl/formsender.git'
  revision 'master'
  notifies :build, 'docker_image[formsender]', :immediately
  notifies :redeploy, 'docker_container[formsender]'
end

docker_image 'formsender' do
  tag 'latest'
  source '/var/lib/formsender'
  action :nothing
end

formsender_env = data_bag_item('osl-app', 'formsender')

docker_container 'formsender' do
  repo 'formsender'
  tag 'latest'
  port '8085:5000'
  restart_policy 'always'
  env [
    "TOKEN=#{formsender_env['token']}",
    "RT_TOKEN=#{formsender_env['rt_token']}",
    "RECAPTCHA_SECRET=#{formsender_env['recaptcha_secret']}",
  ]
  sensitive true
end

# Docker containers - app3
directory '/data/docker/code.mulgara.org' do
  recursive true
end

mulgara_redmine_creds = data_bag_item('mulgara_redmine', 'mysql_creds')
mulgara_redmine_creds['db_hostname'] = node['ipaddress'] if node['kitchen']
mulgara_redmine_tag = '4.1.1'

docker_image 'library/redmine' do
  tag mulgara_redmine_tag
  action :pull
end

docker_container 'code.mulgara.org' do
  repo 'redmine'
  tag mulgara_redmine_tag
  port '8084:3000'
  restart_policy 'always'
  volumes ['/data/docker/code.mulgara.org:/usr/src/redmine/files']
  env [
    "REDMINE_DB_MYSQL=#{mulgara_redmine_creds['db_hostname']}",
    "REDMINE_DB_DATABASE=#{mulgara_redmine_creds['db_db']}",
    "REDMINE_DB_USERNAME=#{mulgara_redmine_creds['db_user']}",
    "REDMINE_DB_PASSWORD=#{mulgara_redmine_creds['db_passwd']}",
    'REDMINE_PLUGINS_MIGRATE=1',
  ]
  sensitive true
end

etherpad_osl_secrets = data_bag_item('etherpad', 'osl')
etherpad_osl_secrets['db_hostname'] = node['ipaddress'] if node['kitchen']
etherpad_osl_tag = '1.8.6-2020.11.13.2015'

docker_image 'osuosl/etherpad' do
  tag etherpad_osl_tag
  action :pull
end

docker_container 'etherpad-lite.osuosl.org' do
  repo 'osuosl/etherpad'
  tag etherpad_osl_tag
  port '8085:9001'
  restart_policy 'always'
  user 'etherpad'
  env [
    'DB_TYPE=mysql',
    "DB_HOST=#{etherpad_osl_secrets['db_hostname']}",
    "DB_NAME=#{etherpad_osl_secrets['db_db']}",
    "DB_USER=#{etherpad_osl_secrets['db_user']}",
    "DB_PASS=#{etherpad_osl_secrets['db_passwd']}",
    "ADMIN_PASSWORD=#{etherpad_osl_secrets['admin_passwd']}",
  ]
  sensitive true
end

etherpad_snowdrift_secrets = data_bag_item('etherpad', 'snowdrift')
etherpad_snowdrift_secrets['db_hostname'] = node['ipaddress'] if node['kitchen']
etherpad_snowdrift_tag = '1.8.6-2020.11.13.2015'

docker_image 'osuosl/etherpad-snowdrift' do
  tag etherpad_snowdrift_tag
  action :pull
end

docker_container 'etherpad-snowdrift.osuosl.org' do
  repo 'osuosl/etherpad-snowdrift'
  tag etherpad_snowdrift_tag
  port '8086:9001'
  restart_policy 'always'
  user 'etherpad'
  env [
    'DB_TYPE=mysql',
    "DB_HOST=#{etherpad_snowdrift_secrets['db_hostname']}",
    "DB_NAME=#{etherpad_snowdrift_secrets['db_db']}",
    "DB_USER=#{etherpad_snowdrift_secrets['db_user']}",
    "DB_PASS=#{etherpad_snowdrift_secrets['db_passwd']}",
    "ADMIN_PASSWORD=#{etherpad_snowdrift_secrets['admin_passwd']}",
  ]
  sensitive true
end
