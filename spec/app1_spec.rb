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
          recaptcha_secret_key: 'hxia4nvuirax4hfx8cem450tuw5uwvn74xgq783y',
          db_password: 'db_password',
          db_host: 'db_host'
        )
      end

      it { is_expected.to create_git_credentials('app1-root').with(owner: 'root', secrets_item: 'app1') }

      it do
        is_expected.to sync_git('/var/lib/openid-staging').with(
          user: 'root',
          group: 'root',
          repository: 'https://github.com/openid-foundation/oidf-members.git',
          revision: 'develop',
          ignore_failure: true
        )
      end

      it do
        expect(chef_run.git('/var/lib/openid-staging')).to \
          notify('docker_image[openid-staging]').to(:build).immediately
      end

      it do
        expect(chef_run.git('/var/lib/openid-staging')).to \
          notify('docker_container[openid-staging-website]').to(:redeploy)
      end

      it do
        expect(chef_run.git('/var/lib/openid-staging')).to \
          notify('docker_container[openid-staging-delayed-job]').to(:redeploy)
      end

      it do
        is_expected.to nothing_docker_image('openid-staging').with(tag: 'staging', source: '/var/lib/openid-staging')
      end

      it do
        is_expected.to run_docker_container('openid-staging-website').with(
          repo: 'openid-staging',
          tag: 'staging',
          port: '8080:8080',
          command: ['sh', '-c', 'bundle exec rake db:migrate && bundle exec unicorn -c config/unicorn.rb'],
          env: [
            'RAILS_ENV=staging',
            'DB_PASSWORD=db_password',
            'DB_HOST=db_host',
          ],
          sensitive: true
        )
      end

      it do
        is_expected.to run_docker_container('openid-staging-delayed-job').with(
          repo: 'openid-staging',
          tag: 'staging',
          restart_policy: 'always',
          command: ['bundle', 'exec', 'bin/delayed_job', '-n', '2', 'run'],
          env: [
            'RAILS_ENV=staging',
            'DB_PASSWORD=db_password',
            'DB_HOST=db_host',
          ],
          sensitive: true
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
          start_cmd: '/home/openid-production/.rvm/bin/rvm 3.1.4 do bundle exec unicorn -c /home/openid-production/current/config/unicorn/production.rb -E deployment -D',
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
          start_cmd: '/home/openid-production/.rvm/bin/rvm 3.1.4 do bundle exec bin/delayed_job -n 2 start',
          reload_cmd: '/home/openid-production/.rvm/bin/rvm 3.1.4 do bundle exec bin/delayed_job -n 2 restart'
        )
      end
    end
  end
end
