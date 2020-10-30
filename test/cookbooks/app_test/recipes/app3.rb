%w(production staging).each do |env|
  directory "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media" do
    recursive true
  end

  file "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media/index.html" do
    content "streamwebs-#{env}"
  end
end

include_recipe 'osl-mysql::server'

%w(mulgara_redmine etherpad_osl etherpad_sd).each do |db|
  percona_mysql_database db do
    password 'password'
    database_name db
    action :create
  end
end

[
  %w(redmine mulgara_redmine),
  %w(etherpad_osl etherpad_osl),
  %w(etherpad_sd etherpad_sd),
].each do |user, db|
  percona_mysql_user user do
    database_name db
    privileges [:all]
    password 'passwd'
    host '172.17.%'
    ctrl_password 'password'
    action [:create, :grant]
  end
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
