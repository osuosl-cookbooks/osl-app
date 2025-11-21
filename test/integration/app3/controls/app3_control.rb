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

  describe docker.images.where { repository == 'redmine' && tag == '5.1.4' } do
    it { should exist }
  end

  describe docker.images.where { repository == 'elestio/etherpad' && tag == 'latest' } do
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
    its('image') { should eq 'redmine:5.1.4' }
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
    its('content') { should match /ENV=staging/ }
    its('content') { should match /APP_PORT=8087/ }
    its('content') { should match /DB_NAME=invasives-staging/ }
    its('content') { should match /DB_USER=invasives-staging/ }
    its('content') { should match /DB_HOST=10.1.100.*/ }
    its('content') { should match /SENTRY_TRACES_SAMPLE_RATE=0.5/ }
    its('content') { should match %r{VOLUME_PATH=/home/invasives-staging/volume} }
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

  describe json(content: command('docker compose -f /home/invasives-staging/oregoninvasiveshotline/docker-compose.deploy.yml -p invasives-staging ps --format json --no-trunc | jq -s \'map({Service: .Service, State: .State})\'').stdout) do
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
    'http://127.0.0.1:8087',
    headers: {
      'Host' => 'staging.oregoninvasiveshotline.org',
      'X-Forwarded-Proto' => 'https',
    }
  ) do
    its('status') { should eq 200 }
    its('headers.location') { should cmp nil }
    its('body') { should match /Oregon Invasives Hotline/ }
  end

  describe http(
    'http://127.0.0.1:8087/static/robots.txt',
    headers: { 'Host' => 'staging.oregoninvasiveshotline.org' }
  ) do
    its('status') { should eq 200 }
    its('body') { should match /User-Agent:/ }
  end
end
