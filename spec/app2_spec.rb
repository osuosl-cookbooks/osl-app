require_relative 'spec_helper'

describe 'osl-app::app2' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7.dup.merge(step_into: %w(osl_app))).converge('sudo', described_recipe)
  end

  include_context 'common_stubs'

  %w(staging production).each do |env|
    it do
      port = env == 'staging' ? 8086 : 8085
      expect(chef_run).to create_osl_app("formsender-#{env}-gunicorn").with(
        description: "formsender #{env} app",
        user: "formsender-#{env}",
        start_cmd: "/home/formsender-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
          "-D --pid /home/formsender-#{env}/tmp/pids/gunicorn.pid "\
          "--access-logfile /home/formsender-#{env}/logs/access.log "\
          "--error-logfile /home/formsender-#{env}/logs/error.log "\
          '--log-level debug '\
          'formsender.wsgi:application',
        environment: { 'PATH' => "/home/formsender-#{env}/venv/bin" },
        working_directory: "/home/formsender-#{env}/formsender",
        pid_file: "/home/formsender-#{env}/tmp/pids/gunicorn.pid"
      )
    end

    it do
      expect(chef_run).to create_sudo("formsender-#{env}").with(
        commands: ["/usr/bin/systemctl enable formsender-#{env}-gunicorn",
                   "/usr/bin/systemctl disable formsender-#{env}-gunicorn",
                   "/usr/bin/systemctl stop formsender-#{env}-gunicorn",
                   "/usr/bin/systemctl start formsender-#{env}-gunicorn",
                   "/usr/bin/systemctl status formsender-#{env}-gunicorn",
                   "/usr/bin/systemctl reload formsender-#{env}-gunicorn",
                   "/usr/bin/systemctl restart formsender-#{env}-gunicorn"],
        nopasswd: true
      )
    end

    it do
      port = env == 'staging' ? 8086 : 8085
      expect(chef_run).to create_systemd_service("formsender-#{env}-gunicorn").with(
        description: "formsender #{env} app",
        after: %w(network.target),
        wanted_by: 'multi-user.target',
        type: 'forking',
        user: "formsender-#{env}",
        environment: { 'PATH' => "/home/formsender-#{env}/venv/bin" },
        environment_file: nil,
        working_directory: "/home/formsender-#{env}/formsender",
        pid_file: "/home/formsender-#{env}/tmp/pids/gunicorn.pid",
        exec_start: "/home/formsender-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
          "-D --pid /home/formsender-#{env}/tmp/pids/gunicorn.pid "\
          "--access-logfile /home/formsender-#{env}/logs/access.log "\
          "--error-logfile /home/formsender-#{env}/logs/error.log "\
          '--log-level debug '\
          'formsender.wsgi:application',
        exec_reload: '/bin/kill -USR2 $MAINPID'
      )
    end

    it do
      port = env == 'staging' ? 8084 : 8083
      expect(chef_run).to create_osl_app("iam-#{env}").with(
        description: 'osuosl metrics',
        start_cmd: "/home/iam-#{env}/.rvm/bin/rvm 2.3.0 do bundle exec unicorn -l #{port} -c unicorn.rb -E deployment -D",
        working_directory: "/home/iam-#{env}/iam",
        pid_file: "/home/iam-#{env}/pids/unicorn.pid"
      )
    end

    it do
      port = env == 'staging' ? 8084 : 8083
      expect(chef_run).to create_systemd_service("iam-#{env}").with(
        description: 'osuosl metrics',
        after: %w(network.target),
        wanted_by: 'multi-user.target',
        type: 'forking',
        user: "iam-#{env}",
        environment: {},
        environment_file: nil,
        working_directory: "/home/iam-#{env}/iam",
        pid_file: "/home/iam-#{env}/pids/unicorn.pid",
        exec_start: "/home/iam-#{env}/.rvm/bin/rvm 2.3.0 do bundle exec unicorn -l #{port} -c unicorn.rb -E deployment -D",
        exec_reload: '/bin/kill -USR2 $MAINPID'
      )
    end

    it do
      expect(chef_run).to create_osl_app("timesync-#{env}").with(
        description: 'Time tracker',
        start_cmd: "/usr/local/bin/node /home/timesync-#{env}/timesync/src/app.js",
        environment_file: "/home/timesync-#{env}/timesync.env",
        working_directory: "/home/timesync-#{env}/timesync",
        pid_file: "/home/timesync-#{env}/pids/timesync.pid"
      )
    end

    it do
      expect(chef_run).to create_systemd_service("timesync-#{env}").with(
        description: 'Time tracker',
        after: %w(network.target),
        wanted_by: 'multi-user.target',
        type: 'forking',
        user: "timesync-#{env}",
        environment: {},
        environment_file: "/home/timesync-#{env}/timesync.env",
        working_directory: "/home/timesync-#{env}/timesync",
        pid_file: "/home/timesync-#{env}/pids/timesync.pid",
        exec_start: "/usr/local/bin/node /home/timesync-#{env}/timesync/src/app.js",
        exec_reload: '/bin/kill -USR2 $MAINPID'
      )
    end

    %w(iam timesync).each do |app|
      it do
        expect(chef_run).to create_sudo("#{app}-#{env}").with(
          commands: ["/usr/bin/systemctl enable #{app}-#{env}",
                     "/usr/bin/systemctl disable #{app}-#{env}",
                     "/usr/bin/systemctl stop #{app}-#{env}",
                     "/usr/bin/systemctl start #{app}-#{env}",
                     "/usr/bin/systemctl status #{app}-#{env}",
                     "/usr/bin/systemctl reload #{app}-#{env}",
                     "/usr/bin/systemctl restart #{app}-#{env}"],
          nopasswd: true
        )
      end
    end
  end

  it do
    expect(chef_run).to create_osl_app('replicant-redmine-unicorn').with(
      user: 'replicant',
      description: 'Replicant Redmine',
      start_cmd: '/home/replicant/.rvm/bin/rvm 2.3.0 do bundle exec unicorn -l 8090 -c unicorn.rb -E production -D',
      service_type: 'simple',
      environment: { 'RAILS_ENV' => 'production' },
      working_directory: '/home/replicant/redmine',
      pid_file: '/home/replicant/redmine/pids/unicorn.pid'
    )
  end

  it do
    expect(chef_run).to create_sudo('replicant').with(
      commands: ['/usr/bin/systemctl enable replicant-redmine-unicorn',
                 '/usr/bin/systemctl disable replicant-redmine-unicorn',
                 '/usr/bin/systemctl stop replicant-redmine-unicorn',
                 '/usr/bin/systemctl start replicant-redmine-unicorn',
                 '/usr/bin/systemctl status replicant-redmine-unicorn',
                 '/usr/bin/systemctl reload replicant-redmine-unicorn',
                 '/usr/bin/systemctl restart replicant-redmine-unicorn'],
      nopasswd: true
    )
  end

  it do
    expect(chef_run).to create_systemd_service('replicant-redmine-unicorn').with(
      description: 'Replicant Redmine',
      after: %w(network.target),
      wanted_by: 'multi-user.target',
      type: 'simple',
      user: 'replicant',
      environment: { 'RAILS_ENV' => 'production' },
      environment_file: nil,
      working_directory: '/home/replicant/redmine',
      pid_file: '/home/replicant/redmine/pids/unicorn.pid',
      exec_start: '/home/replicant/.rvm/bin/rvm 2.3.0 do bundle exec unicorn -l 8090 -c unicorn.rb -E production -D',
      exec_reload: '/bin/kill -USR2 $MAINPID'
    )
  end

  %w(formsender-production-gunicorn
     formsender-staging-gunicorn
     iam-production
     iam-staging
     replicant-redmine-unicorn
     timesync-production
     timesync-staging).each do |s|
    it do
      expect(chef_run).to enable_systemd_service(s)
    end
  end
end
