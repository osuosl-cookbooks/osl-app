require_relative 'spec_helper'

describe 'osl-app::default' do
  cached(:chef_run) do
    ChefSpec::SoloRunner.new(CENTOS_7).converge('sudo', described_recipe)
  end

  include_context 'common_stubs'

  it do
    expect { chef_run }.to_not raise_error
  end

  it do
    expect(chef_run).to include_recipe 'yum-epel::default'
  end

  it do
    expect(chef_run).to include_recipe 'osl-mysql::client'
  end

  it do
    %w(
      automake
      freetype-devel
      gdal-python
      geos-python
      ImageMagick-devel
      libffi-devel
      libjpeg-turbo-devel
      libpng-devel
      libtool
      libyaml-devel
      openssl-devel
      postgis
      postgresql-devel
      proj
      proj-nad
      python-psycopg2
      readline-devel
      sqlite-devel
      zlib-devel
    ).each do |p|
      expect(chef_run).to install_package(p)
    end
  end

  it do
    expect(chef_run).to install_python_runtime('2')
  end

  it do
    expect(chef_run).to create_directory('/etc/systemd/system').with(mode: 0750)
  end
end
