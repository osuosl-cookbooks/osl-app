require_relative 'spec_helper'

describe 'osl-app::app2' do
  ALL_PLATFORMS.each do |plat|
    context "#{plat[:platform]} #{plat[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(plat.dup.merge(step_into: %w(osl_app))) do |_node, server|
        end.converge('sudo', described_recipe)
      end

      include_context 'common_stubs'

      before do
        stub_data_bag_item('replicant_redmine', 'mysql_creds').and_return(
          db_db: 'fakedb',
          db_hostname: 'testdb.osuosl.bak',
          db_passwd: 'fakepw',
          db_user: 'fakeuser'
        )
      end

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
            unit_description: "formsender #{env} app",
            unit_after: %w(network.target),
            install_wanted_by: 'multi-user.target',
            service_type: 'forking',
            service_user: "formsender-#{env}",
            service_environment: { 'PATH' => "/home/formsender-#{env}/venv/bin" },
            service_environment_file: nil,
            service_working_directory: "/home/formsender-#{env}/formsender",
            service_pid_file: "/home/formsender-#{env}/tmp/pids/gunicorn.pid",
            service_exec_start: "/home/formsender-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
              "-D --pid /home/formsender-#{env}/tmp/pids/gunicorn.pid "\
              "--access-logfile /home/formsender-#{env}/logs/access.log "\
              "--error-logfile /home/formsender-#{env}/logs/error.log "\
              '--log-level debug '\
              'formsender.wsgi:application',
            service_exec_reload: '/bin/kill -USR2 $MAINPID',
            verify: false
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
            unit_description: 'osuosl metrics',
            unit_after: %w(network.target),
            install_wanted_by: 'multi-user.target',
            service_type: 'forking',
            service_user: "iam-#{env}",
            service_environment: {},
            service_environment_file: nil,
            service_working_directory: "/home/iam-#{env}/iam",
            service_pid_file: "/home/iam-#{env}/pids/unicorn.pid",
            service_exec_start: "/home/iam-#{env}/.rvm/bin/rvm 2.3.0 do bundle exec unicorn -l #{port} -c unicorn.rb -E deployment -D",
            service_exec_reload: '/bin/kill -USR2 $MAINPID',
            verify: false
          )
        end

        it do
          expect(chef_run).to create_osl_app("timesync-#{env}").with(
            description: 'Time tracker',
            start_cmd: "/usr/local/bin/node /home/timesync-#{env}/timesync/src/app.js",
            environment_file: "/home/timesync-#{env}/timesync.env",
            working_directory: "/home/timesync-#{env}/timesync",
            pid_file: "/home/timesync-#{env}/pids/timesync.pid",
            service_type: 'simple'
          )
        end

        it do
          expect(chef_run).to create_systemd_service("timesync-#{env}").with(
            unit_description: 'Time tracker',
            unit_after: %w(network.target),
            install_wanted_by: 'multi-user.target',
            service_type: 'simple',
            service_user: "timesync-#{env}",
            service_environment: {},
            service_environment_file: "/home/timesync-#{env}/timesync.env",
            service_working_directory: "/home/timesync-#{env}/timesync",
            service_pid_file: "/home/timesync-#{env}/pids/timesync.pid",
            service_exec_start: "/usr/local/bin/node /home/timesync-#{env}/timesync/src/app.js",
            service_exec_reload: '/bin/kill -USR2 $MAINPID',
            verify: false
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
        expect(chef_run).to stop_osl_app('replicant-redmine-unicorn').with(
          user: 'replicant',
          description: 'Replicant Redmine',
          start_cmd: '/home/replicant/.rvm/bin/rvm 2.6.3 do bundle exec unicorn -l 8090 -c unicorn.rb -E production -D',
          service_type: 'simple',
          environment: { 'RAILS_ENV' => 'production' },
          working_directory: '/home/replicant/redmine',
          pid_file: '/home/replicant/redmine/pids/unicorn.pid'
        )
      end

      it do
        expect(chef_run).to disable_osl_app('replicant-redmine-unicorn')
      end

      it do
        expect(chef_run).to stop_systemd_service('replicant-redmine-unicorn')
      end

      it do
        expect(chef_run).to disable_systemd_service('replicant-redmine-unicorn')
      end

      %w(formsender-production-gunicorn
        formsender-staging-gunicorn
        iam-production
        iam-staging
        timesync-production
        timesync-staging).each do |s|
        it do
          expect(chef_run).to enable_systemd_service(s)
        end
      end

      it do
        expect(chef_run).to create_directory('/data/docker/redmine.replicant.us').with(
          recursive: true
        )
      end

      it do
        expect(chef_run).to pull_docker_image('osuosl/redmine-replicant').with(
          tag: '4.1.1'
        )
      end

      it do
        expect(chef_run).to run_docker_container('redmine.replicant.us').with(
          repo: 'osuosl/redmine-replicant',
          tag: '4.1.1',
          port: '8090:3000',
          restart_policy: 'always',
          # This needs to be volumes_binds, since the volumes property gets coerced into a volumes_binds property if it's
          # passed an entry that specifies a bind mount
          # https://github.com/chef-cookbooks/docker/blob/v4.9.3/libraries/docker_container.rb#L210
          volumes_binds: ['/data/docker/redmine.replicant.us:/usr/src/redmine/files'],
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
  end
end
