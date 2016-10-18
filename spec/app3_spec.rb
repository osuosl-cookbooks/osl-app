require_relative 'spec_helper'

describe 'osl-app::app3' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7).converge('sudo', described_recipe)
  end
  include_context 'common_stubs'

  it 'should create systemctl privs for streamwebs-staging' do
    expect(chef_run).to install_sudo('streamwebs-staging').with(
      commands: ['/usr/bin/systemctl enable streamwebs-staging-gunicorn',
                 '/usr/bin/systemctl disable streamwebs-staging-gunicorn',
                 '/usr/bin/systemctl stop streamwebs-staging-gunicorn',
                 '/usr/bin/systemctl start streamwebs-staging-gunicorn',
                 '/usr/bin/systemctl status streamwebs-staging-gunicorn',
                 '/usr/bin/systemctl reload streamwebs-staging-gunicorn',
                 '/usr/bin/systemctl restart streamwebs-staging-gunicorn'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for streamwebs-production' do
    expect(chef_run).to install_sudo('streamwebs-production').with(
      commands: ['/usr/bin/systemctl enable streamwebs-production-gunicorn',
                 '/usr/bin/systemctl disable streamwebs-production-gunicorn',
                 '/usr/bin/systemctl stop streamwebs-production-gunicorn',
                 '/usr/bin/systemctl start streamwebs-production-gunicorn',
                 '/usr/bin/systemctl status streamwebs-production-gunicorn',
                 '/usr/bin/systemctl reload streamwebs-production-gunicorn',
                 '/usr/bin/systemctl restart streamwebs-production-gunicorn'],
      nopasswd: true
    )
  end

  %w(streamwebs-staging-gunicorn streamwebs-production-gunicorn).each do |s|
    it "should create system service #{s}" do
      expect(chef_run).to create_systemd_service(s)
    end
  end
end
