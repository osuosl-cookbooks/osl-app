module OslAppTest
  module Cookbook
    module Helpers
      def get_return_code(site)
        require 'rest-client'

        begin
          client = RestClient.get site
        rescue
          client = nil
        end

        client ? client.code : nil
      end
    end
  end
end
