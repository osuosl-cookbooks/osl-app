%w(formsender-production-gunicorn
   formsender-staging-gunicorn
   iam-production
   iam-staging
   timesync-production
   timesync-staging
   docker).each do |s|
     describe service(s) do
       it { should be_enabled }
     end
   end

describe http(
  'http://127.0.0.1:8090/',
  headers: { 'Host' => 'redmine.replicant.us' },
  enable_remote_worker: true
) do
  its('status') { should eq 200 }
  its('body') { should match(%r{<h1><span class="current-project">replicant<\/span><\/h1>}) }
end

describe docker.images.where { repository == 'osuosl/redmine-replicant' && tag == '4.1.1' } do
  it { should exist }
end

describe docker_container('redmine.replicant.us') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'osuosl/redmine-replicant:4.1.1' }
  its('repo') { should eq 'osuosl/redmine-replicant' }
  its('tag') { should eq '4.1.1' }
  its('ports') { should eq '0.0.0.0:8090->3000/tcp' }
end
