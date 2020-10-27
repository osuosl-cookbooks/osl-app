include_recipe 'osl-mysql::server'

percona_mysql_database 'replicant_redmine' do
  password 'password'
  sql 'CREATE DATABASE replicant_redmine'
  action :query
end

percona_mysql_user 'redmine' do
  database_name 'replicant_redmine'
  password 'passwd'
  host '172.17.%'
  ctrl_password 'password'
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
