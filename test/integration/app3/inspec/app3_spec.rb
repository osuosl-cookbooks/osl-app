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

%w(streamwebs-production-gunicorn
   streamwebs-staging-gunicorn
   timesync-web-production
   timesync-web-staging).each do |s|
     describe service(s) do
       it { should be_enabled }
     end
   end
