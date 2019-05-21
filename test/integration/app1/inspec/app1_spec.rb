%w(fenestra
   openid-production-delayed-job
   openid-production-unicorn
   openid-staging-delayed-job
   openid-staging-unicorn).each do |s|
     describe service(s) do
       it { should be_enabled }
     end
   end
