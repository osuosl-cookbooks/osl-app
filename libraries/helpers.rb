module OslApp
  module Cookbook
    module Helpers
      def sudo_commands(*args)
        args.reduce([]) { |acc, elem| acc + systemctl_commands(elem) }
      end

      def systemctl_commands(service)
        %w(enable disable stop start status reload restart).collect do |x|
          "/usr/bin/systemctl #{x} #{service}"
        end
      end
    end
  end
end

Chef::Resource.include OslApp::Cookbook::Helpers
Chef::DSL::Recipe.include OslApp::Cookbook::Helpers
