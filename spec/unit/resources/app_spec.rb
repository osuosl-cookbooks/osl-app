require_relative '../../spec_helper'

describe 'osl_app' do
  platform 'centos'
  step_into :osl_app

  context 'create' do
    cached(:subject) { chef_run }

    recipe do
      osl_app 'test_app' do
        start_cmd '/opt/test/bin/test start'
      end
    end

    it do
      is_expected.to create_systemd_unit('test_app.service').with(
        content: {
          'Unit' => {
            'After' => 'network.target',
          },
          'Install' => {
            'WantedBy' => 'multi-user.target',
          },
          'Service' => {
            'Type' => 'forking',
            'User' => 'test_app',
            'ExecStart' => '/opt/test/bin/test start',
            'ExecReload' => '/bin/kill -USR2 $MAINPID',
          },
        }
      )
    end

    it do
      is_expected.to enable_systemd_unit('test_app.service')
    end

    it do
      is_expected.to nothing_sudo('test_app').with(
        commands: [
          '/usr/bin/systemctl enable test_app',
          '/usr/bin/systemctl disable test_app',
          '/usr/bin/systemctl stop test_app',
          '/usr/bin/systemctl start test_app',
          '/usr/bin/systemctl status test_app',
          '/usr/bin/systemctl reload test_app',
          '/usr/bin/systemctl restart test_app',
        ],
        nopasswd: true
      )
    end

    it do
      expect(subject.systemd_unit('test_app.service')).to notify('sudo[test_app]').to(:create).immediately
    end
  end

  context 'delete' do
    cached(:subject) { chef_run }

    recipe do
      osl_app 'test_app' do
        start_cmd '/opt/test/bin/test start'
        action :delete
      end
    end

    it do
      is_expected.to stop_systemd_unit('test_app.service')
    end

    it do
      is_expected.to disable_systemd_unit('test_app.service')
    end

    it do
      is_expected.to delete_systemd_unit('test_app.service')
    end

    it do
      is_expected.to delete_sudo('test_app')
    end
  end

  context 'create_with_options' do
    cached(:subject) { chef_run }

    recipe do
      osl_app 'test_app' do
        description 'test_app'
        service_after 'default.target'
        wanted_by 'multi-user.target'
        service_type 'simple'
        user 'testuser'
        environment 'TEST_PATH=/opt/test'
        working_directory '/opt/test'
        start_cmd '/opt/test/bin/test start'
        reload_cmd '/opt/test/bin/test restart'
      end
    end

    it do
      is_expected.to create_systemd_unit('test_app.service').with(
        content: {
          'Unit' => {
            'Description' => 'test_app',
            'After' => 'default.target',
          },
          'Install' => {
            'WantedBy' => 'multi-user.target',
          },
          'Service' => {
            'Type' => 'simple',
            'User' => 'testuser',
            'Environment' => 'TEST_PATH=/opt/test',
            'WorkingDirectory' => '/opt/test',
            'ExecStart' => '/opt/test/bin/test start',
            'ExecReload' => '/opt/test/bin/test restart',
          },
        }
      )
    end

    it do
      is_expected.to enable_systemd_unit('test_app.service')
    end

    it do
      is_expected.to nothing_sudo('testuser').with(
        commands: [
          '/usr/bin/systemctl enable test_app',
          '/usr/bin/systemctl disable test_app',
          '/usr/bin/systemctl stop test_app',
          '/usr/bin/systemctl start test_app',
          '/usr/bin/systemctl status test_app',
          '/usr/bin/systemctl reload test_app',
          '/usr/bin/systemctl restart test_app',
        ],
        nopasswd: true
      )
    end

    it do
      expect(subject.systemd_unit('test_app.service')).to notify('sudo[testuser]').to(:create).immediately
    end
  end
end
