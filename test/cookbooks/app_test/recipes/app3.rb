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

include_recipe 'osl-docker'

docker_image 'postgis/postgis'

docker_container 'pg_streamwebs_staging' do
  repo 'postgis/postgis'
  env [
    'POSTGRES_DB=streamwebs-staging',
    'POSTGRES_USER=streamwebs-staging',
    'POSTGRES_PASSWORD=staging_password',
  ]
end

cookbook_file '/tmp/mulgara_redmine.sql' do
  source 'mulgara_redmine.sql'
  sensitive true # just to supress wall of text
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
