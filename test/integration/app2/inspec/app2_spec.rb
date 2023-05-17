%w(
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
