# === Class: mediawiki::params
#
#  The mediawiki configuration settings idiosyncratic to different operating
#  systems.
#
# === Parameters
#
# None
#
class mediawiki::params {

  $tarball_url        = 'http://releases.wikimedia.org/mediawiki/1.31/mediawiki-1.31.1.tar.gz'
  $mediawiki_dir = regsubst($tarball_url, '^.*?/(mediawiki-\d\.\d+\.\d+).*$', '\1')
  $conf_dir           = '/etc/mediawiki'
  $installation_files = ['api.php',
                         'autoload.php',
                         'CODE_OF_CONDUCT.md',
                         'composer.json',
                         'composer.local.json-sample',
                         'COPYING',
                         'CREDITS',
                         'docs',
                         'extensions',
                         'FAQ',
                         'Gruntfile.js',
                         'HISTORY',
                         'img_auth.php',
                         'includes',
                         'index.php',
                         'INSTALL',
                         'jsduck.json',
                         'languages',
                         'load.php',
                         'maintenance',
                         'mw-config',
                         'opensearch_desc.php',
                         'profileinfo.php',
                         'README',
                         'resources',
                         'SECURITY',
                         'serialized',
                         'skins',
                         'StartProfiler.sample',
                         'tests',
                         'thumb_handler.php',
                         'thumb.php',
                         'UPGRADE',
                         'vendor']

  case $::operatingsystem {
    'Redhat', 'CentOS':  {
      $web_dir            = '/var/www/html'
      $doc_root           = "${web_dir}/wikis"
      $packages           = ['php-gd', 'php-mysql', 'php-xml', 'wget', 'php-pecl-apcu', 'php-intl']
      $apache             = 'apache'
    }
    'Debian', 'Ubuntu':  {
      $web_dir            = '/var/www'
      $doc_root           = "${web_dir}/wikis"
      $packages           = ['php', 'php-mysql', 'wget', 'php-mail', 'php-gd', 'php-intl', 'php-common', 'php-mbstring', 'php-xml', 'php-curl']
      $apache             = 'apache2'
      $apache_user        = 'www-data'
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }
  $mediawiki_install_path = "${web_dir}/${mediawiki_dir}"
}
