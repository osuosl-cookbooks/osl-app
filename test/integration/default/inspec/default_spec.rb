%w(
  automake
  freetype-devel
  geos-devel
  ImageMagick-devel
  libffi-devel
  libjpeg-turbo-devel
  libpng-devel
  libtool
  libyaml
  openssl-devel
  proj
  readline-devel
  sqlite-devel
  zlib-devel
).each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

if os.release.to_i < 8
  %w(postgresql-devel python-psycopg2).each do |p|
    describe package(p) do
      it { should be_installed }
    end
  end
else
  %w(libpq-devel python2-psycopg2).each do |p|
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
