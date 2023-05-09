replicant_dbcreds = data_bag_item('replicant_redmine', 'mysql_creds')
replicant_dbcreds['db_hostname'] = '172.%'

osl_mysql_test replicant_dbcreds['db_db'] do
  username replicant_dbcreds['db_user']
  password replicant_dbcreds['db_passwd']
end

osl_firewall_port 'mysql'

cookbook_file '/tmp/replicant_redmine.sql' do
  source 'replicant_redmine.sql'
  sensitive true # just to supress wall of text
end

execute 'import sql dump' do
  command "mysql #{replicant_dbcreds['db_db']} < /tmp/replicant_redmine.sql && touch /root/.replicant-imported"
  creates '/root/.replicant-imported'
end

directory '/data/docker/redmine.replicant.us/2019/09/' do
  recursive true
end

cookbook_file '/data/docker/redmine.replicant.us/2019/09/190923192555_testfile.txt' do
  source '190923192555_testfile.txt'
end
