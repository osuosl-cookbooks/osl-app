build_essential 'app-test'
chef_gem 'rest-client'

ruby_block 'wait_for_mulgara' do
  extend OslAppTest::Cookbook::Helpers
  block do
    times = 0
    until get_return_code('http://127.0.0.1:8084/') == 200
      times += 1
      sleep 5
      puts "Still waiting for code.mulgara.org to start... #{times * 5} seconds"
      if times > 6
        puts '! Failed to start code.mulgara.org, could just be first run !'
        break
      end
    end
  end
  not_if { get_return_code('http://127.0.0.1:8084/') == 200 }
end

# localhost / test kitchen ip is not in OSL ips
# allow all traffic so kitchen test works

edit_resource!(:osl_firewall_port, 'unicorn') do
  osl_only false
end

edit_resource!(:osl_firewall_docker, 'osl-docker') do
  osl_only false
end

%w(production staging).each do |env|
  directory "/home/streamwebs-#{env}/media" do
    user "streamwebs-#{env}"
    group "streamwebs-#{env}"
    recursive true
  end

  file "/home/streamwebs-#{env}/media/index.html" do
    user "streamwebs-#{env}"
    group "streamwebs-#{env}"
    content "streamwebs-#{env}"
  end
end
