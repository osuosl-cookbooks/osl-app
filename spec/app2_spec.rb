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

  %w(formsender-staging-gunicorn formsender-production-gunicorn
     iam-staging iam-production).each do |s|
    it "should create system service #{s}" do
      expect(chef_run).to create_systemd_service(s)
    end
  end
end
