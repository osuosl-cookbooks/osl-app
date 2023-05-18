require 'chefspec'
require 'chefspec/berkshelf'

CENTOS_7 = {
  platform: 'centos',
  version: '7',
}.freeze

ALMA_8 = {
  platform: 'almalinux',
  version: '8',
}.freeze

ALL_PLATFORMS = [
  CENTOS_7,
  ALMA_8,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end

shared_context 'common_stubs' do
  before do
    stub_command('which sudo')
    stub_command('which nginx')
    stub_search('users', '*:*').and_return([])

    stub_data_bag_item('replicant_redmine', 'mysql_creds').and_return(
      db_db: 'fakedb',
      db_hostname: 'testdb.osuosl.bak',
      db_passwd: 'fakepw',
      db_user: 'fakeuser'
    )
    stub_data_bag_item('osl-app', 'formsender').and_return(
      token: 'faketoken',
      rt_token: 'rt_faketoken',
      recaptcha_secret: 'fakerecaptcha'
    )

    stub_data_bag_item('mulgara_redmine', 'mysql_creds').and_return(
      db_db: 'fakedb',
      db_hostname: 'testdb.osuosl.bak',
      db_passwd: 'fakepw',
      db_user: 'fakeuser'
    )
    %w(osl snowdrift).each do |type|
      stub_data_bag_item('etherpad', type).and_return(
        db_db: 'fakedb',
        db_hostname: 'testdb.osuosl.bak',
        db_passwd: 'fakepw',
        db_user: 'fakeuser',
        admin_passwd: 'fakeadmin'
      )
    end
  end
end
