name             'osl-app'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
issues_url       'https://github.com/osuosl-cookbooks/osl-app/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-app'
license          'Apache-2.0'
chef_version     '>= 16.0'
description      'Installs/Configures osl-app'
version          '4.10.1'

supports         'almalinux', '~> 8.0'
supports         'almalinux', '~> 9.0'

depends          'htpasswd'
depends          'osl-docker'
depends          'osl-firewall'
depends          'osl-git'
depends          'osl-nginx'
depends          'users', '~> 8.0'
