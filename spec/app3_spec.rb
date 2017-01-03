require_relative 'spec_helper'

describe 'osl-app::app3' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7).converge('sudo', described_recipe)
  end
  include_context 'common_stubs'

  it 'should create systemctl privs for streamwebs-staging' do
    expect(chef_run).to install_sudo('streamwebs-staging').with(
      commands: ['/usr/bin/systemctl enable streamwebs-staging',
                 '/usr/bin/systemctl disable streamwebs-staging',
                 '/usr/bin/systemctl stop streamwebs-staging',
                 '/usr/bin/systemctl start streamwebs-staging',
                 '/usr/bin/systemctl status streamwebs-staging',
                 '/usr/bin/systemctl reload streamwebs-staging',
                 '/usr/bin/systemctl restart streamwebs-staging'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for streamwebs-production' do
    expect(chef_run).to install_sudo('streamwebs-production').with(
      commands: ['/usr/bin/systemctl enable streamwebs-production',
                 '/usr/bin/systemctl disable streamwebs-production',
                 '/usr/bin/systemctl stop streamwebs-production',
                 '/usr/bin/systemctl start streamwebs-production',
                 '/usr/bin/systemctl status streamwebs-production',
                 '/usr/bin/systemctl reload streamwebs-production',
                 '/usr/bin/systemctl restart streamwebs-production'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for timesync-web-production' do
    expect(chef_run).to install_sudo('timesync-web-production').with(
      commands: ['/usr/bin/systemctl enable timesync-web-production',
                 '/usr/bin/systemctl disable timesync-web-production',
                 '/usr/bin/systemctl stop timesync-web-production',
                 '/usr/bin/systemctl start timesync-web-production',
                 '/usr/bin/systemctl status timesync-web-production',
                 '/usr/bin/systemctl reload timesync-web-production',
                 '/usr/bin/systemctl restart timesync-web-production'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for timesync-web-staging' do
    expect(chef_run).to install_sudo('timesync-web-staging').with(
      commands: ['/usr/bin/systemctl enable timesync-web-staging',
                 '/usr/bin/systemctl disable timesync-web-staging',
                 '/usr/bin/systemctl stop timesync-web-staging',
                 '/usr/bin/systemctl start timesync-web-staging',
                 '/usr/bin/systemctl status timesync-web-staging',
                 '/usr/bin/systemctl reload timesync-web-staging',
                 '/usr/bin/systemctl restart timesync-web-staging'],
      nopasswd: true
    )
  end

  %w(streamwebs-staging-gunicorn streamwebs-production-gunicorn
     timesync-web-staging timesync-web-production).each do |s|
    it "should create system service #{s}" do
      expect(chef_run).to create_systemd_service(s)
    end
  end
end
