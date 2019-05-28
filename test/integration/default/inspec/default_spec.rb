%w(sqlite-devel libyaml-devel readline-devel zlib-devel libffi-devel
   openssl-devel automake libtool python git postgresql-devel gdal-python
   geos-python proj proj-nad freetype-devel libjpeg-turbo-devel
   libpng-devel postgis python-psycopg2).each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

describe command('node --version') do
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
