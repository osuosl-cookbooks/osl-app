require_relative '../../spec_helper'

describe 'osl_app_dockercompose_wrapper' do
  platform 'centos'
  step_into :osl_app_dockercompose_wrapper

  cached(:subject) { chef_run }

  recipe do
    osl_app_dockercompose_wrapper 'test_app' do
      directory '/home/test_app/project'
      config_files %w(docker-compose.deploy.yml)
      user 'test_app'
    end

    osl_app_dockercompose_wrapper 'test_app_custom' do
      directory '/home/test_app_custom/project'
      config_files %w(docker-compose.deploy.yml docker-compose.mailpit.yml)
      service 'web'
      command 'bash'
      user 'test_app_custom'
    end
  end

  it do
    is_expected.to create_template('/usr/local/bin/test_app-console').with(
      source: 'dockercompose-console.erb',
      cookbook: 'osl-app',
      mode: '0750',
      variables: {
        directory: '/home/test_app/project',
        project_name: 'test_app',
        config_flags: '-f docker-compose.deploy.yml ',
        service: 'app',
        command: 'sh',
      }
    )
  end

  it do
    is_expected.to create_template('/usr/local/bin/test_app_custom-console').with(
      source: 'dockercompose-console.erb',
      cookbook: 'osl-app',
      mode: '0750',
      variables: {
        directory: '/home/test_app_custom/project',
        project_name: 'test_app_custom',
        config_flags: '-f docker-compose.deploy.yml -f docker-compose.mailpit.yml ',
        service: 'web',
        command: 'bash',
      }
    )
  end

  it do
    is_expected.to create_template('/usr/local/bin/test_app-logs').with(
      source: 'dockercompose-logs.erb',
      cookbook: 'osl-app',
      mode: '0750',
      variables: {
        directory: '/home/test_app/project',
        project_name: 'test_app',
        config_flags: '-f docker-compose.deploy.yml ',
        service: 'app',
      }
    )
  end

  it do
    is_expected.to create_template('/usr/local/bin/test_app_custom-logs').with(
      source: 'dockercompose-logs.erb',
      cookbook: 'osl-app',
      mode: '0750',
      variables: {
        directory: '/home/test_app_custom/project',
        project_name: 'test_app_custom',
        config_flags: '-f docker-compose.deploy.yml -f docker-compose.mailpit.yml ',
        service: 'web',
      }
    )
  end

  it do
    is_expected.to create_template('/usr/local/bin/test_app-ps').with(
      source: 'dockercompose-ps.erb',
      cookbook: 'osl-app',
      mode: '0750',
      variables: {
        directory: '/home/test_app/project',
        project_name: 'test_app',
        config_flags: '-f docker-compose.deploy.yml ',
      }
    )
  end

  it do
    is_expected.to create_template('/usr/local/bin/test_app_custom-ps').with(
      source: 'dockercompose-ps.erb',
      cookbook: 'osl-app',
      mode: '0750',
      variables: {
        directory: '/home/test_app_custom/project',
        project_name: 'test_app_custom',
        config_flags: '-f docker-compose.deploy.yml -f docker-compose.mailpit.yml ',
      }
    )
  end

  it do
    is_expected.to create_sudo('test_app').with(
      user: %w(test_app),
      commands: [
        '/usr/local/bin/test_app-console',
        '/usr/local/bin/test_app-logs',
        '/usr/local/bin/test_app-ps',
      ],
      nopasswd: true
    )
  end

  it do
    is_expected.to create_sudo('test_app_custom').with(
      user: %w(test_app_custom),
      commands: [
        '/usr/local/bin/test_app_custom-console',
        '/usr/local/bin/test_app_custom-logs',
        '/usr/local/bin/test_app_custom-ps',
      ],
      nopasswd: true
    )
  end

  it do
    expect(chef_run).to render_file('/usr/local/bin/test_app-console')
      .with_content(/usage\(\)/)
      .with_content(/Open a console on a container in the test_app compose project/)
      .with_content(/SERVICE\s+Service name to exec into \(default: app\)/)
      .with_content(/docker compose -p test_app -f docker-compose\.deploy\.yml exec \$\{SERVICE\} sh/)
  end

  it do
    expect(chef_run).to render_file('/usr/local/bin/test_app_custom-console')
      .with_content(/Open a console on a container in the test_app_custom compose project/)
      .with_content(/SERVICE\s+Service name to exec into \(default: web\)/)
      .with_content(/docker compose -p test_app_custom -f docker-compose\.deploy\.yml -f docker-compose\.mailpit\.yml exec \$\{SERVICE\} bash/)
  end

  it do
    expect(chef_run).to render_file('/usr/local/bin/test_app-logs')
      .with_content(/usage\(\)/)
      .with_content(/View logs for a container in the test_app compose project/)
      .with_content(/SERVICE\s+Service name to view logs for \(default: app\)/)
      .with_content(/docker compose -p test_app -f docker-compose\.deploy\.yml logs \$\{FOLLOW\} \$\{SERVICE\}/)
  end

  it do
    expect(chef_run).to render_file('/usr/local/bin/test_app_custom-logs')
      .with_content(/View logs for a container in the test_app_custom compose project/)
      .with_content(/SERVICE\s+Service name to view logs for \(default: web\)/)
      .with_content(/docker compose -p test_app_custom -f docker-compose\.deploy\.yml -f docker-compose\.mailpit\.yml logs \$\{FOLLOW\} \$\{SERVICE\}/)
  end

  it do
    expect(chef_run).to render_file('/usr/local/bin/test_app-ps')
      .with_content(/usage\(\)/)
      .with_content(/List containers in the test_app compose project/)
      .with_content(/docker compose -p test_app -f docker-compose\.deploy\.yml ps/)
  end

  it do
    expect(chef_run).to render_file('/usr/local/bin/test_app_custom-ps')
      .with_content(/List containers in the test_app_custom compose project/)
      .with_content(/docker compose -p test_app_custom -f docker-compose\.deploy\.yml -f docker-compose\.mailpit\.yml ps/)
  end
end
