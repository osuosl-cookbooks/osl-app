require 'chefspec'
require 'chefspec/berkshelf'

CENTOS_7 = {
  platform: 'centos',
  version: '7',
}.freeze

ALL_PLATFORMS = [
  CENTOS_7,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end

shared_context 'common_stubs' do
  before do
    stub_command('which sudo')
    stub_command('which nginx')
    stub_search('users', '*:*').and_return([])
  end
end
