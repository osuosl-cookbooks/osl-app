describe http(
  'http://127.0.0.1/streamwebs-production/media/index.html',
  headers: { 'Host' => 'streamwebs.org' }
) do
  its('body') { should match 'streamwebs-production' }
end

describe http(
  'http://127.0.0.1/streamwebs-staging/media/index.html',
  headers: { 'Host' => 'streamwebs-staging.osuosl.org' }
) do
  its('body') { should match 'streamwebs-staging' }
end

describe http(
  'http://127.0.0.1:8084/',
  headers: { 'Host' => 'code.mulgara.org' }
) do
  its('status') { should eq 200 }
  its('body') { should match '<title>Mulgara Redmine</title>' }
end

%w(8085 8086).each do |port|
  describe http("http://127.0.0.1:#{port}/") do
    its('status') { should eq 200 }
    its('body') { should match '<title>Etherpad</title>' }
  end
end

# Ensure ep_small_list plugin is not installed on etherpad-lite
describe http('http://127.0.0.1:8085/small_list') do
  its('status') { should eq 404 }
end

# Ensure ep_small_list plugin is installed on etherpad-snowdrift
describe http('http://127.0.0.1:8086/small_list') do
  its('status') { should eq 200 }
end

%w(
  streamwebs-production-gunicorn
  streamwebs-staging-gunicorn
  timesync-web-production
  timesync-web-staging
).each do |s|
  describe service(s) do
    it { should be_enabled }
  end
end

%w(streamwebs-production nginx).each do |u|
  describe user(u) do
    its('groups') { should include 'streamwebs-production' }
  end
end

%w(streamwebs-staging nginx).each do |u|
  describe user(u) do
    its('groups') { should include 'streamwebs-staging' }
  end
end

describe command 'sudo -U streamwebs-staging -l' do
  its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart streamwebs-staging-gunicorn} }
end

describe command 'sudo -U streamwebs-production -l' do
  its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart streamwebs-production-gunicorn} }
end

%w(
  timesync-web-staging
  timesync-web-production
).each do |app|
  describe command "sudo -U #{app} -l" do
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart #{app}} }
  end
end
