include_recipe 'osl-mysql::server'
build_essential 'install compilation tools'

mysql2_chef_gem 'default' do
  provider Chef::Provider::Mysql2ChefGem::Percona
  action :install
end

mysql_database 'replicant_redmine' do
  connection(
    host: '127.0.0.1',
    user: 'root',
    password: 'password'
  )
  action :create
end

mysql_database_user 'redmine' do
  database_name 'replicant_redmine'
  password 'passwd'
  host '172.17.%'
  connection(
    host: '127.0.0.1',
    user: 'root',
    password: 'password'
  )
  action [:create, :grant]
end

cookbook_file '/tmp/replicant_redmine.sql'

execute 'mysql replicant_redmine < /tmp/replicant_redmine.sql && touch /tmp/replicant_redmine.done' do
  creates '/tmp/replicant_redmine.done'
end

directory '/data/docker/redmine.replicant.us/2019/09' do
  recursive true
end

cookbook_file '/data/docker/redmine.replicant.us/2019/09/190923192555_testfile.txt'

node.default['osl-app']['db_hostname'] = node['ipaddress']
