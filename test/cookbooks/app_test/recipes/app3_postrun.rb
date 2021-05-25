chef_gem 'rest-client' do
  action :install
  compile_time false
end

ruby_block 'wait_for_mulgara' do
  block do
    require 'rest-client'
    times = 0
    client = nil
    until client && client.code == 200
      times += 1
      begin
        client = RestClient.get 'http://127.0.0.1:8084/'
      rescue
        sleep 5
        puts "Still waiting for code.mulgara.org to start... #{times * 5} seconds"
      end
      raise('Failed to start code.mulgara.org') if times > 30
    end
  end
end

# localhost / test kitchen ip is not in OSL ips
# allow all traffic so kitchen test works

edit_resource!(:osl_firewall_port, 'unicorn') do
  osl_only false
end

edit_resource!(:osl_firewall_port, 'mysql') do
  osl_only false
end

edit_resource!(:osl_firewall_docker, 'osl-docker') do
  osl_only false
end
