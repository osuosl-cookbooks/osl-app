require_relative 'spec_helper'

describe 'osl-app::app1' do
  ALL_PLATFORMS.each do |plat|
    context "#{plat[:platform]} #{plat[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(plat) do |_node, server|
        end.converge('sudo', described_recipe)
      end
      include_context 'common_stubs'

      before do
        stub_data_bag_item('osl-app', 'openid').and_return(
          secret_key_base: '7eef5c70ecb083192f46e601144f9d77c9b66061b634963a507'\
            '0fb086ae78bc9353af2c6311edb168abbb9d0bd428f800a0b1713534cf4ad239e8d'\
            '07fdd16c34',
          braintree_access_token: 'access_token$production$mnlc24xq7uGUqKczYhg5PpNGiVOkss',
          recaptcha_site_key: '4infjrcfj9e4mcerefa89cm8h4rvnmv9e4cu8anh',
          recaptcha_secret_key: 'hxia4nvuirax4hfx8cem450tuw5uwvn74xgq783y'
        )
      end

      it do
        is_expected.to create_osl_app('openid-staging-unicorn').with(
          description: 'openid staging app',
          service_after: 'network.target',
          wanted_by: 'multi-user.target',
          service_type: 'forking',
          user: 'openid-staging',
          environment: 'RAILS_ENV=staging',
          working_directory: '/home/openid-staging/current',
          pid_file: '/home/openid-staging/current/tmp/pids/unicorn.pid',
          start_cmd: '/home/openid-staging/.rvm/bin/rvm 2.5.3 do bundle exec unicorn -c /home/openid-staging/current/config/unicorn/staging.rb -E deployment -D',
          reload_cmd: '/bin/kill -USR2 $MAINPID'
        )
      end

      it do
        is_expected.to create_osl_app('openid-staging-delayed-job').with(
          description: 'openid delayed job',
          service_after: 'network.target openid-staging-unicorn.service',
          service_wants: 'openid-staging-unicorn.service',
          wanted_by: 'multi-user.target',
          service_type: 'forking',
          user: 'openid-staging',
          environment: 'RAILS_ENV=staging',
          working_directory: '/home/openid-staging/current',
          start_cmd: '/home/openid-staging/.rvm/bin/rvm 2.5.3 do bundle exec bin/delayed_job -n 2 start',
          reload_cmd: '/home/openid-staging/.rvm/bin/rvm 2.5.3 do bundle exec bin/delayed_job -n 2 restart'
        )
      end
      it do
        is_expected.to create_osl_app('openid-production-unicorn').with(
          description: 'openid production app',
          service_after: 'network.target',
          wanted_by: 'multi-user.target',
          service_type: 'forking',
          user: 'openid-production',
          working_directory: '/home/openid-production/current',
          pid_file: '/home/openid-production/current/tmp/pids/unicorn.pid',
          start_cmd: '/home/openid-production/.rvm/bin/rvm 2.5.3 do bundle exec unicorn -c /home/openid-production/current/config/unicorn/production.rb -E deployment -D',
          reload_cmd: '/bin/kill -USR2 $MAINPID'
        )
      end

      it do
        is_expected.to create_osl_app('openid-production-delayed-job').with(
          description: 'openid delayed job',
          service_after: 'network.target openid-production-unicorn.service',
          service_wants: 'openid-production-unicorn.service',
          wanted_by: 'multi-user.target',
          service_type: 'forking',
          user: 'openid-production',
          environment: 'RAILS_ENV=production',
          working_directory: '/home/openid-production/current',
          start_cmd: '/home/openid-production/.rvm/bin/rvm 2.5.3 do bundle exec bin/delayed_job -n 2 start',
          reload_cmd: '/home/openid-production/.rvm/bin/rvm 2.5.3 do bundle exec bin/delayed_job -n 2 restart'
        )
      end

      %w(production staging).each do |type|
        it "should create LogRotate service for OpenID-#{type}" do
          expect(chef_run).to enable_logrotate_app("OpenID-#{type}").with(
            path: "/home/openid-#{type}/shared/log/*.log",
            frequency: 'daily',
            postrotate: "/bin/kill -USR1 $(cat /home/openid-#{type}/current/tmp/pids/unicorn.pid)",
            su: "openid-#{type} openid-#{type}",
            rotate: 30
          )
        end
      end
    end
  end
end
