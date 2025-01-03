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
end
