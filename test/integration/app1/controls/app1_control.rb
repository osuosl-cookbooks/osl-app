control 'app1' do
  # describe docker_container 'openid-production-website' do
  #   it { should exist }
  #   it { should be_running }
  #   its('ports') { should eq '0.0.0.0:8081->8080/tcp' }
  # end

  describe docker_container 'openid-staging-website' do
    it { should exist }
    it { should be_running }
    its('ports') { should eq '0.0.0.0:8080->8080/tcp' }
  end

  # describe docker_container 'openid-production-delayed-job' do
  #   it { should exist }
  #   it { should be_running }
  # end

  describe docker_container 'openid-staging-delayed-job' do
    it { should exist }
    it { should be_running }
  end

  describe http 'localhost:8080/foundation/members/registration' do
    its('status') { should cmp 200 }
    its('body') { should match 'https://staging.openid.net/foundation/members/rpx' }
  end

  # describe http 'localhost:8081/foundation/members/registration' do
  #   its('status') { should cmp 200 }
  #   its('body') { should match 'https://openid.net/foundation/members/rpx' }
  # end

  %w(
    openid-production-delayed-job
    openid-production-unicorn
  ).each do |s|
    describe service(s) do
      it { should be_enabled }
    end
  end

  describe command 'sudo -U openid-production -l' do
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart openid-production-delayed-job} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart openid-production-unicorn} }
  end
end
