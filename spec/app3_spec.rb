require_relative 'spec_helper'

describe 'osl-app::app3' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7.dup.merge(step_into: %w(osl_app))).converge('sudo', described_recipe)
  end

  include_context 'common_stubs'

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
        description: "streamwebs #{env} app",
        after: %w(network.target),
        wanted_by: 'multi-user.target',
        type: 'forking',
        user: "streamwebs-#{env}",
        environment: { 'PATH' => "/home/streamwebs-#{env}/venv/bin" },
        environment_file: nil,
        working_directory: "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend",
        pid_file: "/home/streamwebs-#{env}/tmp/pids/gunicorn.pid",
        exec_start: "/home/streamwebs-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
          "-D --pid /home/streamwebs-#{env}/tmp/pids/gunicorn.pid "\
          "--access-logfile /home/streamwebs-#{env}/logs/access.log "\
          "--error-logfile /home/streamwebs-#{env}/logs/error.log "\
          'streamwebs_frontend.wsgi:application',
        exec_reload: '/bin/kill -USR2 $MAINPID'
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
        pid_file: "/home/timesync-web-#{env}/tmp/pids/unicorn.pid"
      )
    end

    it do
      port = env == 'staging' ? 8082 : 8083
      expect(chef_run).to create_systemd_service("timesync-web-#{env}").with(
        description: "timesync-web #{env} app",
        after: %w(network.target),
        wanted_by: 'multi-user.target',
        type: 'forking',
        user: "timesync-web-#{env}",
        environment: { 'PATH' => "/home/timesync-web-#{env}/venv/bin" },
        environment_file: nil,
        working_directory: "/home/timesync-web-#{env}/timesync-web",
        pid_file: "/home/timesync-web-#{env}/tmp/pids/unicorn.pid",
        exec_start: "/home/timesync-web-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
          "-D --pid /home/timesync-web-#{env}/tmp/pids/gunicorn.pid wsgi:app",
        exec_reload: '/bin/kill -USR2 $MAINPID'
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
end
