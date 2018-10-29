# This defined type manages symbolic links to mediawiki configuration files.
# WARNING: Only for internal use!
#
# @param conf_dir directory which contains all mediawiki instannce directories
# @param install_files an array of mediawiki installation files
# @param target_dir mediawiki installation directory
#
# @example usage
#   mediawiki::symlinks { $name:
#     conf_dir      => $mediawiki_conf_dir,
#     install_files => $mediawiki_install_files,
#     target_dir    => $mediawiki_install_dir,
#   }
#
# @author Martin Dluhos <martin@gnu.org>
#
# Copyright 2012 Martin Dluhos
#
define mediawiki::symlinks (
  $conf_dir,
  $install_files,
  $target_dir
  ) {
  
  # Generate an array of symlink names
  $link_files = regsubst($install_files, "^.*$", "${conf_dir}/${name}/\\0", "G")   
  mediawiki::files { $link_files:
    target_dir => $target_dir,
  }
}
