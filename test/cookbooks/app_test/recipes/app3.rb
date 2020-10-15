%w(production staging).each do |env|
  directory "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media" do
    recursive true
  end

  file "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media/index.html" do
    content "streamwebs-#{env}"
  end
end

include_recipe 'osl-mysql::server'

mariadb_database 'mulgara_redmine' do
  password 'password'
  database_name 'mulgara_redmine'
  action :create
end

mariadb_user 'redmine' do
  database_name 'mulgara_redmine'
  privileges [:all]
  password 'passwd'
  host '172.17.%'
  ctrl_password 'password'
  action [:create, :grant]
end

cookbook_file '/tmp/mulgara_redmine.sql'

execute 'mysql mulgara_redmine < /tmp/mulgara_redmine.sql && touch /tmp/mulgara_redmine.done' do
  creates '/tmp/mulgara_redmine.done'
end

directory '/data/docker/code.mulgara.org/2019/09' do
  recursive true
end

cookbook_file '/data/docker/code.mulgara.org/2019/09/190923192555_testfile.txt'

node.default['osl-app']['db_hostname'] = node['ipaddress']
