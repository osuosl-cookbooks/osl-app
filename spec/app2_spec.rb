require_relative 'spec_helper'

describe 'osl-app::app2' do
  ALL_PLATFORMS.each do |plat|
    context "#{plat[:platform]} #{plat[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(plat) do |_node, server|
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
            environment: "PATH=/home/formsender-#{env}/venv/bin",
            working_directory: "/home/formsender-#{env}/formsender",
            pid_file: "/home/formsender-#{env}/tmp/pids/gunicorn.pid"
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
          expect(chef_run).to create_osl_app("timesync-#{env}").with(
            description: 'Time tracker',
            start_cmd: "/usr/bin/node /home/timesync-#{env}/timesync/src/app.js",
            environment_file: "/home/timesync-#{env}/timesync.env",
            working_directory: "/home/timesync-#{env}/timesync",
            pid_file: "/home/timesync-#{env}/pids/timesync.pid",
            service_type: 'simple'
          )
        end
      end

      it do
        expect(chef_run).to create_directory('/data/docker/redmine.replicant.us').with(
          recursive: true
        )
      end

      it do
        expect(chef_run).to pull_docker_image('osuosl/redmine-replicant').with(
          tag: '4.2.3-2022.01.14.1907'
        )
      end

      it do
        expect(chef_run).to run_docker_container('redmine.replicant.us').with(
          repo: 'osuosl/redmine-replicant',
          tag: '4.2.3-2022.01.14.1907',
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
