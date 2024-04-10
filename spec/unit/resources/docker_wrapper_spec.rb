require_relative '../../spec_helper'

describe 'osl_app_docker_wrapper' do
  platform 'centos'
  step_into :osl_app_docker_wrapper

  cached(:subject) { chef_run }

  recipe do
    osl_app_docker_wrapper 'test_app' do
      user 'test_app'
    end

    osl_app_docker_wrapper 'test_app_bash' do
      user 'test_app_bash'
      command 'bash'
    end
  end

  it do
    is_expected.to create_template('/usr/local/bin/test_app-console').with(
      source: 'docker-console.erb',
      cookbook: 'osl-app',
      mode: '0750',
      variables: {
        container_name: 'test_app',
        command: 'sh',
      }
    )
  end

  it do
    is_expected.to create_template('/usr/local/bin/test_app_bash-console').with(
      source: 'docker-console.erb',
      cookbook: 'osl-app',
      mode: '0750',
      variables: {
        container_name: 'test_app_bash',
        command: 'bash',
      }
    )
  end

  it do
    is_expected.to create_template('/usr/local/bin/test_app-logs').with(
      source: 'docker-logs.erb',
      cookbook: 'osl-app',
      mode: '0750',
      variables: {
        container_name: 'test_app',
      }
    )
  end

  it do
    is_expected.to create_sudo('test_app').with(
      user: %w(test_app),
      commands: [
        '/usr/local/bin/test_app-console',
        '/usr/local/bin/test_app-logs',
      ],
      nopasswd: true
    )
  end
end
