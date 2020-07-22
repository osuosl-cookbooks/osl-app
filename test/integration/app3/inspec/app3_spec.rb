describe http(
  'http://127.0.0.1/streamwebs-production/media/index.html',
  headers: { 'Host' => 'streamwebs.org' },
  enable_remote_worker: true
) do
  its('body') { should match(/^streamwebs-production$/) }
end

describe http(
  'http://127.0.0.1/streamwebs-staging/media/index.html',
  headers: { 'Host' => 'streamwebs-staging.osuosl.org' },
  enable_remote_worker: true
) do
  its('body') { should match(/^streamwebs-staging$/) }
end

describe http(
  'http://127.0.0.1:8084/',
  headers: { 'Host' => 'code.mulgara.org' },
  enable_remote_worker: true
) do
  its('status') { should eq 200 }
  its('body') { should match(%r{^<title>Mulgara Redmine<\/title>$}) }
end

%w(streamwebs-production-gunicorn
   streamwebs-staging-gunicorn
   timesync-web-production
   timesync-web-staging
   docker).each do |s|
     describe service(s) do
       it { should be_enabled }
     end
   end

describe docker.images.where { repository == 'redmine' && tag == '4.1.1' } do
  it { should exist }
end

describe docker_container('code.mulgara.org') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'redmine:4.1.1' }
  its('repo') { should eq 'redmine' }
  its('tag') { should eq '4.1.1' }
  its('ports') { should eq '0.0.0.0:8084->3000/tcp' }
end
