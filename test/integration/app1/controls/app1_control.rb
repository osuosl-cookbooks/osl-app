control 'app1' do
  describe docker_container 'openid-production-website' do
    it { should exist }
    it { should be_running }
    its('ports') { should eq '0.0.0.0:8081->8080/tcp' }
  end

  describe docker.images.where { repository == 'ghcr.io/openid-foundation/oidf-members' && tag == 'develop' } do
    it { should exist }
  end

  describe docker.images.where { repository == 'ghcr.io/openid-foundation/oidf-members' && tag == 'master' } do
    it { should exist }
  end

  describe docker_container 'openid-staging-website' do
    it { should exist }
    it { should be_running }
    its('ports') { should eq '0.0.0.0:8080->8080/tcp' }
  end

  describe docker_container 'openid-production-delayed-job' do
    it { should exist }
    it { should be_running }
  end

  describe docker_container 'openid-staging-delayed-job' do
    it { should exist }
    it { should be_running }
  end

  describe http 'localhost:8080/foundation/members/registration' do
    its('status') { should cmp 200 }
    its('body') { should match 'https://staging.openid.net/foundation/members/rpx' }
  end

  describe http 'localhost:8081/foundation/members/registration' do
    its('status') { should cmp 200 }
    its('body') { should match 'https://openid.net/foundation/members/rpx' }
  end

  %w(
    openid-staging-website
    openid-staging-delayed-job
  ).each do |f|
    describe file "/usr/local/bin/#{f}-console" do
      it { should exist }
      it { should be_executable }
    end

    describe file "/usr/local/bin/#{f}-logs" do
      it { should exist }
      it { should be_executable }
    end
  end

  describe command 'sudo -U openid-staging -l' do
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/openid-staging-website-console} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/openid-staging-website-logs} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/openid-staging-delayed-job-console} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/openid-staging-delayed-job-logs} }
  end

  describe command 'sudo -U openid-production -l' do
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/openid-production-website-console} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/openid-production-website-logs} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/openid-production-delayed-job-console} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/openid-production-delayed-job-logs} }
  end
end
