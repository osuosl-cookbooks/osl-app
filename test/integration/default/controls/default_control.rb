docker = inspec.file('/.dockerenv').exist?

osl_only = input('osl_only')

control 'default' do
  describe iptables do
    if osl_only
      it { should have_rule '-A unicorn -p tcp -m tcp --dport 8080:9000 -j osl_only' }
    else
      it { should have_rule '-A unicorn -p tcp -m tcp --dport 8080:9000 -j ACCEPT' }
    end
  end unless docker

  describe ip6tables do
    if osl_only
      it { should have_rule '-A unicorn -p tcp -m tcp --dport 8080:9000 -j osl_only' }
    else
      it { should have_rule '-A unicorn -p tcp -m tcp --dport 8080:9000 -j ACCEPT' }
    end
  end unless docker

  describe service('docker') do
    it { should be_enabled }
  end
end
