%w(
  openid-production-delayed-job
  openid-production-unicorn
  openid-staging-delayed-job
  openid-staging-unicorn
).each do |s|
  describe service(s) do
    it { should be_enabled }
  end
end

describe command 'sudo -U openid-production -l' do
  its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart openid-production-delayed-job} }
  its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart openid-production-unicorn} }
end

describe command 'sudo -U openid-staging -l' do
  its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart openid-staging-delayed-job} }
  its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart openid-staging-unicorn} }
end
