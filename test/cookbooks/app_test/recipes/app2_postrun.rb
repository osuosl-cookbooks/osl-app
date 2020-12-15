chef_gem 'rest-client' do
  action :install
  compile_time false
end

ruby_block 'wait_for_replicant' do
  block do
    require 'rest-client'
    times = 0
    client = nil
    until client && client.code == 200
      times += 1
      begin
        client = RestClient.get 'http://127.0.0.1:8090/'
      rescue
        sleep 5
        puts "Still waiting for redmine.replicant.us to start... #{times * 5} seconds"
      end
      raise('Failed to start redmine.replicant.us') if times > 30
    end
  end
end
