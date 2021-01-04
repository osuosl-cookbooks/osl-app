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
        %w(
          osl-repos::epel
          osl-mysql::default
          base::python
        ).each do |p|
          expect(chef_run).to include_recipe(p)
        end
      end

      case plat
      when CENTOS_7
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
      when CENTOS_8
        it do
          expect(chef_run).to install_package(%w(
            freetype-devel
            libjpeg-turbo-devel
            libpng-devel
            postgresql-devel
            proj
            python3-gdal
            python3-psycopg2
          ))
        end
      end

      it do
        expect(chef_run).to create_directory('/etc/systemd/system').with(mode: '750')
      end
    end
  end
end
