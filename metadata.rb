name             'osl-app'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
issues_url       'https://github.com/osuosl-cookbooks/osl-app/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-app'
license          'Apache-2.0'
chef_version     '>= 14.0'
description      'Installs/Configures osl-app'
version          '2.8.2'

supports         'centos', '~> 7.0'
supports         'centos', '~> 8.0'

depends          'base'
depends          'firewall'
depends          'git'
depends          'logrotate'
depends          'osl-docker'
depends          'osl-mysql'
depends          'osl-nginx'
depends          'osl-nodejs'
depends          'systemd', '~> 3.2.4'
depends          'user'
depends          'yum-epel'
