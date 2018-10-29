# This defined type manages symbolic links to mediawiki configuration files.
# WARNING: Only for internal use!
#
# @param target_dir mediawiki installation directory
#
# @example usage
#   mediawiki::files { $link_files:
#     target_dir => $target_dir,
#   }
#
# @author Martin Dluhos <martin@gnu.org>
#
# Copyright 2012 Martin Dluhos
#
define mediawiki::files (
  $target_dir
  ) {
  file { $name:
    ensure  => link,
    owner   => "${mediawiki::params::apache_user}",
    group   => "${mediawiki::params::apache_user}",
    mode    => '0755',
    target  => gen_target_path($target_dir, $name),
  }
}
