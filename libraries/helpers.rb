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

      def github_credentials
        data_bag_item('osl-app', 'github_credentials')
      rescue Net::HTTPServerException => e
        if e.response.code == '404'
          Chef::Log.warn("Could not find databag 'osl-app:github_credentials'; falling back to default attributes.")
          node['osl-app']['github_credentials']
        else
          Chef::Log.fatal("Unable to load databag 'osl-app:github_credentials'; exiting. Please fix the databag and try again.")
          raise
        end
      end
    end
  end
end

Chef::Resource.include OslApp::Cookbook::Helpers
Chef::DSL::Recipe.include OslApp::Cookbook::Helpers
