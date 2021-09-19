%w(
  formsender-production-gunicorn
  formsender-staging-gunicorn
  iam-production
  iam-staging
  timesync-production
  timesync-staging
  docker
).each do |s|
  describe service(s) do
    it { should be_enabled }
  end
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

describe docker.images.where { repository == 'osuosl/redmine-replicant' && tag == '4.1.1-2020.12.12.0022' } do
  it { should exist }
end

describe docker_container('redmine.replicant.us') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'osuosl/redmine-replicant:4.1.1-2020.12.12.0022' }
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

describe command 'sudo -U formsender-staging -l' do
  its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart formsender-staging-gunicorn} }
end

describe command 'sudo -U formsender-production -l' do
  its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart formsender-production-gunicorn} }
end

%w(
  iam-production
  iam-staging
  timesync-production
  timesync-staging
).each do |app|
  describe command "sudo -U #{app} -l" do
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart #{app}} }
  end
end
