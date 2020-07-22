require_relative 'spec_helper'

describe 'osl-app::app3' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7.dup.merge(step_into: %w(osl_app))).converge('sudo', described_recipe)
  end

  include_context 'common_stubs'

  before do
    stub_data_bag_item('mulgara_redmine', 'mysql_creds').and_return(
      db_db: 'fakedb',
      db_hostname: 'testdb.osuosl.bak',
      db_passwd: 'fakepw',
      db_user: 'fakeuser'
    )
  end

  %w(staging production).each do |env|
    it do
      port = env == 'staging' ? 8081 : 8080
      expect(chef_run).to create_osl_app("streamwebs-#{env}-gunicorn").with(
        description: "streamwebs #{env} app",
        user: "streamwebs-#{env}",
        start_cmd: "/home/streamwebs-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
          "-D --pid /home/streamwebs-#{env}/tmp/pids/gunicorn.pid "\
          "--access-logfile /home/streamwebs-#{env}/logs/access.log "\
          "--error-logfile /home/streamwebs-#{env}/logs/error.log "\
          'streamwebs_frontend.wsgi:application',
        environment: { 'PATH' => "/home/streamwebs-#{env}/venv/bin" },
        working_directory: "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend",
        pid_file: "/home/streamwebs-#{env}/tmp/pids/gunicorn.pid"
      )
    end

    it do
      port = env == 'staging' ? 8081 : 8080
      expect(chef_run).to create_systemd_service("streamwebs-#{env}-gunicorn").with(
        unit_description: "streamwebs #{env} app",
        unit_after: %w(network.target),
        install_wanted_by: 'multi-user.target',
        service_type: 'forking',
        service_user: "streamwebs-#{env}",
        service_environment: { 'PATH' => "/home/streamwebs-#{env}/venv/bin" },
        service_environment_file: nil,
        service_working_directory: "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend",
        service_pid_file: "/home/streamwebs-#{env}/tmp/pids/gunicorn.pid",
        service_exec_start: "/home/streamwebs-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
          "-D --pid /home/streamwebs-#{env}/tmp/pids/gunicorn.pid "\
          "--access-logfile /home/streamwebs-#{env}/logs/access.log "\
          "--error-logfile /home/streamwebs-#{env}/logs/error.log "\
          'streamwebs_frontend.wsgi:application',
        service_exec_reload: '/bin/kill -USR2 $MAINPID',
        verify: false
      )
    end

    it do
      port = env == 'staging' ? 8082 : 8083
      expect(chef_run).to create_osl_app("timesync-web-#{env}").with(
        description: "timesync-web #{env} app",
        start_cmd: "/home/timesync-web-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
          "-D --pid /home/timesync-web-#{env}/tmp/pids/gunicorn.pid wsgi:app",
        environment: { 'PATH' => "/home/timesync-web-#{env}/venv/bin" },
        working_directory: "/home/timesync-web-#{env}/timesync-web",
        pid_file: "/home/timesync-web-#{env}/tmp/pids/gunicorn.pid"
      )
    end

    it do
      port = env == 'staging' ? 8082 : 8083
      expect(chef_run).to create_systemd_service("timesync-web-#{env}").with(
        unit_description: "timesync-web #{env} app",
        unit_after: %w(network.target),
        install_wanted_by: 'multi-user.target',
        service_type: 'forking',
        service_user: "timesync-web-#{env}",
        service_environment: { 'PATH' => "/home/timesync-web-#{env}/venv/bin" },
        service_environment_file: nil,
        service_working_directory: "/home/timesync-web-#{env}/timesync-web",
        service_pid_file: "/home/timesync-web-#{env}/tmp/pids/gunicorn.pid",
        service_exec_start: "/home/timesync-web-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
          "-D --pid /home/timesync-web-#{env}/tmp/pids/gunicorn.pid wsgi:app",
        service_exec_reload: '/bin/kill -USR2 $MAINPID'
      )
    end
  end

  %w(staging production).each do |env|
    it do
      expect(chef_run).to create_sudo("streamwebs-#{env}").with(
        commands: ["/usr/bin/systemctl enable streamwebs-#{env}-gunicorn",
                   "/usr/bin/systemctl disable streamwebs-#{env}-gunicorn",
                   "/usr/bin/systemctl stop streamwebs-#{env}-gunicorn",
                   "/usr/bin/systemctl start streamwebs-#{env}-gunicorn",
                   "/usr/bin/systemctl status streamwebs-#{env}-gunicorn",
                   "/usr/bin/systemctl reload streamwebs-#{env}-gunicorn",
                   "/usr/bin/systemctl restart streamwebs-#{env}-gunicorn"],
        nopasswd: true
      )
    end

    it do
      expect(chef_run).to create_sudo("timesync-web-#{env}").with(
        commands: ["/usr/bin/systemctl enable timesync-web-#{env}",
                   "/usr/bin/systemctl disable timesync-web-#{env}",
                   "/usr/bin/systemctl stop timesync-web-#{env}",
                   "/usr/bin/systemctl start timesync-web-#{env}",
                   "/usr/bin/systemctl status timesync-web-#{env}",
                   "/usr/bin/systemctl reload timesync-web-#{env}",
                   "/usr/bin/systemctl restart timesync-web-#{env}"],
        nopasswd: true
      )
    end
  end

  %w(streamwebs-production-gunicorn
     streamwebs-staging-gunicorn
     timesync-web-production
     timesync-web-staging).each do |s|
    it do
      expect(chef_run).to enable_systemd_service(s)
    end
  end

  it do
    expect(chef_run).to modify_group('streamwebs-production').with(members: %w(streamwebs-production nginx))
  end

  it do
    expect(chef_run).to modify_group('streamwebs-staging').with(members: %w(streamwebs-staging nginx))
  end

  it do
    expect(chef_run).to create_nginx_app('app3.osuosl.org').with(
      template: 'app-nginx.erb',
      cookbook: 'osl-app'
    )
  end

  it do
    expect(chef_run).to create_directory('/data/docker/code.mulgara.org').with(
      recursive: true
    )
  end

  it do
    expect(chef_run).to pull_docker_image('library/redmine').with(
      tag: '4.1.1'
    )
  end

  it do
    expect(chef_run).to run_docker_container('code.mulgara.org').with(
      repo: 'redmine',
      tag: '4.1.1',
      port: '8084:3000',
      restart_policy: 'always',
      # This needs to be volumes_binds, since the volumes property gets coerced into a volumes_binds property if it's
      # passed an entry that specifies a bind mount
      # https://github.com/chef-cookbooks/docker/blob/v4.9.3/libraries/docker_container.rb#L210
      volumes_binds: ['/data/docker/code.mulgara.org:/usr/src/redmine/files'],
      env: [
        'REDMINE_DB_MYSQL=testdb.osuosl.bak',
        'REDMINE_DB_DATABASE=fakedb',
        'REDMINE_DB_USERNAME=fakeuser',
        'REDMINE_DB_PASSWORD=fakepw',
        'REDMINE_PLUGINS_MIGRATE=1',
      ]
    )
  end
end
