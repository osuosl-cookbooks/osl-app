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

%w(
  fenestra
).each do |s|
  describe service(s) do
    it { should_not be_enabled }
    it { should_not be_running }
  end
end
