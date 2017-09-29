require 'serverspec'

set :backend, :exec

describe command('curl -q -H "Host: new.streamwebs.org" http://127.0.0.1/streamwebs-production/media/index.html') do
  its(:stdout) { should match(/^streamwebs-production$/) }
end

describe command('curl -q -H "Host: streamwebs-staging.osuosl.org" \
http://127.0.0.1/streamwebs-staging/media/index.html') do
  its(:stdout) { should match(/^streamwebs-staging$/) }
end
