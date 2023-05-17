require_relative 'spec_helper'

describe 'osl-app::app3' do
  ALL_PLATFORMS.each do |plat|
    context "#{plat[:platform]} #{plat[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(plat) do |_node, server|
        end.converge('sudo', described_recipe)
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
            environment: "PATH=/home/streamwebs-#{env}/venv/bin",
            working_directory: "/home/streamwebs-#{env}/streamwebs/streamwebs_frontend",
            pid_file: "/home/streamwebs-#{env}/tmp/pids/gunicorn.pid"
          )
        end

        it do
          port = env == 'staging' ? 8082 : 8083
          expect(chef_run).to create_osl_app("timesync-web-#{env}").with(
            description: "timesync-web #{env} app",
            start_cmd: "/home/timesync-web-#{env}/venv/bin/gunicorn -b 0.0.0.0:#{port} "\
              "-D --pid /home/timesync-web-#{env}/tmp/pids/gunicorn.pid wsgi:app",
            environment: "PATH=/home/timesync-web-#{env}/venv/bin",
            working_directory: "/home/timesync-web-#{env}/timesync-web",
            pid_file: "/home/timesync-web-#{env}/tmp/pids/gunicorn.pid"
          )
        end
      end

      it do
        expect(chef_run).to create_nginx_app('app3.osuosl.org').with(
          template: 'app-nginx.erb',
          cookbook: 'osl-app'
        )
      end
    end
  end
end
