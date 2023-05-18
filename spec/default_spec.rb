require_relative 'spec_helper'

describe 'osl-app::default' do
  ALL_PLATFORMS.each do |plat|
    context "#{plat[:platform]} #{plat[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(plat) do |_node, server|
        end.converge('sudo', described_recipe)
      end

      include_context 'common_stubs'

      it do
        expect { chef_run }.to_not raise_error
      end

      case plat[:version].to_i
      when 7

        it do
          %w(
            base::python
            git::default
            osl-mysql::default
            osl-nodejs::default
            osl-repos::centos
            osl-repos::epel
          ).each do |p|
            expect(chef_run).to include_recipe(p)
          end
        end

        it { expect(chef_run).to accept_osl_firewall_port('unicorn').with(osl_only: true) }

        it do
          expect(chef_run).to install_package(%w(
            freetype-devel
            gdal-python
            geos-python
            libjpeg-turbo-devel
            libpng-devel
            postgis
            postgresql-devel
            proj
            proj-nad
            python-psycopg2
          ))
        end
        it do
          expect(chef_run).to create_directory('/etc/systemd/system').with(mode: '750')
        end
      end

      context 'app2' do
        cached(:subject) { chef_run }

        include_context 'common_stubs'

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

        it do
          expect(chef_run).to sync_git('/var/lib/formsender').with(
            repository: 'https://github.com/osuosl/formsender.git',
            revision: 'master'
          )
          expect(chef_run.git('/var/lib/formsender')).to notify('docker_image[formsender]').to(:build).immediately
          expect(chef_run.git('/var/lib/formsender')).to notify('docker_container[formsender]').to(:redeploy).delayed
        end

        it do
          expect(chef_run).to_not pull_docker_image('/var/lib/formsender').with(
            tag: 'latest',
            source: '/var/lib/formsender'
          )
        end

        it do
          expect(chef_run).to run_docker_container('formsender').with(
            repo: 'formsender',
            tag: 'latest',
            port: '8085:5000',
            restart_policy: 'always',
            env: [
              'TOKEN=faketoken',
              'RT_TOKEN=rt_faketoken',
              'RECAPTCHA_SECRET=fakerecaptcha',
            ],
            sensitive: true
          )
        end
      end

      context 'app3' do
        cached(:subject) { chef_run }

        include_context 'common_stubs'

        it do
          expect(chef_run).to create_directory('/data/docker/code.mulgara.org').with(
            recursive: true
          )
        end

        it do
          expect(chef_run).to pull_docker_image('library/redmine').with(
            tag: '4.1.1'
          )
        end

        it do
          expect(chef_run).to run_docker_container('code.mulgara.org').with(
            repo: 'redmine',
            tag: '4.1.1',
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
          expect(chef_run).to pull_docker_image('osuosl/etherpad').with(
            tag: '1.8.6-2020.11.13.2015'
          )
        end

        it do
          expect(chef_run).to run_docker_container('etherpad-lite.osuosl.org').with(
            repo: 'osuosl/etherpad',
            tag: '1.8.6-2020.11.13.2015',
            port: '8085:9001',
            restart_policy: 'always',
            user: 'etherpad',
            env: [
              'DB_TYPE=mysql',
              'DB_HOST=testdb.osuosl.bak',
              'DB_NAME=fakedb',
              'DB_USER=fakeuser',
              'DB_PASS=fakepw',
              'ADMIN_PASSWORD=fakeadmin',
            ]
          )
        end

        it do
          expect(chef_run).to pull_docker_image('osuosl/etherpad-snowdrift').with(
            tag: '1.8.6-2020.11.13.2015'
          )
        end

        it do
          expect(chef_run).to run_docker_container('etherpad-snowdrift.osuosl.org').with(
            repo: 'osuosl/etherpad-snowdrift',
            tag: '1.8.6-2020.11.13.2015',
            port: '8086:9001',
            restart_policy: 'always',
            user: 'etherpad',
            env: [
              'DB_TYPE=mysql',
              'DB_HOST=testdb.osuosl.bak',
              'DB_NAME=fakedb',
              'DB_USER=fakeuser',
              'DB_PASS=fakepw',
              'ADMIN_PASSWORD=fakeadmin',
            ]
          )
        end
      end
    end
  end
end
