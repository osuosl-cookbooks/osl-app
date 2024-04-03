openid_secrets = data_bag_item('osl-app', 'openid')

osl_mysql_test 'openid_goldfish_prod' do
  username 'openid_goldfish'
  password openid_secrets['db_password']
end

mariadb_database 'openid_goldfish_staging' do
  password 'osl_mysql_test'
  encoding 'utf8mb4'
  collation 'utf8mb4_unicode_ci'
end

mariadb_user 'openid_goldfish' do
  ctrl_password 'osl_mysql_test'
  password openid_secrets['db_password']
  database_name 'openid_goldfish_staging'
  host '172.%'
  action [:create, :grant]
end

mariadb_user 'openid_goldfish' do
  ctrl_password 'osl_mysql_test'
  database_name 'openid_goldfish_prod'
  password openid_secrets['db_password']
  host '172.%'
  privileges [:all]
  action [:create, :grant]
end
