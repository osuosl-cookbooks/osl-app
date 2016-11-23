name             'osl-app'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
issues_url       'https://github.com/osuosl-cookbooks/osl-app/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-app'
license          'apache2'
description      'Installs/Configures osl-app'
long_description 'Installs/Configures osl-app'
version          '1.9.4'

supports         'centos', '~> 7.0'

depends          'build-essential'
depends          'firewall'
depends          'git'
depends          'poise-python'
depends          'nodejs'
depends          'sudo'
depends          'user'
depends          'systemd'
depends          'yum-epel'
