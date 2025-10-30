module OslApp
  module Cookbook
    module Helpers
      def osl_sudo_commands(*args)
        args.reduce([]) { |acc, elem| acc + osl_systemctl_commands(elem) }
      end

      def osl_systemctl_commands(service)
        %w(enable disable stop start status reload restart).collect do |x|
          "/usr/bin/systemctl #{x} #{service}"
        end
      end

      def osl_app_packages
        if node['platform_version'].to_i < 8
          %w(
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
          )
        else
          %w(
            freetype-devel
            libjpeg-turbo-devel
            libpng-devel
            postgresql-devel
            proj
            python3-gdal
            python3-psycopg2
          )
        end
      end

      private

      def user_uid(username)
        require 'etc'
        Etc.getpwnam(username).uid
      end
    end
  end
end

Chef::Resource.include OslApp::Cookbook::Helpers
Chef::DSL::Recipe.include OslApp::Cookbook::Helpers
