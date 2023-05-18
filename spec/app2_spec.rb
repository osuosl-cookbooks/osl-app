require_relative 'spec_helper'

describe 'osl-app::app2' do
  ALL_PLATFORMS.each do |plat|
    context "#{plat[:platform]} #{plat[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(plat) do |_node, server|
        end.converge('sudo', described_recipe)
      end

      include_context 'common_stubs'

      %w(staging production).each do |env|
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
    end
  end
end
