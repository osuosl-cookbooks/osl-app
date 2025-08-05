require 'chefspec'
require 'chefspec/berkshelf'

ALMA_8 = {
  platform: 'almalinux',
  version: '8',
}.freeze
ALMA_9 = {
  platform: 'almalinux',
  version: '9',
}.freeze

ALL_PLATFORMS = [
  ALMA_8,
  ALMA_9,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end

shared_context 'common_stubs' do
  before do
    stub_command('which sudo')
    stub_command('which nginx')
    stub_data_bag_item('nginx', 'dhparam').and_return(
      'id' => 'dhparam',
      'key' => 'dh param key'
    )
    stub_search('users', '*:*').and_return([])
    stub_data_bag_item('docker', 'ghcr-io').and_return(
      username: 'gh_user',
      password: 'gh_password'
    )
    stub_command('iptables -C INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null').and_return(true)
  end
end
