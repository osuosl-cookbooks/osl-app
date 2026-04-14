control 'app3' do
  describe http(
    'http://127.0.0.1/streamwebs-production/media/index.html',
    headers: { 'Host' => 'streamwebs.org' }
  ) do
    its('body') { should match 'streamwebs-production' }
  end

  describe http(
    'http://127.0.0.1:8080',
    headers: { 'Host' => 'streamwebs.org' }
  ) do
    its('status') { should eq 200 }
    its('body') { should match 'streamwebs' }
  end

  describe http(
    'http://127.0.0.1:8081',
    headers: { 'Host' => 'streamwebs-staging.osuosl.org' }
  ) do
    its('status') { should eq 200 }
    its('body') { should match 'streamwebs' }
  end

  describe http(
    'http://127.0.0.1/streamwebs-staging/media/index.html',
    headers: { 'Host' => 'streamwebs-staging.osuosl.org' }
  ) do
    its('body') { should match 'streamwebs-staging' }
  end

  describe http(
    'http://127.0.0.1:8084/',
    headers: { 'Host' => 'code.mulgara.org' }
  ) do
    its('status') { should eq 200 }
    its('body') { should match '<title>Mulgara Redmine</title>' }
  end

  %w(8085 8086).each do |port|
    describe http("http://127.0.0.1:#{port}/") do
      its('status') { should eq 200 }
      its('body') { should match '<title>Etherpad</title>' }
    end
  end

  describe docker.images.where { repository == 'ghcr.io/osuosl/streamwebs' && tag == 'develop' } do
    it { should exist }
  end

  describe docker.images.where { repository == 'ghcr.io/osuosl/streamwebs' && tag == 'master' } do
    it { should exist }
  end

  describe docker.images.where { repository == 'redmine' && tag == '5.1' } do
    it { should exist }
  end

  describe docker.images.where { repository == 'etherpad/etherpad' && tag == 'latest' } do
    it { should exist }
  end

  describe docker_container('streamwebs-staging.osuosl.org') do
    it { should exist }
    it { should be_running }
    its('image') { should eq 'ghcr.io/osuosl/streamwebs:develop' }
    its('ports') { should eq '0.0.0.0:8081->8000/tcp' }
    its('command') { should eq '/usr/src/app/entrypoint.sh' }
  end

  describe docker_container('streamwebs.org') do
    it { should exist }
    it { should be_running }
    its('image') { should eq 'ghcr.io/osuosl/streamwebs:master' }
    its('ports') { should eq '0.0.0.0:8080->8000/tcp' }
    its('command') { should eq '/usr/src/app/entrypoint.sh' }
  end

  describe docker_container('code.mulgara.org') do
    it { should exist }
    it { should be_running }
    its('image') { should eq 'redmine:5.1' }
    its('ports') { should eq '0.0.0.0:8084->3000/tcp' }
  end

  describe command('docker exec code.mulgara.org env') do
    %W(
      REDMINE_DB_MYSQL=#{interface('eth0').ipv4_address}
      REDMINE_DB_DATABASE=mulgara_redmine
      REDMINE_DB_USERNAME=redmine
      REDMINE_DB_PASSWORD=super_safe
      REDMINE_PLUGINS_MIGRATE=1
    ).each do |line|
      its('stdout') { should match line }
    end
  end

  describe command('docker exec etherpad-lite.osuosl.org env') do
    %W(
      DB_TYPE=mysql
      DB_HOST=#{interface('eth0').ipv4_address}
      DB_NAME=etherpad_osl
      DB_USER=etherpad_osl
      DB_PASS=super_safe
      ADMIN_PASSWORD=adminpasswd
    ).each do |line|
      its('stdout') { should match line }
    end
  end

  describe command('docker exec etherpad-snowdrift.osuosl.org env') do
    %W(
      DB_TYPE=mysql
      DB_HOST=#{interface('eth0').ipv4_address}
      DB_NAME=etherpad_sd
      DB_USER=etherpad_sd
      DB_PASS=super_safe
      ADMIN_PASSWORD=adminpasswd
    ).each do |line|
      its('stdout') { should match line }
    end
  end

  %w(streamwebs-production nginx).each do |u|
    describe user(u) do
      its('groups') { should include 'streamwebs-production' }
    end
  end

  %w(streamwebs-staging nginx).each do |u|
    describe user(u) do
      its('groups') { should include 'streamwebs-staging' }
    end
  end

  # Oregon Invasives Hotline tests
  describe directory('/home/invasives-staging/oregoninvasiveshotline') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'invasives-staging' }
  end

  describe file('/home/invasives-staging/oregoninvasiveshotline/.env') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'invasives-staging' }
    its('content') { should match(/ENV=staging/) }
    its('content') { should match(/APP_PORT=8087/) }
    its('content') { should match(/DB_NAME=invasives-staging/) }
    its('content') { should match(/DB_USER=invasives-staging/) }
    its('content') { should match(/DB_HOST=10.1.100.*/) }
    its('content') { should match(/SENTRY_TRACES_SAMPLE_RATE=0.5/) }
    its('content') { should match %r{VOLUME_PATH=/home/invasives-staging/volume} }
    its('content') { should match(/EMAIL_HOST=mailpit/) }
    its('content') { should match(/MAILPIT_PORT=8088/) }
    its('content') { should match(/MAILPIT_UI_AUTH=admin:admin/) }
  end

  describe directory('/home/invasives-staging/oregoninvasiveshotline/docker/secrets') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'invasives-staging' }
  end

  describe directory('/home/invasives-staging/volume/media') do
    it { should exist }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
  end

  describe directory('/home/invasives-staging/volume/static') do
    it { should exist }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
  end

  describe file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/secret_key.txt') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
    its('content') { should cmp '+cj5n258ct-lge3=vvr!r0byc-8$+ch7$f9&#g6_kk(uxngmkc' }
  end

  describe file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/db_password.txt') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
    its('content') { should cmp 'invasives-staging' }
  end

  describe file('/home/invasives-staging/oregoninvasiveshotline/docker/secrets/google_api_key.txt') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
    its('size') { should eq 0 }
  end

  describe docker.images.where { repository == 'ghcr.io/osu-cass/oregoninvasiveshotline' && tag == 'develop' } do
    it { should exist }
  end

  describe json(content: command('docker compose -f /home/invasives-staging/oregoninvasiveshotline/docker-compose.deploy.yml -f /home/invasives-staging/oregoninvasiveshotline/docker-compose.mailpit.yml -p invasives-staging ps --format json --no-trunc | jq -s \'map({Service: .Service, State: .State})\'').stdout) do
    its([0, 'Service']) { should eq 'app' }
    its([0, 'State']) { should eq 'running' }
    its([1, 'Service']) { should eq 'celery' }
    its([1, 'State']) { should eq 'running' }
    its([2, 'Service']) { should eq 'mailpit' }
    its([2, 'State']) { should eq 'running' }
    its([3, 'Service']) { should eq 'nginx' }
    its([3, 'State']) { should eq 'running' }
    its([4, 'Service']) { should eq 'rabbitmq' }
    its([4, 'State']) { should eq 'running' }
  end

  describe http(
    'http://127.0.0.1:8087',
    headers: {
      'Host' => 'staging.oregoninvasiveshotline.org',
      'X-Forwarded-Proto' => 'https',
    }
  ) do
    its('status') { should eq 200 }
    its('headers.location') { should cmp nil }
    its('body') { should match(/Oregon Invasives Hotline/) }
  end

  describe http(
    'http://127.0.0.1:8087/static/robots.txt',
    headers: { 'Host' => 'staging.oregoninvasiveshotline.org' }
  ) do
    its('status') { should eq 200 }
    its('body') { should match(/User-Agent:/) }
  end

  # Oregon Invasives Hotline - Production tests
  describe directory('/home/invasives-production/oregoninvasiveshotline') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'invasives-production' }
  end

  describe file('/home/invasives-production/oregoninvasiveshotline/.env') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'invasives-production' }
    its('content') { should match(/ENV=production/) }
    its('content') { should match(/APP_PORT=8089/) }
    its('content') { should match(/DB_NAME=invasives-production/) }
    its('content') { should match(/DB_USER=invasives-production/) }
    its('content') { should match(/DB_HOST=10.1.100.*/) }
    its('content') { should match(/SENTRY_TRACES_SAMPLE_RATE=1.0/) }
    its('content') { should match %r{VOLUME_PATH=/home/invasives-production/volume} }
    its('content') { should match(/EMAIL_HOST=smtp\.osuosl\.org/) }
    its('content') { should_not match(/MAILPIT_PORT=/) }
    its('content') { should_not match(/MAILPIT_UI_AUTH=/) }
  end

  describe directory('/home/invasives-production/oregoninvasiveshotline/docker/secrets') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'invasives-production' }
  end

  describe directory('/home/invasives-production/volume/media') do
    it { should exist }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
  end

  describe directory('/home/invasives-production/volume/static') do
    it { should exist }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
  end

  describe file('/home/invasives-production/oregoninvasiveshotline/docker/secrets/secret_key.txt') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
    its('content') { should cmp '+cj5n258ct-lge3=vvr!r0byc-8$+ch7$f9&#g6_kk(uxngmkc' }
  end

  describe file('/home/invasives-production/oregoninvasiveshotline/docker/secrets/db_password.txt') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
    its('content') { should cmp 'invasives-production' }
  end

  describe file('/home/invasives-production/oregoninvasiveshotline/docker/secrets/google_api_key.txt') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('uid') { should eq 1000 }
    its('gid') { should eq 1000 }
    its('size') { should eq 0 }
  end

  describe docker.images.where { repository == 'ghcr.io/osu-cass/oregoninvasiveshotline' && tag == 'main' } do
    it { should exist }
  end

  describe json(content: command('docker compose -f /home/invasives-production/oregoninvasiveshotline/docker-compose.deploy.yml -p invasives-production ps --format json --no-trunc | jq -s \'sort_by(.Service) | map({Service: .Service, State: .State})\'').stdout) do
    its([0, 'Service']) { should eq 'app' }
    its([0, 'State']) { should eq 'running' }
    its([1, 'Service']) { should eq 'celery' }
    its([1, 'State']) { should eq 'running' }
    its([2, 'Service']) { should eq 'nginx' }
    its([2, 'State']) { should eq 'running' }
    its([3, 'Service']) { should eq 'rabbitmq' }
    its([3, 'State']) { should eq 'running' }
  end

  describe http(
    'http://127.0.0.1:8089',
    headers: {
      'Host' => 'oregoninvasiveshotline.org',
      'X-Forwarded-Proto' => 'https',
    }
  ) do
    its('status') { should eq 200 }
    its('headers.location') { should cmp nil }
    its('body') { should match(/Oregon Invasives Hotline/) }
  end

  describe http(
    'http://127.0.0.1:8089/static/robots.txt',
    headers: { 'Host' => 'oregoninvasiveshotline.org' }
  ) do
    its('status') { should eq 200 }
    its('body') { should match(/User-Agent:/) }
  end

  # EEC Walkthrough React - Staging
  describe docker.images.where { repository == 'ghcr.io/osu-cass/eec-walkthrough-react' && tag == 'dev' } do
    it { should exist }
  end

  describe docker_container('eec-walkthrough-staging.cass.oregonstate.edu') do
    it { should exist }
    it { should be_running }
    its('image') { should eq 'ghcr.io/osu-cass/eec-walkthrough-react:dev' }
    its('ports') { should match(/0.0.0.0:8090->1111/) }
    its('ports') { should match(/0.0.0.0:8091->2222/) }
  end

  describe directory('/home/eec-walkthrough-staging/secrets') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'eec-walkthrough-staging' }
  end

  describe directory('/home/eec-walkthrough-staging/uploads') do
    it { should exist }
  end

  describe directory('/home/eec-walkthrough-staging/public-uploads') do
    it { should exist }
  end

  describe file('/home/eec-walkthrough-staging/secrets/mysql_password.txt') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('content') { should cmp 'eec-walkthrough-staging' }
  end

  describe file('/home/eec-walkthrough-staging/secrets/jwt_secret_key.txt') do
    it { should exist }
    it { should be_file }
    its('mode') { should cmp '0400' }
    its('content') { should cmp 'staging_jwt_secret' }
  end

  describe command('docker exec eec-walkthrough-staging.cass.oregonstate.edu env') do
    %W(
      API_PORT=1111
      FILE_PORT=2222
      NODE_ENV=production
      MYSQL_DB_NAME=eec_walkthrough_staging
      MYSQL_HOST=#{interface('eth0').ipv4_address}
      MYSQL_PORT=3306
      MYSQL_USER=eec-walkthrough-staging
      MYSQL_PASSWORD_FILE=/run/secrets/mysql_password
      JWT_SECRET_KEY_FILE=/run/secrets/jwt_secret_key
    ).each do |line|
      its('stdout') { should match line }
    end
  end

  describe http(
    'http://127.0.0.1:8091',
    headers: { 'Host' => 'eec-walkthrough-staging.cass.oregonstate.edu' }
  ) do
    its('status') { should eq 200 }
  end

  describe http(
    'http://127.0.0.1:8090/api/home',
    headers: { 'Host' => 'eec-walkthrough-staging.cass.oregonstate.edu' }
  ) do
    its('status') { should be_in [200, 304] }
  end

  # dockercompose_wrapper - invasives-staging
  %w(console logs ps).each do |cmd|
    describe file "/usr/local/bin/invasives-staging-#{cmd}" do
      it { should exist }
      it { should be_executable }
    end
  end

  describe file '/usr/local/bin/invasives-staging-console' do
    its('content') { should match /docker compose -p invasives-staging/ }
    its('content') { should match /exec/ }
    its('content') { should match /usage\(\)/ }
  end

  describe file '/usr/local/bin/invasives-staging-logs' do
    its('content') { should match /docker compose -p invasives-staging/ }
    its('content') { should match /logs/ }
    its('content') { should match /usage\(\)/ }
  end

  describe file '/usr/local/bin/invasives-staging-ps' do
    its('content') { should match /docker compose -p invasives-staging/ }
    its('content') { should match /ps/ }
    its('content') { should match /usage\(\)/ }
  end

  describe command 'sudo -U invasives-staging -l' do
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/invasives-staging-console} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/invasives-staging-logs} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/invasives-staging-ps} }
  end

  # dockercompose_wrapper - invasives-production
  %w(console logs ps).each do |cmd|
    describe file "/usr/local/bin/invasives-production-#{cmd}" do
      it { should exist }
      it { should be_executable }
    end
  end

  describe file '/usr/local/bin/invasives-production-console' do
    its('content') { should match /docker compose -p invasives-production/ }
    its('content') { should match /exec/ }
    its('content') { should match /usage\(\)/ }
  end

  describe file '/usr/local/bin/invasives-production-logs' do
    its('content') { should match /docker compose -p invasives-production/ }
    its('content') { should match /logs/ }
    its('content') { should match /usage\(\)/ }
  end

  describe file '/usr/local/bin/invasives-production-ps' do
    its('content') { should match /docker compose -p invasives-production/ }
    its('content') { should match /ps/ }
    its('content') { should match /usage\(\)/ }
  end

  describe command 'sudo -U invasives-production -l' do
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/invasives-production-console} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/invasives-production-logs} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/invasives-production-ps} }
  end

  # docker_wrapper - eec-walkthrough-staging
  %w(console logs).each do |cmd|
    describe file "/usr/local/bin/eec-walkthrough-staging.cass.oregonstate.edu-#{cmd}" do
      it { should exist }
      it { should be_executable }
    end
  end

  describe command 'sudo -U eec-walkthrough-staging -l' do
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/eec-walkthrough-staging.cass.oregonstate.edu-console} }
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/local/bin/eec-walkthrough-staging.cass.oregonstate.edu-logs} }
  end
end
