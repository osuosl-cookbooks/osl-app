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
          secret_key_base: '7eef5c70ecb083192f46e601144f9d77c9b66061b634963a507'\
            '0fb086ae78bc9353af2c6311edb168abbb9d0bd428f800a0b1713534cf4ad239e8d'\
            '07fdd16c34',
          braintree_access_token: 'access_token$production$mnlc24xq7uGUqKczYhg5PpNGiVOkss',
          recaptcha_site_key: '4infjrcfj9e4mcerefa89cm8h4rvnmv9e4cu8anh',
          recaptcha_secret_key: 'hxia4nvuirax4hfx8cem450tuw5uwvn74xgq783y',
          db_password: 'db_password',
          db_host: 'db_host'
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
            'SECRET_KEY_BASE=7eef5c70ecb083192f46e601144f9d77c9b66061b634963a5070fb086ae78bc9353af2c6311edb168abbb9d0bd428f800a0b1713534cf4ad239e8d07fdd16c34',
            'BRAINTREE_ACCESS_TOKEN=access_token$production$mnlc24xq7uGUqKczYhg5PpNGiVOkss',
            'RECAPTCHA_SITE_KEY=4infjrcfj9e4mcerefa89cm8h4rvnmv9e4cu8anh',
            'RECAPTCHA_SECRET_KEY=hxia4nvuirax4hfx8cem450tuw5uwvn74xgq783y',
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
        is_expected.to run_docker_container('registry.osuosl.org').with(
          tag: '2',
          port: '8082:5000',
          restart_policy: 'always',
          env: [
            'REGISTRY_STORAGE=s3',
            'REGISTRY_STORAGE_S3_ACCESSKEY=access_key',
            'REGISTRY_STORAGE_S3_SECRETKEY=secret_key',
            'REGISTRY_STORAGE_S3_REGION=us-east-1',
            'REGISTRY_STORAGE_S3_BUCKET=osuosl-registry',
            'REGISTRY_STORAGE_S3_REGIONENDPOINT=s3.osuosl.org',
            'REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io',
            'REGISTRY_PROXY_USERNAME=docker_username',
            'REGISTRY_PROXY_PASSWORD=docker_password',
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
