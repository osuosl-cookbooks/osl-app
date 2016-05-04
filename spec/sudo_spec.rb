require 'chefspec'
require 'chefspec/berkshelf'

describe 'osl-app::sudo' do
  context 'on centos 7.2' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos',
                               version: '7.2.1511').converge(described_recipe)
    end

    it 'should create systemctl privs for openid-staging' do
      expect(chef_run).to install_sudo('openid-staging').with(
        commands: ['/usr/bin/systemctl enable openid-staging-unicorn',
                   '/usr/bin/systemctl disable openid-staging-unicorn',
                   '/usr/bin/systemctl stop openid-staging-unicorn',
                   '/usr/bin/systemctl start openid-staging-unicorn',
                   '/usr/bin/systemctl reload openid-staging-unicorn',
                   '/usr/bin/systemctl restart openid-staging-unicorn',
                   '/usr/bin/systemctl enable openid-staging-delayed-job',
                   '/usr/bin/systemctl disable openid-staging-delayed-job',
                   '/usr/bin/systemctl stop openid-staging-delayed-job',
                   '/usr/bin/systemctl start openid-staging-delayed-job',
                   '/usr/bin/systemctl reload openid-staging-delayed-job',
                   '/usr/bin/systemctl restart openid-staging-delayed-job']
      )
    end

    it 'should create systemctl privs for openid-production' do
      expect(chef_run).to install_sudo('openid-production').with(
        commands: ['/usr/bin/systemctl enable openid-production-unicorn',
                   '/usr/bin/systemctl disable openid-production-unicorn',
                   '/usr/bin/systemctl stop openid-production-unicorn',
                   '/usr/bin/systemctl start openid-production-unicorn',
                   '/usr/bin/systemctl reload openid-production-unicorn',
                   '/usr/bin/systemctl restart openid-production-unicorn',
                   '/usr/bin/systemctl enable openid-production-delayed-job',
                   '/usr/bin/systemctl disable openid-production-delayed-job',
                   '/usr/bin/systemctl stop openid-production-delayed-job',
                   '/usr/bin/systemctl start openid-production-delayed-job',
                   '/usr/bin/systemctl reload openid-production-delayed-job',
                   '/usr/bin/systemctl restart openid-production-delayed-job']
      )
    end
  end
end
