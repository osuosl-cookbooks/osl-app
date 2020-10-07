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
          yum-epel::default
          osl-mysql::default
          base::python
        ).each do |p|
          expect(chef_run).to include_recipe(p)
        end
      end

      it do
        if plat[:version].to_i < 8
          %w(
            automake
            freetype-devel
            geos-devel
            ImageMagick-devel
            libffi-devel
            libjpeg-turbo-devel
            libpng-devel
            libtool
            libyaml
            openssl-devel
            postgresql-devel
            proj
            python-psycopg2
            readline-devel
            sqlite-devel
            zlib-devel
          ).each do |p|
            expect(chef_run).to install_package(p)
          end
        else
          %w(
            automake
            freetype-devel
            geos-devel
            ImageMagick-devel
            libffi-devel
            libjpeg-turbo-devel
            libpng-devel
            libtool
            libyaml
            openssl-devel
            postgresql-devel
            proj
            python2-psycopg2
            readline-devel
            sqlite-devel
            zlib-devel
          ).each do |p|
            expect(chef_run).to install_package(p)
          end
        end
      end

      it do
        expect(chef_run).to create_directory('/etc/systemd/system').with(mode: '750')
      end
    end
  end
end
