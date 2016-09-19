require_relative 'spec_helper'

describe 'osl-app::default' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7).converge('sudo', described_recipe)
  end
  include_context 'common_stubs'
  it do
    expect { chef_run }.to_not raise_error
  end
end
