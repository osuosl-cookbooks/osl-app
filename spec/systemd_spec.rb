require 'chefspec'
require 'chefspec/berkshelf'

describe 'osl-app::systemd' do
  context 'on centos 7.2' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos',
                               version: '7.2.1511').converge(described_recipe)
    end

    before do
      stub_data_bag_item('osl-app', 'openid').and_return(
        secret_key_base: '7eef5c70ecb083192f46e601144f9d77c9b66061b634963a507'\
          '0fb086ae78bc9353af2c6311edb168abbb9d0bd428f800a0b1713534cf4ad239e8d'\
          '07fdd16c34')
    end

    it 'the systemd system folder should not be world readable' do
      expect(chef_run).to create_directory(
        '/etc/systemd/system'
      ).with(mode: 0750)
    end

    %w(openid-staging-unicorn openid-staging-delayed-job
       openid-production-unicorn openid-production-delayed-job).each do |s|
      it "should create system service #{s}" do
        expect(chef_run).to create_systemd_service(s)
      end
    end
  end
end
