chef_gem 'rest-client'

ruby_block 'wait_for_replicant' do
  extend OslAppTest::Cookbook::Helpers
  block do
    times = 0
    until get_return_code('http://127.0.0.1:8090/') == 200
      times += 1
      sleep 5
      puts "Still waiting for redmine.replicant.us to start... #{times * 5} seconds"
      raise('Failed to start redmine.replicant.us') if times > 30
    end
  end
  not_if { get_return_code('http://127.0.0.1:8090/') == 200 }
  only_if { ::File.exist?('/root/.replicant-postrun') }
end

file '/root/.replicant-postrun'

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
