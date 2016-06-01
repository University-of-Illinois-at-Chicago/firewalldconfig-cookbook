name             'firewalldconfig'
maintainer       'Johnathan Kupferer'
maintainer_email 'jtk@uic.edu'
license          'Apache v2.0'
description      'Installs/Configures firewalld using configuration files'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.7.1'

depends          'xml'

supports         'fedora', '>= 21.0'
supports         'centos', '>= 7.0'
supports         'rhel', '>= 7.0'
supports         'ubuntu', '>= 14.10'
