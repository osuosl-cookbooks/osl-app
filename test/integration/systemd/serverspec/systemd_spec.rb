require 'serverspec'

set :backend, :exec

describe file('/etc/systemd/system') do
  it { should be_directory }
  it { should be_mode 750 }
end
