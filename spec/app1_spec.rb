require_relative 'spec_helper'

describe 'osl-app::app1' do
  ALL_PLATFORMS.each do |plat|
    context "#{plat[:platform]} #{plat[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(plat) do |_node, server|
        end.converge(described_recipe)
      end
      include_context 'common_stubs'

      before do
        stub_data_bag_item('osl-app', 'openid').and_return(
          db_password: 'db_password',
          db_host: 'db_host',
          'staging' => {
            'secret_key_base' => 'staging_secret_key_base',
            'braintree_access_token' => 'staging_braintree_access_token',
            'recaptcha_site_key' => 'staging_recaptcha_site_key',
            'recaptcha_secret_key' => 'staging_recaptcha_secret_key',
            'hello_client_id' => 'staging_hello_client_id',
            'hello_client_secret' => 'staging_hello_client_secret',
          },
          'production' => {
            'secret_key_base' => 'production_secret_key_base',
            'braintree_access_token' => 'production_braintree_access_token',
            'recaptcha_site_key' => 'production_recaptcha_site_key',
            'recaptcha_secret_key' => 'production_recaptcha_secret_key',
            'hello_client_id' => 'production_hello_client_id',
            'hello_client_secret' => 'production_hello_client_secret',
          }
        )
        stub_data_bag_item('osl-app', 'registry').and_return(
          access_key: 'access_key',
          secret_key: 'secret_key',
          docker_username: 'docker_username',
          docker_password: 'docker_password',
          htpasswds: [
            {
              username: 'guest',
              password: 'guest',
            },
            {
              username: 'admin',
              password: 'admin',
              type: 'plaintext',
            },
          ]
        )
      end

      it { is_expected.to login_docker_registry('ghcr.io').with(username: 'gh_user', password: 'gh_password') }

      it do
        is_expected.to pull_docker_image('oidf-members-develop').with(
          repo: 'ghcr.io/openid-foundation/oidf-members',
          tag: 'develop'
        )
      end

      it do
        is_expected.to pull_docker_image('oidf-members-master').with(
          repo: 'ghcr.io/openid-foundation/oidf-members',
          tag: 'master'
        )
      end

      it do
        is_expected.to pull_docker_image('registry').with(
          tag: '2'
        )
      end

      it do
        is_expected.to pull_docker_image('valkey').with(
          repo: 'valkey/valkey',
          tag: '8-alpine'
        )
      end

      it do
        expect(chef_run.docker_image('valkey')).to \
          notify('docker_container[registry-valkey]').to(:redeploy)
      end

      it do
        expect(chef_run.docker_image('oidf-members-develop')).to \
          notify('docker_container[openid-staging-website]').to(:redeploy)
      end

      it do
        expect(chef_run.docker_image('oidf-members-develop')).to \
          notify('docker_container[openid-staging-delayed-job]').to(:redeploy)
      end

      it do
        expect(chef_run.docker_image('oidf-members-master')).to \
          notify('docker_container[openid-production-website]').to(:redeploy)
      end

      it do
        expect(chef_run.docker_image('oidf-members-master')).to \
          notify('docker_container[openid-production-delayed-job]').to(:redeploy)
      end

      it do
        expect(chef_run.docker_image('registry')).to \
          notify('docker_container[registry.osuosl.org]').to(:redeploy)
      end

      it { is_expected.to create_directory('/usr/local/etc/registry.osuosl.org').with(recursive: true) }

      it do
        is_expected.to add_htpasswd('guest in /usr/local/etc/registry.osuosl.org/htpasswd').with(
          file: '/usr/local/etc/registry.osuosl.org/htpasswd',
          user: 'guest',
          password: 'guest'
        )
      end

      it do
        is_expected.to add_htpasswd('admin in /usr/local/etc/registry.osuosl.org/htpasswd').with(
          file: '/usr/local/etc/registry.osuosl.org/htpasswd',
          user: 'admin',
          password: 'admin',
          type: 'plaintext'
        )
      end

      it do
        is_expected.to run_docker_container('openid-staging-website').with(
          repo: 'ghcr.io/openid-foundation/oidf-members',
          tag: 'develop',
          port: '8080:8080',
          restart_policy: 'always',
          init: true,
          command: ['/usr/src/app/entrypoint.sh'],
          env: [
            'RAILS_ENV=staging',
            'DB_PASSWORD=db_password',
            'DB_HOST=db_host',
            'BRAINTREE_ENV=sandbox',
            'SECRET_KEY_BASE=staging_secret_key_base',
            'BRAINTREE_ACCESS_TOKEN=staging_braintree_access_token',
            'RECAPTCHA_SITE_KEY=staging_recaptcha_site_key',
            'RECAPTCHA_SECRET_KEY=staging_recaptcha_secret_key',
            'HELLO_ISSUER=https://issuer.hello.coop',
            'HELLO_CLIENT_ID=staging_hello_client_id',
            'HELLO_CLIENT_SECRET=staging_hello_client_secret',
          ],
          sensitive: true
        )
      end

      it do
        is_expected.to run_docker_container('openid-production-website').with(
          repo: 'ghcr.io/openid-foundation/oidf-members',
          tag: 'master',
          port: '8081:8080',
          restart_policy: 'always',
          init: true,
          command: ['/usr/src/app/entrypoint.sh'],
          env: [
            'RAILS_ENV=production',
            'DB_PASSWORD=db_password',
            'DB_HOST=db_host',
            'SECRET_KEY_BASE=production_secret_key_base',
            'BRAINTREE_ENV=production',
            'BRAINTREE_ACCESS_TOKEN=production_braintree_access_token',
            'RECAPTCHA_SITE_KEY=production_recaptcha_site_key',
            'RECAPTCHA_SECRET_KEY=production_recaptcha_secret_key',
            'HELLO_ISSUER=https://issuer.hello.coop',
            'HELLO_CLIENT_ID=production_hello_client_id',
            'HELLO_CLIENT_SECRET=production_hello_client_secret',
          ],
          sensitive: true
        )
      end

      it do
        is_expected.to run_docker_container('openid-staging-delayed-job').with(
          repo: 'ghcr.io/openid-foundation/oidf-members',
          tag: 'develop',
          restart_policy: 'always',
          command: ['/usr/src/app/entrypoint-delayed-job.sh'],
          env: [
            'RAILS_ENV=staging',
            'DB_PASSWORD=db_password',
            'DB_HOST=db_host',
            'SECRET_KEY_BASE=staging_secret_key_base',
          ],
          sensitive: true
        )
      end

      it do
        is_expected.to run_docker_container('openid-production-delayed-job').with(
          repo: 'ghcr.io/openid-foundation/oidf-members',
          tag: 'master',
          restart_policy: 'always',
          command: ['/usr/src/app/entrypoint-delayed-job.sh'],
          env: [
            'RAILS_ENV=production',
            'DB_PASSWORD=db_password',
            'DB_HOST=db_host',
          ],
          sensitive: true
        )
      end

      it do
        is_expected.to run_docker_container('registry-valkey').with(
          repo: 'valkey/valkey',
          tag: '8-alpine',
          restart_policy: 'always',
          command: ['valkey-server', '--appendonly', 'yes', '--maxmemory', '256mb', '--maxmemory-policy', 'allkeys-lru']
        )
      end

      it do
        is_expected.to run_docker_container('registry.osuosl.org').with(
          tag: '2',
          port: '8082:5000',
          restart_policy: 'always',
          links: ['registry-valkey:redis'],
          env: [
            'REGISTRY_STORAGE=s3',
            'REGISTRY_STORAGE_S3_ACCESSKEY=access_key',
            'REGISTRY_STORAGE_S3_SECRETKEY=secret_key',
            'REGISTRY_STORAGE_S3_REGION=us-east-1',
            'REGISTRY_STORAGE_S3_BUCKET=osuosl-registry',
            'REGISTRY_STORAGE_S3_REGIONENDPOINT=s3.osuosl.org',
            'REGISTRY_STORAGE_S3_CHUNKSIZE=104857600',
            'REGISTRY_STORAGE_S3_MULTIPARTCOPYCHUNKSIZE=104857600',
            'REGISTRY_STORAGE_S3_MULTIPARTCOPYMAXCONCURRENCY=32',
            'REGISTRY_STORAGE_CACHE_BLOBDESCRIPTOR=redis',
            'REGISTRY_REDIS_ADDR=redis:6379',
            'REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io',
            'REGISTRY_PROXY_USERNAME=docker_username',
            'REGISTRY_PROXY_PASSWORD=docker_password',
            'REGISTRY_HTTP_DRAINTIMEOUT=60s',
          ],
          volumes_binds: ['/usr/local/etc/registry.osuosl.org:/auth'],
          sensitive: true
        )
      end

      it { is_expected.to create_osl_app_docker_wrapper('openid-staging-website').with(user: 'openid-staging') }
      it { is_expected.to create_osl_app_docker_wrapper('openid-staging-delayed-job').with(user: 'openid-staging') }
      it { is_expected.to create_osl_app_docker_wrapper('openid-production-website').with(user: 'openid-production') }
      it { is_expected.to create_osl_app_docker_wrapper('openid-production-delayed-job').with(user: 'openid-production') }
    end
  end
end
