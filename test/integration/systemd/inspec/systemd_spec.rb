describe file('/etc/systemd/system') do
  it { should be_directory }
  its('mode') { should cmp '0750' }
end
