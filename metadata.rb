name             'osl-app'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
issues_url       'https://github.com/osuosl-cookbooks/osl-app/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-app'
license          'Apache-2.0'
chef_version     '>= 12.18' if respond_to?(:chef_version)
description      'Installs/Configures osl-app'
long_description 'Installs/Configures osl-app'
version          '2.0.4'

supports         'centos', '~> 7.0'

depends          'build-essential'
depends          'firewall'
depends          'git'
depends          'logrotate'
depends          'poise-python'
depends          'osl-nginx'
depends          'osl-nodejs'
depends          'sudo'
depends          'systemd', '< 3.0.0'
depends          'user'
depends          'yum-epel'
