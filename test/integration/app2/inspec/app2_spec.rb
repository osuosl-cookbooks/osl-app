%w(formsender-production-gunicorn
   formsender-staging-gunicorn
   iam-production
   iam-staging
   replicant-redmine-unicorn
   timesync-production
   timesync-staging).each do |s|
     describe service(s) do
       it { should be_enabled }
     end
   end
