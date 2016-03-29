require 'serverspec'

set :backend, :exec

set :path, '/usr/local/bin:$PATH'

%w(sqlite-devel libyaml-devel readline-devel zlib-devel libffi-devel
   openssl-devel automake libtool python git).each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

describe command('node --version') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/v4\.4\.1/) }
end
