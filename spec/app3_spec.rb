require_relative 'spec_helper'

describe 'osl-app::app3' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7.dup.merge(step_into: %w(osl_app))).converge('sudo', described_recipe)
  end
  include_context 'common_stubs'

  it 'should create systemctl privs for streamwebs-staging-gunicorn' do
    expect(chef_run).to create_sudo('streamwebs-staging').with(
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

  it 'should create systemctl privs for streamwebs-production-gunicorn' do
    expect(chef_run).to create_sudo('streamwebs-production').with(
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

  it 'should create systemctl privs for timesync-web-production' do
    expect(chef_run).to create_sudo('timesync-web-production').with(
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
    expect(chef_run).to create_sudo('timesync-web-staging').with(
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

  %w(streamwebs-production-gunicorn
     streamwebs-staging-gunicorn
     timesync-web-production
     timesync-web-staging).each do |s|
    it do
      expect(chef_run).to create_osl_app(s)
    end

    it "should create system service #{s}" do
      expect(chef_run).to create_systemd_service(s)
    end

    it "should enable system service #{s}" do
      expect(chef_run).to enable_systemd_service(s)
    end
  end

  it do
    expect(chef_run).to modify_group('streamwebs-production').with(members: %w(streamwebs-production nginx))
  end
  it do
    expect(chef_run).to modify_group('streamwebs-staging').with(members: %w(streamwebs-staging nginx))
  end
end
