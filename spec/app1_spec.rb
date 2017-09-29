require_relative 'spec_helper'

describe 'osl-app::app1' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7).converge('sudo', described_recipe)
  end
  include_context 'common_stubs'

  before do
    stub_data_bag_item('osl-app', 'openid').and_return(
      secret_key_base: '7eef5c70ecb083192f46e601144f9d77c9b66061b634963a507'\
        '0fb086ae78bc9353af2c6311edb168abbb9d0bd428f800a0b1713534cf4ad239e8d'\
        '07fdd16c34',
      braintree_access_token: 'access_token$production$mnlc24xq7uGUqKczYhg5PpNGiVOkss'
    )
  end

  it 'should create systemctl privs for openid-staging' do
    expect(chef_run).to install_sudo('openid-staging').with(
      commands: ['/usr/bin/systemctl enable openid-staging-unicorn',
                 '/usr/bin/systemctl disable openid-staging-unicorn',
                 '/usr/bin/systemctl stop openid-staging-unicorn',
                 '/usr/bin/systemctl start openid-staging-unicorn',
                 '/usr/bin/systemctl status openid-staging-unicorn',
                 '/usr/bin/systemctl reload openid-staging-unicorn',
                 '/usr/bin/systemctl restart openid-staging-unicorn',
                 '/usr/bin/systemctl enable openid-staging-delayed-job',
                 '/usr/bin/systemctl disable openid-staging-delayed-job',
                 '/usr/bin/systemctl stop openid-staging-delayed-job',
                 '/usr/bin/systemctl start openid-staging-delayed-job',
                 '/usr/bin/systemctl status openid-staging-delayed-job',
                 '/usr/bin/systemctl reload openid-staging-delayed-job',
                 '/usr/bin/systemctl restart openid-staging-delayed-job'],
      nopasswd: true
    )
  end

  it 'should create systemctl privs for openid-production' do
    expect(chef_run).to install_sudo('openid-production').with(
      commands: ['/usr/bin/systemctl enable openid-production-unicorn',
                 '/usr/bin/systemctl disable openid-production-unicorn',
                 '/usr/bin/systemctl stop openid-production-unicorn',
                 '/usr/bin/systemctl start openid-production-unicorn',
                 '/usr/bin/systemctl status openid-production-unicorn',
                 '/usr/bin/systemctl reload openid-production-unicorn',
                 '/usr/bin/systemctl restart openid-production-unicorn',
                 '/usr/bin/systemctl enable openid-production-delayed-job',
                 '/usr/bin/systemctl disable openid-production-delayed-job',
                 '/usr/bin/systemctl stop openid-production-delayed-job',
                 '/usr/bin/systemctl start openid-production-delayed-job',
                 '/usr/bin/systemctl status openid-production-delayed-job',
                 '/usr/bin/systemctl reload openid-production-delayed-job',
                 '/usr/bin/systemctl restart openid-production-delayed-job'],
      nopasswd: true
    )
  end

  %w(openid-staging-unicorn openid-staging-delayed-job
     openid-production-unicorn openid-production-delayed-job).each do |s|
    it "should create system service #{s}" do
      expect(chef_run).to create_systemd_service(s)
    end
  end

  %w(production staging).each do |type|
    it "should create LogRotate service for OpenID-#{type}" do
      expect(chef_run).to enable_logrotate_app("OpenID-#{type}").with(
        path: "/home/openid-#{type}/shared/log/*.log",
        frequency: 'daily',
        postrotate: "/bin/kill -USR1 /home/openid-#{type}/current/tmp/pids/unicorn.pid",
        su: "openid-#{type} openid-#{type}",
        rotate: 30
      )
    end
  end
end
