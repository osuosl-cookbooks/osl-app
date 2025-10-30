require_relative 'spec_helper'
require_relative '../libraries/helpers'

describe 'osl-app::app3' do
  ALL_PLATFORMS.each do |plat|
    context "#{plat[:platform]} #{plat[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(plat) do |_node, server|
        end.converge(described_recipe)
      end

      include_context 'common_stubs'

      before do
        allow_any_instance_of(OslApp::Cookbook::Helpers).to receive(:user_uid).with('invasives-staging').and_return(1000)
        stub_data_bag_item('osl-app', 'streamwebs').and_return(
          production: {
            fqdn: 'streamwebs.org',
            secret_key: 'NrXzeh4ccgBi6lXC',
            recaptcha_public_key: 'recaptcha_public_key',
            recaptcha_private_key: 'recaptcha_private_key',
            google_maps_api_key: 'google_maps_api_key',
            google_maps_map_type: 'google.maps.MapTypeId.TERRAIN',
            debug: 'False',
            default_from_email: 'testing@streamwebs.org',
            db_name: 'streamwebs-production',
            db_user: 'streamwebs-production',
            db_password: 'production_password',
            db_host: 'postgres_host',
            sentry_dsn: 'sentry_dsn',
            sentry_public_dsn: 'sentry_public_dsn',
          },
          staging: {
            fqdn: 'streamwebs-staging.osuosl.org',
            secret_key: 'NrXzeh4ccgBi6lXC',
            recaptcha_public_key: 'recaptcha_public_key',
            recaptcha_private_key: 'recaptcha_private_key',
            google_maps_api_key: 'google_maps_api_key',
            google_maps_map_type: 'google.maps.MapTypeId.TERRAIN',
            debug: 'False',
            default_from_email: 'testing@streamwebs.org',
            db_name: 'streamwebs-staging',
            db_user: 'streamwebs-staging',
            db_password: 'staging_password',
            db_host: 'postgres_host',
            sentry_dsn: 'sentry_dsn',
            sentry_public_dsn: 'sentry_public_dsn',
          }
        )
        stub_data_bag_item('mulgara_redmine', 'mysql_creds').and_return(
          db_db: 'fakedb',
          db_hostname: 'testdb.osuosl.bak',
          db_passwd: 'fakepw',
          db_user: 'fakeuser'
        )
        %w(osl snowdrift).each do |type|
          stub_data_bag_item('etherpad', type).and_return(
            db_db: 'fakedb',
            db_hostname: 'testdb.osuosl.bak',
            db_passwd: 'fakepw',
            db_user: 'fakeuser',
            admin_passwd: 'fakeadmin'
          )
        end
        stub_data_bag_item('osl-app', 'invasives').and_return(
          "staging": {
            db_name: 'invasives-staging',
            db_user: 'invasives-staging',
            db_pass: 'invasives-staging',
            db_host: '127.0.0.1',
            google_api_key: 'google_api_key:',
            secret_key: 'secret_key:',
          }
        )
      end

      it { is_expected.to login_docker_registry('ghcr.io').with(username: 'gh_user', password: 'gh_password') }

      it do
        is_expected.to pull_docker_image('streamwebs-develop').with(repo: 'ghcr.io/osuosl/streamwebs', tag: 'develop')
      end

      it do
        is_expected.to pull_docker_image('streamwebs-master').with(repo: 'ghcr.io/osuosl/streamwebs', tag: 'master')
      end

      it do
        expect(chef_run.docker_image('streamwebs-develop')).to \
          notify('docker_container[streamwebs-staging.osuosl.org]').to(:redeploy)
      end

      it do
        expect(chef_run.docker_image('streamwebs-master')).to \
          notify('docker_container[streamwebs.org]').to(:redeploy)
      end

      it do
        is_expected.to create_template('/home/streamwebs-staging/settings.py').with(
          variables: {
            secrets: {
              'db_host' => 'postgres_host',
              'db_name' => 'streamwebs-staging',
              'db_password' => 'staging_password',
              'db_user' => 'streamwebs-staging',
              'debug' => 'False',
              'default_from_email' => 'testing@streamwebs.org',
              'fqdn' => 'streamwebs-staging.osuosl.org',
              'google_maps_api_key' => 'google_maps_api_key',
              'google_maps_map_type' => 'google.maps.MapTypeId.TERRAIN',
              'recaptcha_private_key' => 'recaptcha_private_key',
              'recaptcha_public_key' => 'recaptcha_public_key',
              'secret_key' => 'NrXzeh4ccgBi6lXC',
              'sentry_dsn' => 'sentry_dsn',
              'sentry_public_dsn' => 'sentry_public_dsn',
            },
          },
          sensitive: true
        )
      end

      it do
        is_expected.to create_template('/home/streamwebs-production/settings.py').with(
          variables: {
            secrets: {
              'db_host' => 'postgres_host',
              'db_name' => 'streamwebs-production',
              'db_password' => 'production_password',
              'db_user' => 'streamwebs-production',
              'debug' => 'False',
              'default_from_email' => 'testing@streamwebs.org',
              'fqdn' => 'streamwebs.org',
              'google_maps_api_key' => 'google_maps_api_key',
              'google_maps_map_type' => 'google.maps.MapTypeId.TERRAIN',
              'recaptcha_private_key' => 'recaptcha_private_key',
              'recaptcha_public_key' => 'recaptcha_public_key',
              'secret_key' => 'NrXzeh4ccgBi6lXC',
              'sentry_dsn' => 'sentry_dsn',
              'sentry_public_dsn' => 'sentry_public_dsn',
            },
          },
          sensitive: true
        )
      end

      it do
        expect(chef_run.template('/home/streamwebs-staging/settings.py')).to \
          notify('docker_container[streamwebs-staging.osuosl.org]').to(:redeploy)
      end

      it do
        expect(chef_run.template('/home/streamwebs-production/settings.py')).to \
          notify('docker_container[streamwebs.org]').to(:redeploy)
      end

      it do
        is_expected.to run_docker_container('streamwebs-staging.osuosl.org').with(
          repo: 'ghcr.io/osuosl/streamwebs',
          tag: 'develop',
          port: '8081:8000',
          restart_policy: 'always',
          command: ['/usr/src/app/entrypoint.sh'],
          links: nil,
          volumes_binds: [
            '/home/streamwebs-staging/media:/usr/src/app/media',
            '/home/streamwebs-staging/settings.py:/usr/src/app/streamwebs_frontend/streamwebs_frontend/settings.py',
          ]
        )
      end

      it do
        is_expected.to run_docker_container('streamwebs.org').with(
          repo: 'ghcr.io/osuosl/streamwebs',
          tag: 'master',
          port: '8080:8000',
          restart_policy: 'always',
          command: ['/usr/src/app/entrypoint.sh'],
          links: nil,
          volumes_binds: [
            '/home/streamwebs-production/media:/usr/src/app/media',
            '/home/streamwebs-production/settings.py:/usr/src/app/streamwebs_frontend/streamwebs_frontend/settings.py',
          ]
        )
      end

      it do
        is_expected.to create_nginx_app('app3.osuosl.org').with(
          template: 'app-nginx.erb',
          cookbook: 'osl-app'
        )
      end

      it do
        is_expected.to create_directory('/data/docker/code.mulgara.org').with(
          recursive: true
        )
      end

      it do
        is_expected.to pull_docker_image('library/redmine').with(
          tag: '5.1.4'
        )
      end

      it do
        expect(chef_run.docker_image('library/redmine')).to \
          notify('docker_container[code.mulgara.org]').to(:redeploy)
      end

      it do
        is_expected.to run_docker_container('code.mulgara.org').with(
          repo: 'redmine',
          tag: '5.1.4',
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

      it do
        is_expected.to pull_docker_image('elestio/etherpad').with(
          tag: 'latest'
        )
      end

      it do
        expect(chef_run.docker_image('elestio/etherpad')).to \
          notify('docker_container[etherpad-lite.osuosl.org]').to(:redeploy)
      end

      it do
        expect(chef_run.docker_image('ghcr.io/osuosl/etherpad-snowdrift')).to \
          notify('docker_container[etherpad-snowdrift.osuosl.org]').to(:redeploy)
      end

      it do
        is_expected.to run_docker_container('etherpad-lite.osuosl.org').with(
          repo: 'elestio/etherpad',
          tag: 'latest',
          port: '8085:9001',
          restart_policy: 'always',
          user: 'etherpad',
          env: [
            'DB_TYPE=mysql',
            'DB_CHARSET=utf8mb4',
            'DB_COLLECTION=utf8mb4_unicode_ci',
            'DB_HOST=testdb.osuosl.bak',
            'DB_NAME=fakedb',
            'DB_USER=fakeuser',
            'DB_PASS=fakepw',
            'ADMIN_PASSWORD=fakeadmin',
          ]
        )
      end

      it do
        is_expected.to run_docker_container('etherpad-snowdrift.osuosl.org').with(
          repo: 'ghcr.io/osuosl/etherpad-snowdrift',
          tag: 'latest',
          port: '8086:9001',
          restart_policy: 'always',
          user: 'etherpad',
          env: [
            'DB_TYPE=mysql',
            'DB_CHARSET=utf8mb4',
            'DB_COLLECTION=utf8mb4_unicode_ci',
            'DB_HOST=testdb.osuosl.bak',
            'DB_NAME=fakedb',
            'DB_USER=fakeuser',
            'DB_PASS=fakepw',
            'ADMIN_PASSWORD=fakeadmin',
          ]
        )
      end

      it do
        is_expected.to sync_git('/home/invasives-staging/oregoninvasiveshotline').with(
          repository: 'https://github.com/osu-cass/oregoninvasiveshotline.git',
          revision: 'develop'
        )
      end

      it do
        template = chef_run.template('/home/invasives-staging/oregoninvasiveshotline/.env')
        is_expected.to create_template('/home/invasives-staging/oregoninvasiveshotline/.env').with(
          source: 'oregoninvasiveshotline-env.erb',
          mode: '0400',
          sensitive: true
        )
        expect(template.variables[:env]).to eq('staging')
        expect(template.variables[:image]).to eq('develop')
        expect(template.variables[:app_port]).to eq('8087')
        expect(template.variables[:allowed_hosts]).to eq(%w(staging.oregoninvasiveshotline.org))
        expect(template.variables[:db_name]).to eq('invasives-staging')
        expect(template.variables[:db_user]).to eq('invasives-staging')
        expect(template.variables[:db_host]).to eq('127.0.0.1')
        expect(template.variables[:sentry_dsn]).to eq(nil)
        expect(template.variables[:sentry_sample_rate]).to eq('0.5')
        expect(template.variables[:user_id].call(chef_run.node)).to eq(1000)
        expect(template.variables[:volume_path]).to eq('/home/invasives-staging/volume')
      end

      it do
        expect(chef_run.template('/home/invasives-staging/oregoninvasiveshotline/.env')).to \
          notify('osl_dockercompose[invasives-staging]').to(:rebuild)
      end

      it do
        expect(chef_run.template('/home/invasives-staging/oregoninvasiveshotline/.env')).to \
          notify('osl_dockercompose[invasives-staging]').to(:restart)
      end

      it do
        expect(chef_run.git('/home/invasives-staging/oregoninvasiveshotline')).to \
          notify('osl_dockercompose[invasives-staging]').to(:rebuild)
      end

      it do
        expect(chef_run.git('/home/invasives-staging/oregoninvasiveshotline')).to \
          notify('osl_dockercompose[invasives-staging]').to(:restart)
      end

      it do
        is_expected.to create_directory('/home/invasives-staging/oregoninvasiveshotline/docker/secrets')
      end

      it do
        is_expected.to create_directory('/home/invasives-staging/volume/media').with(
          owner: 1000,
          group: 1000,
          recursive: true
        )
      end

      it do
        is_expected.to create_directory('/home/invasives-staging/volume/static').with(
          owner: 1000,
          group: 1000,
          recursive: true
        )
      end

      it do
        is_expected.to create_file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/secret_key.txt').with(
          owner: 1000,
          group: 1000,
          mode: '0400',
          content: 'secret_key:',
          sensitive: true
        )
      end

      it do
        expect(chef_run.file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/secret_key.txt')).to \
          notify('osl_dockercompose[invasives-staging]').to(:rebuild)
      end

      it do
        expect(chef_run.file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/secret_key.txt')).to \
          notify('osl_dockercompose[invasives-staging]').to(:restart)
      end

      it do
        is_expected.to create_file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/db_password.txt').with(
          owner: 1000,
          group: 1000,
          mode: '0400',
          content: 'invasives-staging',
          sensitive: true
        )
      end

      it do
        expect(chef_run.file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/db_password.txt')).to \
          notify('osl_dockercompose[invasives-staging]').to(:rebuild)
      end

      it do
        expect(chef_run.file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/db_password.txt')).to \
          notify('osl_dockercompose[invasives-staging]').to(:restart)
      end

      it do
        is_expected.to create_file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/google_api_key.txt').with(
          owner: 1000,
          group: 1000,
          mode: '0400',
          content: 'google_api_key:',
          sensitive: true
        )
      end

      it do
        expect(chef_run.file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/google_api_key.txt')).to \
          notify('osl_dockercompose[invasives-staging]').to(:rebuild)
      end

      it do
        expect(chef_run.file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/google_api_key.txt')).to \
          notify('osl_dockercompose[invasives-staging]').to(:restart)
      end

      it do
        is_expected.to pull_docker_image('ghcr.io/osu-cass/oregoninvasiveshotline').with(
          tag: 'develop'
        )
      end

      it do
        expect(chef_run.docker_image('ghcr.io/osu-cass/oregoninvasiveshotline')).to \
          notify('osl_dockercompose[invasives-staging]').to(:rebuild)
      end

      it do
        expect(chef_run.docker_image('ghcr.io/osu-cass/oregoninvasiveshotline')).to \
          notify('osl_dockercompose[invasives-staging]').to(:restart)
      end

      it do
        is_expected.to up_osl_dockercompose('invasives-staging').with(
          directory: '/home/invasives-staging/oregoninvasiveshotline',
          config_files: %w(docker-compose.deploy.yml)
        )
      end
    end
  end
end
