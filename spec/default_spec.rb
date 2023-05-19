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

      it do
        expect(chef_run).to include_recipe('git')
        expect(chef_run).to include_recipe('osl-docker')
      end

      case plat[:version].to_i
      when 7
        it do
          %w(
            base::python
            osl-mysql::default
            osl-nodejs::default
            osl-repos::centos
            osl-repos::epel
          ).each do |p|
            expect(chef_run).to include_recipe(p)
          end
        end

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

      it do
        expect(chef_run).to accept_osl_firewall_port('unicorn').with(osl_only: true)
      end
    end
  end
end
