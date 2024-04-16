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
        stub_data_bag_item('osl-app', 'formsender').and_return(
          token: 'faketoken',
          rt_token: 'rt_faketoken',
          recaptcha_secret: 'fakerecaptcha',
          sentry_uri: 'fakeuri'
        )
      end

      it { is_expected.to login_docker_registry('ghcr.io').with(username: 'gh_user', password: 'gh_password') }

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
        expect(chef_run.docker_image('osuosl/redmine-replicant')).to \
          notify('docker_container[redmine.replicant.us]').to(:redeploy)
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

      it { expect(chef_run).to pull_docker_image('ghcr.io/osuosl/formsender').with(tag: 'master') }

      it do
        expect(chef_run).to run_docker_container('formsender').with(
          repo: 'ghcr.io/osuosl/formsender',
          tag: 'master',
          port: '8085:5000',
          restart_policy: 'always',
          env: [
            'TOKEN=faketoken',
            'RT_TOKEN=rt_faketoken',
            'RECAPTCHA_SECRET=fakerecaptcha',
            'SENTRY_URI=fakeuri',
          ],
          sensitive: true
        )
      end
    end
  end
end
