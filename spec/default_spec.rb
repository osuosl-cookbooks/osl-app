require_relative 'spec_helper'

describe 'osl-app::default' do
  ALL_PLATFORMS.each do |plat|
    context "#{plat[:platform]} #{plat[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(plat) do |_node, server|
        end.converge(described_recipe)
      end

      include_context 'common_stubs'

      it do
        expect { chef_run }.to_not raise_error
      end

      it { expect(chef_run).to include_recipe('git') }
      it { expect(chef_run).to include_recipe('osl-docker') }
      it { expect(chef_run).to accept_osl_firewall_port('unicorn').with(osl_only: true) }
    end
  end
end
