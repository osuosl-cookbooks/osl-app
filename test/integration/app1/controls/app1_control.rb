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

  describe command('docker exec openid-staging-website env') do
    its('stdout') { should match /RAILS_ENV=staging/ }
    its('stdout') { should match /BRAINTREE_ENV=sandbox/ }
    its('stdout') { should match %r{HELLO_ISSUER=https://issuer\.hello\.coop} }
    its('stdout') { should match /HELLO_CLIENT_ID=hello_client_id/ }
    its('stdout') { should match /HELLO_CLIENT_SECRET=hello_client_secret/ }
    its('stdout') { should match /SECRET_KEY_BASE=7eef5c70ecb083192f46e601144f9d77c9b66061b634963a5070fb086ae78bc9353af2c6311edb168abbb9d0bd428f800a0b1713534cf4ad239e8d07fdd16c34/ }
    its('stdout') { should match /BRAINTREE_ACCESS_TOKEN=access_token\$production\$mnlc24xq7uGUqKczYhg5PpNGiVOkss/ }
    its('stdout') { should match /RECAPTCHA_SITE_KEY=fay7bvryba784ycban3dxar7x83a7ca37trateh/ }
    its('stdout') { should match /RECAPTCHA_SECRET_KEY=vfu389ray3xrwg3r7w3tra7tfazr837tvrany7s/ }
  end

  describe command('docker exec openid-production-website env') do
    its('stdout') { should match /RAILS_ENV=production/ }
    its('stdout') { should match /BRAINTREE_ENV=production/ }
    its('stdout') { should match %r{HELLO_ISSUER=https://issuer\.hello\.coop} }
    its('stdout') { should match /SECRET_KEY_BASE=7eef5c70ecb083192f46e601144f9d77c9b66061b634963a5070fb086ae78bc9353af2c6311edb168abbb9d0bd428f800a0b1713534cf4ad239e8d07fdd16c34/ }
    its('stdout') { should match /BRAINTREE_ACCESS_TOKEN=access_token\$production\$mnlc24xq7uGUqKczYhg5PpNGiVOkss/ }
    its('stdout') { should match /RECAPTCHA_SITE_KEY=fay7bvryba784ycban3dxar7x83a7ca37trateh/ }
    its('stdout') { should match /RECAPTCHA_SECRET_KEY=vfu389ray3xrwg3r7w3tra7tfazr837tvrany7s/ }
  end

  describe docker_container 'registry-valkey' do
    it { should exist }
    it { should be_running }
  end

  describe docker_container 'registry.osuosl.org' do
    it { should exist }
    it { should be_running }
    its('ports') { should match %r{0.0.0.0:8082->5000/tcp} }
  end

  describe file '/usr/local/etc/registry.osuosl.org/htpasswd' do
    its('content') { should match /^guest:\$apr1/ }
    its('content') { should match /^admin:\$apr1/ }
  end

  describe docker_container 'openid-production-delayed-job' do
    it { should exist }
    it { should be_running }
  end

  describe docker_container 'openid-staging-delayed-job' do
    it { should exist }
    it { should be_running }
  end

  describe command('docker exec openid-staging-delayed-job env') do
    its('stdout') { should match /SECRET_KEY_BASE=7eef5c70ecb083192f46e601144f9d77c9b66061b634963a5070fb086ae78bc9353af2c6311edb168abbb9d0bd428f800a0b1713534cf4ad239e8d07fdd16c34/ }
  end

  describe http 'localhost:8080/foundation/members/registration' do
    its('status') { should cmp 200 }
    its('body') { should match 'Membership Dues' }
  end

  describe http 'localhost:8081/foundation/members/registration' do
    its('status') { should cmp 200 }
    its('body') { should match 'Membership Dues' }
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
