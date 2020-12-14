%w(production staging).each do |env|
  directory "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media" do
    recursive true
  end

  file "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend/media/index.html" do
    content "streamwebs-#{env}"
  end
end

include_recipe 'osl-mysql::server'

[
  %w(etherpad mysql_creds_osl),
  %w(etherpad mysql_creds_snowdrift),
  %w(mulgara_redmine mysql_creds),
].each do |bag, item|
  dbcreds = data_bag_item(bag, item)
  dbcreds['db_hostname'] = '172.%'

  percona_mysql_user dbcreds['db_user'] do
    host dbcreds['db_hostname']
    password dbcreds['db_passwd']
    ctrl_password ''
    action :create
  end

  percona_mysql_database dbcreds['db_db'] do
    password ''
  end

  percona_mysql_user dbcreds['db_user'] do
    host dbcreds['db_hostname']
    database_name dbcreds['db_db']
    privileges ['ALL PRIVILEGES']
    table '*'
    password dbcreds['db_passwd']
    ctrl_password ''
    action :grant
  end
end

cookbook_file '/tmp/mulgara_redmine.sql' do
  source 'mulgara_redmine.sql'
  sensitive true # just to supress wall of text
end

execute 'mysql mulgara_redmine < /tmp/mulgara_redmine.sql && touch /tmp/mulgara_redmine.done' do
  creates '/tmp/mulgara_redmine.done'
end

directory '/data/docker/code.mulgara.org/2019/09' do
  recursive true
end

cookbook_file '/data/docker/code.mulgara.org/2019/09/190923192555_testfile.txt' do
  source '190923192555_testfile.txt'
end
