require_relative 'spec_helper'

describe 'osl-app::app2' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7).converge('sudo', described_recipe)
  end
  include_context 'common_stubs'

  it 'should create systemctl privs for formsender-staging' do
    expect(chef_run).to install_sudo('formsender-staging').with(
      commands: ['/usr/bin/systemctl enable formsender-staging-gunicorn',
                 '/usr/bin/systemctl disable formsender-staging-gunicorn',
                 '/usr/bin/systemctl stop formsender-staging-gunicorn',
                 '/usr/bin/systemctl start formsender-staging-gunicorn',
                 '/usr/bin/systemctl status formsender-staging-gunicorn',
                 '/usr/bin/systemctl reload formsender-staging-gunicorn',
                 '/usr/bin/systemctl restart formsender-staging-gunicorn'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for formsender-production' do
    expect(chef_run).to install_sudo('formsender-production').with(
      commands: ['/usr/bin/systemctl enable formsender-production-gunicorn',
                 '/usr/bin/systemctl disable formsender-production-gunicorn',
                 '/usr/bin/systemctl stop formsender-production-gunicorn',
                 '/usr/bin/systemctl start formsender-production-gunicorn',
                 '/usr/bin/systemctl status formsender-production-gunicorn',
                 '/usr/bin/systemctl reload formsender-production-gunicorn',
                 '/usr/bin/systemctl restart formsender-production-gunicorn'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for iam-staging' do
    expect(chef_run).to install_sudo('iam-staging').with(
      commands: ['/usr/bin/systemctl enable iam-staging',
                 '/usr/bin/systemctl disable iam-staging',
                 '/usr/bin/systemctl stop iam-staging',
                 '/usr/bin/systemctl start iam-staging',
                 '/usr/bin/systemctl status iam-staging',
                 '/usr/bin/systemctl reload iam-staging',
                 '/usr/bin/systemctl restart iam-staging'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for iam-production' do
    expect(chef_run).to install_sudo('iam-production').with(
      commands: ['/usr/bin/systemctl enable iam-production',
                 '/usr/bin/systemctl disable iam-production',
                 '/usr/bin/systemctl stop iam-production',
                 '/usr/bin/systemctl start iam-production',
                 '/usr/bin/systemctl status iam-production',
                 '/usr/bin/systemctl reload iam-production',
                 '/usr/bin/systemctl restart iam-production'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for timesync-production' do
    expect(chef_run).to install_sudo('timesync-production').with(
      commands: ['/usr/bin/systemctl enable timesync-production',
                 '/usr/bin/systemctl disable timesync-production',
                 '/usr/bin/systemctl stop timesync-production',
                 '/usr/bin/systemctl start timesync-production',
                 '/usr/bin/systemctl status timesync-production',
                 '/usr/bin/systemctl reload timesync-production',
                 '/usr/bin/systemctl restart timesync-production'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for timesync-staging' do
    expect(chef_run).to install_sudo('timesync-staging').with(
      commands: ['/usr/bin/systemctl enable timesync-staging',
                 '/usr/bin/systemctl disable timesync-staging',
                 '/usr/bin/systemctl stop timesync-staging',
                 '/usr/bin/systemctl start timesync-staging',
                 '/usr/bin/systemctl status timesync-staging',
                 '/usr/bin/systemctl reload timesync-staging',
                 '/usr/bin/systemctl restart timesync-staging'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for replicant' do
    expect(chef_run).to install_sudo('replicant').with(
      commands: ['/usr/bin/systemctl enable replicant-redmine-webrick',
                 '/usr/bin/systemctl disable replicant-redmine-webrick',
                 '/usr/bin/systemctl stop replicant-redmine-webrick',
                 '/usr/bin/systemctl start replicant-redmine-webrick',
                 '/usr/bin/systemctl status replicant-redmine-webrick',
                 '/usr/bin/systemctl reload replicant-redmine-webrick',
                 '/usr/bin/systemctl restart replicant-redmine-webrick'],
      nopasswd: true
    )
  end

  %w(formsender-staging-gunicorn formsender-production-gunicorn
     iam-staging iam-production
     timesync-staging timesync-production
     replicant-redmine-webrick).each do |s|
    it "should create system service #{s}" do
      expect(chef_run).to create_systemd_service(s)
    end
  end
end
