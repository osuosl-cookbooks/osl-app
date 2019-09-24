chef_gem 'rest-client' do
  action :install
  compile_time false
end

ruby_block 'wait_for_mulgara' do
  block do
    require 'rest-client'
    times = 0
    loop do
      times += 1
      begin
        client = RestClient.get 'http://127.0.0.1:8084/'
      rescue
        sleep 5
        print "\nStill waiting for code.mulgara.org to start.. #{times * 5} seconds"
      end
      Chef::Application.fatal!('Failed to start code.mulgara.org') if times > 30
      break if client && client.code == 200
    end
  end
end
