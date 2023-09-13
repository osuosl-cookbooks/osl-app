include_controls 'default'

control 'app2' do
  describe service('docker') do
    it { should be_enabled }
  end

  describe http(
    'http://127.0.0.1:8090/',
    headers: { 'Host' => 'replicant.redmine.us' }
  ) do
    its('status') { should eq 200 }
    its('body') { should match %r{<h1><span class="current-project">replicant<\/span><\/h1>} }
  end

  describe http(
    'http://127.0.0.1:8090/projects/replicant/activity.atom',
    headers: { 'Host' => 'replicant.redmine.us' }
  ) do
    its('status') { should eq 200 }
    its('body') { should match %r{<link rel="self" href="http://replicant.redmine.us/projects/replicant/activity.atom"/>} }
  end

  describe docker.images.where { repository == 'osuosl/redmine-replicant' && tag == '4.2.3-2022.01.14.1907' } do
    it { should exist }
  end

  describe docker_container('redmine.replicant.us') do
    it { should exist }
    it { should be_running }
    its('image') { should eq 'osuosl/redmine-replicant:4.2.3-2022.01.14.1907' }
    its('ports') { should eq '0.0.0.0:8090->3000/tcp' }
  end

  describe command('docker exec redmine.replicant.us env') do
    %W(
      REDMINE_DB_MYSQL=#{interface('eth0').ipv4_address}
      REDMINE_DB_DATABASE=replicant_redmine
      REDMINE_DB_USERNAME=redmine
      REDMINE_DB_PASSWORD=super_safe
      REDMINE_PLUGINS_MIGRATE=1
    ).each do |line|
      its('stdout') { should match line }
    end
  end

  describe docker_container('formsender') do
    it { should exist }
    it { should be_running }
    its('image') { should eq 'formsender:latest' }
    its('ports') { should eq '0.0.0.0:8085->5000/tcp' }
  end

  describe http 'http://127.0.0.1:8085/server-status' do
    its('status') { should eq 200 }
  end
end
