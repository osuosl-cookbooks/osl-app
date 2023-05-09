[
  %w(etherpad osl),
  %w(etherpad snowdrift),
  %w(mulgara_redmine mysql_creds),
].each do |bag, item|
  dbcreds = data_bag_item(bag, item)
  dbcreds['db_hostname'] = '172.%'

  osl_mysql_test dbcreds['db_db'] do
    username dbcreds['db_user']
    password dbcreds['db_passwd']
  end
end

osl_firewall_port 'mysql'

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
