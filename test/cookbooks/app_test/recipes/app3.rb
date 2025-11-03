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

  # Create the same user with a different host destination to allow for them to connect remotely
  mariadb_user dbcreds['db_user'] do
    password dbcreds['db_passwd']
    host dbcreds['db_hostname']
    database_name dbcreds['db_db']
    ctrl_password 'osl_mysql_test'
    action [:create, :grant]
  end
end

osl_postgresql_test 'streamwebs-staging' do
  username 'streamwebs-staging'
  password 'staging_password'
  source :repo
  postgis true
  additional_users [
    {
      name: 'streamwebs-production',
      password: 'production_password',
    },
    {
      name: 'invasives-staging',
      password: 'invasives-staging',
    },
  ]
  additional_databases [
    {
      name: 'streamwebs-production',
      owner: 'streamwebs-production',
    },
    {
      name: 'invasives-staging',
      owner: 'invasives-staging',
    },
  ]
  notifies :reload, 'service[postgresql-16]', :immediately
end

service 'postgresql-16' do
  action :nothing
end

cookbook_file '/tmp/mulgara_redmine.sql' do
  source 'mulgara_redmine.sql'
  sensitive true # just to suppress wall of text
end

execute 'mysql -posl_mysql_test mulgara_redmine < /tmp/mulgara_redmine.sql && touch /tmp/mulgara_redmine.done' do
  creates '/tmp/mulgara_redmine.done'
end

directory '/data/docker/code.mulgara.org/2019/09' do
  recursive true
end

cookbook_file '/data/docker/code.mulgara.org/2019/09/190923192555_testfile.txt' do
  source '190923192555_testfile.txt'
end
