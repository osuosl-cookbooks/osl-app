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
when 8
  %w(
    freetype-devel
    libjpeg-turbo-devel
    libpng-devel
    proj
    python3-gdal
    python3-psycopg2
  ).each do |p|
    describe package(p) do
      it { should be_installed }
    end
  end
end

describe command('/usr/local/bin/node --version') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match(/v6\.9\.1/) }
end

describe file('/etc/systemd/system') do
  it { should be_directory }
  its('mode') { should cmp '0750' }
end

describe file('/etc/sudoers') do
  it { should be_file }
  its('content') { should match(%r{#includedir \/etc\/sudoers\.d}) }
end

describe iptables do
  it { should have_rule '-A unicorn -p tcp -m tcp --dport 8080:9000 -j osl_only' }
end

describe ip6tables do
  it { should have_rule '-A unicorn -p tcp -m tcp --dport 8080:9000 -j osl_only' }
end
