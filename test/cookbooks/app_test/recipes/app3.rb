%w(production staging).each do |env|
  directory "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media" do
    recursive true
  end

  file "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media/index.html" do
    content "streamwebs-#{env}"
  end
end

include_recipe 'osl-mysql::server'
include_recipe 'build-essential'

mysql2_chef_gem 'default' do
  provider Chef::Provider::Mysql2ChefGem::Percona
  action :install
end

mysql_database 'mulgara_redmine' do
  connection(
    host: '127.0.0.1',
    user: 'root',
    password: 'password'
  )
  action :create
end

mysql_database_user 'redmine' do
  database_name 'mulgara_redmine'
  password 'passwd'
  host '172.17.%'
  connection(
    host: '127.0.0.1',
    user: 'root',
    password: 'password'
  )
  action [:create, :grant]
end

cookbook_file '/tmp/mulgara_redmine.sql'

execute 'mysql mulgara_redmine < /tmp/mulgara_redmine.sql && touch /tmp/mulgara_redmine.done' do
  creates '/tmp/mulgara_redmine.done'
end

node.default['osl-app']['mulgara_redmine_mysql_hostname'] = node['ipaddress']
