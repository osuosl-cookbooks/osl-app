case os.release.to_i
when 7
  %w(
    freetype-devel
    gdal-python
    geos-python
    libjpeg-turbo-devel
    libpng-devel
    postgis
    postgresql-devel
    proj
    proj-nad
    python-psycopg2
  ).each do |p|
    describe package(p) do
      it { should be_installed }
    end
  end

  describe command('node --version') do
    its('exit_status') { should eq 0 }
    its('stdout') { should match(/^v6\.*/) }
  end

  describe file('/etc/systemd/system') do
    it { should be_directory }
    its('mode') { should cmp '0750' }
  end

  describe file('/etc/sudoers') do
    it { should be_file }
    its('content') { should match(%r{#includedir \/etc\/sudoers\.d}) }
  end
end

describe iptables do
  it { should have_rule '-A unicorn -p tcp -m tcp --dport 8080:9000 -j osl_only' }
end

describe ip6tables do
  it { should have_rule '-A unicorn -p tcp -m tcp --dport 8080:9000 -j osl_only' }
end

describe service('docker') do
  it { should be_enabled }
end

describe docker.images.where { repository == 'osuosl/redmine-replicant' && tag == '4.2.3-2022.01.14.1907' } do
  it { should exist }
end

describe docker_container('redmine.replicant.us') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'osuosl/redmine-replicant:4.2.3-2022.01.14.1907' }
  its('ports') { should eq '0.0.0.0:8090->3000/tcp' }
end

describe command('docker exec redmine.replicant.us env') do
  %W(
    REDMINE_DB_MYSQL=#{interface('eth0').ipv4_address}
    REDMINE_DB_DATABASE=replicant_redmine
    REDMINE_DB_USERNAME=redmine
    REDMINE_DB_PASSWORD=super_safe
    REDMINE_PLUGINS_MIGRATE=1
  ).each do |line|
    its('stdout') { should match line }
  end
end

%w(
  iam-production
  iam-staging
  timesync-production
  timesync-staging
).each do |app|
  describe command "sudo -U #{app} -l" do
    its('stdout') { should match %r{\(ALL\) NOPASSWD: /usr/bin/systemctl restart #{app}} }
  end
end

describe docker_container('formsender') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'formsender:latest' }
  its('ports') { should eq '0.0.0.0:8085->5000/tcp' }
end

describe http 'http://127.0.0.1:8085/server-status' do
  its('status') { should eq 200 }
end

describe docker.images.where { repository == 'redmine' && tag == '4.1.1' } do
  it { should exist }
end

describe docker_container('code.mulgara.org') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'redmine:4.1.1' }
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
