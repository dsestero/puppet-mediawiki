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

  $tarball_url        = 'http://releases.wikimedia.org/mediawiki/1.27/mediawiki-1.27.1.tar.gz'
  $mediawiki_dir = regsubst($tarball_url, '^.*?/(mediawiki-\d\.\d+\.\d+).*$', '\1')
  $conf_dir           = '/etc/mediawiki'
  $installation_files = ['api.php',
                         'docs',
                         'extensions',
                         'img_auth.php',
                         'includes',
                         'index.php',
                         'languages',
                         'load.php',
                         'maintenance',
                         'mw-config',
                         'opensearch_desc.php',
                         'profileinfo.php',
                         'resources',
                         'serialized',
                         'skins',
                         'StartProfiler.sample',
                         'tests',
                         'thumb_handler.php',
                         'thumb.php',
                         'vendor',
                         'wiki.phtml']

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
      $packages           = ['php5', 'php5-mysql', 'wget', 'php-mail', 'php5-gd', 'php5-xcache', 'php5-intl']
      $apache             = 'apache2'
      $apache_user        = 'www-data'
    }
    default: {
      fail("Module ${module_name} is not supported on ${::operatingsystem}")
    }
  }
  $mediawiki_install_path = "${web_dir}/${mediawiki_dir}"
}
