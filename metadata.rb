name             'osl-app'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
license          'apache2'
description      'Installs/Configures osl-app'
long_description 'Installs/Configures osl-app'
version          '1.0.1'

supports         'centos', '~> 7.0'

depends          'build-essential'
depends          'firewall'
depends          'git'
depends          'poise-python'
depends          'nodejs'
depends          'sudo'
depends          'user'
