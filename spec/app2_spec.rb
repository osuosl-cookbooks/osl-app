require 'chefspec'
require 'chefspec/berkshelf'

describe 'osl-app::app2' do
  context 'on centos 7.2' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos',
                               version: '7.2.1511').converge(described_recipe)
    end

    before do
      stub_data_bag_item('osl-app', 'formsender').and_return(
        secret_key_base: '7eef5c70ecb083192f46e601144f9d77c9b66061b634963a507'\
          '0fb086ae78bc9353af2c6311edb168abbb9d0bd428f800a0b1713534cf4ad239e8d'\
          '07fdd16c34'
      )
    end

    it 'should create systemctl privs for formsender-staging' do
      expect(chef_run).to install_sudo('formsender-staging').with(
        commands: ['/usr/bin/systemctl enable formsender-staging-ggunicorn',
                   '/usr/bin/systemctl disable formsender-staging-ggunicorn',
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

    %w(formsender-staging-gunicorn formsender-production-gunicorn ).each do |s|
      it "should create system service #{s}" do
        expect(chef_run).to create_systemd_service(s)
      end
    end
  end
end
