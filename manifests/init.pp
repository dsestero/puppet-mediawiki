# This class includes all resources regarding installation and configuration
# that needs to be performed exactly once and is therefore not mediawiki
# instance specific.
#
# @param server_name the host name of the server
# @param admin_email email address Apache will display when rendering error page
# @param db_root_password password for mysql root user
# @param doc_root the DocumentRoot directory used by Apache
# @param tarball_url the url to fetch the mediawiki tar archive
# @param package_ensure state of the package
# @param max_memory a memcached memory limit
#
# @example usage
# class { 'mediawiki':
#   server_name      => 'www.example.com',
#   admin_email      => 'admin@puppetlabs.com',
#   db_root_password => 'really_really_long_password',
#   max_memory       => '1024'
# }
# mediawiki::instance { 'my_wiki1':
#   db_name     => 'wiki1_user',
#   db_password => 'really_long_password',
# }
#
# @author Martin Dluhos <martin@gnu.org>
#
# Copyright 2012 Martin Dluhos
#
class mediawiki (
  $server_name,
  $admin_email,
  $db_root_password,
  $doc_root       = $mediawiki::params::doc_root,
  $tarball_url    = $mediawiki::params::tarball_url,
  $package_ensure = 'latest',
  $max_memory     = '2048'
  ) inherits mediawiki::params {

  $web_dir = $mediawiki::params::web_dir

  # Parse the url
  $tarball_dir              = regsubst($tarball_url, '^.*?/(\d\.\d+).*$', '\1')
  $tarball_name             = regsubst($tarball_url, '^.*?/(mediawiki-\d\.\d+.*tar\.gz)$', '\1')
  $mediawiki_dir            = regsubst($tarball_url, '^.*?/(mediawiki-\d\.\d+\.\d+).*$', '\1')
  $mediawiki_install_path   = "${web_dir}/${mediawiki_dir}"

  # Specify dependencies
  Class['mysql::server'] -> Class['mediawiki']
  #Class['mysql::config'] -> Class['mediawiki']

  class { 'apache':
    mpm_module => 'prefork',
  }
  class { 'apache::mod::php': }


  # Manages the mysql server package and service by default
  class { 'mysql::server':
    root_password => $db_root_password,
  }

  package { $mediawiki::params::packages:
    ensure  => $package_ensure,
  }
  Package[$mediawiki::params::packages] ~> Service<| title == $mediawiki::params::apache |>

  # Make sure the directories and files common for all instances are included
  file { 'mediawiki_conf_dir':
    ensure  => 'directory',
    path    => $mediawiki::params::conf_dir,
    owner   => "${mediawiki::params::apache_user}",
    group   => "${mediawiki::params::apache_user}",
    mode    => '0755',
    require => Package[$mediawiki::params::packages],
  }

#  file { 'deploy-composer-installer':
#    ensure  => 'present',
#    path    => '/usr/local/bin/install-composer.sh',
#    mode    => '0755',
#    source => "puppet:///modules/${module_name}/install-composer.sh",
#    require => Package[$mediawiki::params::packages],
#  }

#  exec { 'install-composer':
#    cwd       => $web_dir,
#    command   => "/usr/local/bin/install-composer.sh",
#    creates   => $mediawiki_install_path,
#    subscribe => Exec['get-mediawiki'],
#    require => File['deploy-composer-installer'],
#  }

  # Download and install MediaWiki from a tarball
  exec { 'get-mediawiki':
    cwd       => $web_dir,
    command   => "/usr/bin/wget ${tarball_url}",
    creates   => "${web_dir}/${tarball_name}",
    subscribe => File['mediawiki_conf_dir'],
  }

  exec { 'unpack-mediawiki':
    cwd       => $web_dir,
    command   => "/bin/tar -xvzf ${tarball_name}",
    creates   => $mediawiki_install_path,
    subscribe => Exec['get-mediawiki'],
  }

  exec { 'make-executable-pygmentize':
    cwd         => $web_dir,
    command     => "/bin/chmod a+x ${mediawiki_install_path}/extensions/SyntaxHighlight_GeSHi/pygments/pygmentize",
    unless      => "if [ `stat -c %A ${mediawiki_install_path}/extensions/SyntaxHighlight_GeSHi/pygments/pygmentize | cut -c10` == 'x' ]",
    subscribe   => Exec['unpack-mediawiki'],
    refreshonly => true,
  }

  #  exec { 'fetch-required-php-libraries':
#    cwd       => $web_dir,
#    command   => '/usr/local/bin/composer.phar install --no-dev',
#    creates   => $mediawiki_install_path,
#    subscribe => [Exec['get-mediawiki'], Exec['install-composer']],
#  }

  class { 'memcached':
    max_memory => $max_memory,
    max_connections => '1024',
  }
}



define mediawiki::manage_extension(
  $ensure,
  $instance,
  $source,
  $doc_root
){
  $extension = $name
  $line = "wfLoadExtension( '${extension}' );"
  $path = "${doc_root}/${instance}/LocalSettings.php"

  mediawiki_extension { $extension:
    ensure    =>  present,
    instance  =>  $instance,
    source    =>  $source,
    doc_root  =>  $doc_root,
    notify  =>  Exec["set_${extension}_perms"],
  }

  file_line{"${extension}_include":
    ensure  =>  $ensure,
    line    =>  $line,
    path    =>  $path,
    require =>  Mediawiki_extension["${extension}"],
    notify  =>  Exec["set_${extension}_perms"],
  }

  File_line["${extension}_include"] ~> Service<| title == $mediawiki::params::apache |>

  exec{"set_${extension}_perms":
    command     =>  "/bin/chown -R ${apache::params::user}:${apache::params::user} ${doc_root}/${instance}",
    refreshonly =>  true,
    notify  =>  Exec["set_${extension}_perms_two"],
  }
  exec{"set_${extension}_perms_two":
    command     =>  "/bin/chown -R ${mediawiki::params::apache_user}:${mediawiki::params::apache_user} ${mediawiki::params::conf_dir}/${instance}",
    refreshonly =>  true,
    notify  =>  Exec["set_${extension}_perms_three"],
  }
  exec{"set_${extension}_perms_three":
    command     =>  "/bin/chown -R ${mediawiki::params::apache_user}:${mediawiki::params::apache_user} ${mediawiki::params::mediawiki_install_path}",
    refreshonly =>  true
  }
}
