# This defined type allows the user to create a mediawiki instance.
#
# @param db_name name of the mediawiki instance mysql database
# @param db_user name of the mysql database user
# @param db_password password for the mysql database user
# @param ip ip address of the mediawiki web server
# @param port port on mediawiki web server
# @param server_aliases an array of mediawiki web server aliases
# @param ensure the current status of the wiki instance.
#                       Options: present, absent, deleted
# @param db_prefix prefix of the table names for the instance database.
#                       Defaults to +wk+
# @param allow_html_email whether html is allowed in email
# @param additional_mail_params not used at the moment
# @param logo_url the logo url or pathname where '/' is the root directory of the wiki farm
# @param lang_code the language code of the wiki, default to false
# @param enable_uploads enable uploads? Default to false. If true sets up
#   <tt>wgUploadPath</tt> with value <tt>$wgScriptPath/images</tt> and
#   <tt>wgUploadDirectory</tt> with value <tt>$IP/images</tt>
# @param hashed_upload_dir has the upload directory to be hashed? Default to true
# @param external_smtp whether an SMTP server is present and needs to be configurated for sending emails
# @param smtp_idhost the domain name to be used when sending emails
# @param smtp_host where the SMTP server is located; could be an IP address or a fqdn
# @param smtp_port port to use when connecting to the SMTP server
# @param smtp_auth Should we use SMTP authentication (true or false)
# @param smtp_username Username to use for SMTP authentication (if being used)
# @param smtp_password Password to use for SMTP authentication (if being used)
# @param password_sender Password reminder email address
# @param emergency_contact Site admin email address
#
# @example usage
#   class { 'mediawiki':
#     admin_email      => 'admin@puppetlabs.com',
#     db_root_password => 'really_really_long_password',
#     max_memory       => '1024'
#   }
#   mediawiki::instance { 'my_wiki1':
#     db_password => 'really_long_password',
#     db_name     => 'wiki1',
#     db_user     => 'wiki1_user',
#     port        => '80',
#     ensure      => 'present'
#   }
#
# @author Martin Dluhos <martin@gnu.org>
#
# Copyright 2012 Martin Dluhos
#
define mediawiki::instance (
  $db_password,
  $db_name                = $name,
  $db_user                = "${name}_user",
  $db_prefix              = 'wk',
  $ip                     = '*',
  $port                   = '80',
  $server_aliases         = '',
  $ensure                 = 'present',
  $allow_html_email       = 'false',
  $additional_mail_params = 'none',
  $logo_url               = false,
  $lang_code              = false,
  $enable_uploads         = false,
  $hashed_upload_dir      = true,
  $external_smtp          = false,
  $smtp_idhost=undef,
  $smtp_host=undef,
  $smtp_port=undef,
  $smtp_auth=false,
  $smtp_username='',
  $smtp_password='',
  $password_sender='apache@localhost',
  $emergency_contact='apache@localhost',
  ) {

  validate_re($ensure, '^(present|absent|deleted)$',
  "${ensure} is not supported for ensure.
  Allowed values are 'present', 'absent', and 'deleted'.")

  include mediawiki::params

  # MediaWiki needs to be installed before a particular instance is created
  Class['mediawiki'] -> Mediawiki::Instance[$name]

  # Make the configuration file more readable
  $admin_email             = $mediawiki::admin_email
  $db_root_password        = $mediawiki::db_root_password
  $server_name             = $mediawiki::server_name
  $doc_root                = $mediawiki::doc_root
  $mediawiki_install_path  = $mediawiki::mediawiki_install_path
  $mediawiki_conf_dir      = $mediawiki::params::conf_dir
  $mediawiki_install_files = $mediawiki::params::installation_files

  if $external_smtp {
    if ! $smtp_idhost   { fail("'smtp_idhost' required when 'external_smtp' is true.") }
    if ! $smtp_host     { fail("'smtp_host' required when 'external_smtp' is true.") }
    if ! $smtp_port     { fail("'smtp_port' required when 'external_smtp' is true.") }
    if $smtp_auth     {
      if ! $smtp_username { fail("'smtp_username' required when 'smtp_auth' is true.") }
      if ! $smtp_password { fail("'smtp_password' required when 'smtp_auth' is true.") }
	  }
    $smtp_settings = "array('host' => \"${smtp_host}\", 'IDHost' => \"${smtp_idhost}\", 'localhost' => \"${::hostname}.${smtp_idhost}\", 'port' => 25, 'auth' => ${smtp_auth}, 'username' => \"${smtp_username}\", 'password' => \"${smtp_password}\");"
  } else {
    $smtp_settings = "false;"
  }

  # Figure out how to improve db security (manually done by
  # mysql_secure_installation)
  case $ensure {
    'present', 'absent': {

      exec { "${name}-install_script":
        cwd         => "${mediawiki_install_path}/maintenance",
        command     => "/usr/bin/php install.php ${name} admin    \
                        --pass puppet                             \
                        --email ${admin_email}                    \
                        --server http://${server_name}            \
                        --scriptpath /${name}                     \
                        --dbtype mysql                            \
                        --dbserver localhost                      \
                        --installdbuser root                      \
                        --installdbpass ${db_root_password}       \
                        --dbname ${db_name}                       \
                        --dbuser ${db_user}                       \
                        --dbpass ${db_password}                   \
                        --dbprefix ${db_prefix}                   \
                        --confpath ${mediawiki_conf_dir}/${name}  \
                        --lang en",
        creates     => "${mediawiki_conf_dir}/${name}/LocalSettings.php",
        subscribe   => File["${mediawiki_conf_dir}/${name}/images"],
      }

      # Ensure resource attributes common to all resources
      File {
        ensure => directory,
        owner  => "${mediawiki::params::apache_user}",
        group  => "${mediawiki::params::apache_user}",
        mode   => '0755',
      }

      # MediaWIki Custom Logo
      if $logo_url {
        file_line{"${name}_logo_url":
          path  =>  "${mediawiki_conf_dir}/${name}/LocalSettings.php",
          line  =>  "\$wgLogo = '${logo_url}';",
          match =>  '\$wgLogo =.*',
          subscribe => Exec["${name}-install_script"],
        }
      }

      # MediaWIki language code
      if $lang_code {
        file_line{"${name}_lang_code":
          path  =>  "${mediawiki_conf_dir}/${name}/LocalSettings.php",
          line  =>  "\$wgLanguageCode = '${lang_code}';",
          match =>  '\$wgLanguageCode =.*',
          subscribe => Exec["${name}-install_script"],
        }
      }

      # MediaWIki uploads enabling
      if $enable_uploads {
        file_line{"${name}_enable_uploads":
          path  =>  "${mediawiki_conf_dir}/${name}/LocalSettings.php",
          line  =>  "\$wgEnableUploads = ${enable_uploads};",
          match =>  '\$wgEnableUploads =.*',
          subscribe => Exec["${name}-install_script"],
        }
        file_line{"${name}_upload_path":
          path  =>  "${mediawiki_conf_dir}/${name}/LocalSettings.php",
          line  =>  '$wgUploadPath = "$wgScriptPath/images";',
          match =>  '\$wgUploadPath =.*',
          subscribe => Exec["${name}-install_script"],
        }
        file_line{"${name}_upload_directory":
          path  =>  "${mediawiki_conf_dir}/${name}/LocalSettings.php",
          line  =>  '$wgUploadDirectory = "$IP/images";',
          match =>  '\$wgUploadDirectory =.*',
          subscribe => Exec["${name}-install_script"],
        }
      }

      # MediaWIki upload directory hashing
      if ! $hashed_upload_dir {
        file_line{"${name}_hashed_upload_dir":
          path  =>  "${mediawiki_conf_dir}/${name}/LocalSettings.php",
          line  =>  "\$wgHashedUploadDirectory = ${hashed_upload_dir};",
          match =>  '\$wgHashedUploadDirectory =.*',
          subscribe => Exec["${name}-install_script"],
        }
      }

      # SMTP settings
      file_line{"${name}_smtp":
        path  =>  "${mediawiki_conf_dir}/${name}/LocalSettings.php",
        line  =>  "\$wgSMTP = ${smtp_settings}",
        match =>  '\$wgSMTP =.*',
        subscribe => Exec["${name}-install_script"],
      }

      # Emergency contact
      file_line{"${name}_emergency_contact":
        path  =>  "${mediawiki_conf_dir}/${name}/LocalSettings.php",
        line  =>  "\$wgEmergencyContact = '${emergency_contact}';",
        match =>  '\$wgEmergencyContact =.*',
        subscribe => Exec["${name}-install_script"],
      }

      # Password sender
      file_line{"${name}_password_sender":
        path  =>  "${mediawiki_conf_dir}/${name}/LocalSettings.php",
        line  =>  "\$wgPasswordSender = '${password_sender}';",
        match =>  '\$wgPasswordSender =.*',
        subscribe => Exec["${name}-install_script"],
      }

      # MediaWiki instance directory
      file { "${mediawiki_conf_dir}/${name}":
        ensure   => directory,
      }

#      # MediaWiki DefaultSettings
#      file { "${mediawiki_conf_dir}/${name}/includes/DefaultSettings.php":
#        ensure  =>  present,
#        content =>  template('mediawiki/DefaultSettings.php.erb'),
#      }

      # Each instance needs a separate folder to upload images
      file { "${mediawiki_conf_dir}/${name}/images":
        ensure   => directory,
        group  => "${mediawiki::params::apache_user}",
      }

      # Ensure that mediawiki configuration files are included in each instance.
      mediawiki::symlinks { $name:
        conf_dir      => $mediawiki_conf_dir,
        install_files => $mediawiki_install_files,
        target_dir    => $mediawiki_install_path,
      }

      # Symlink for the mediawiki instance directory
      file { "${doc_root}/${name}":
        ensure   => link,
        target   => "${mediawiki_conf_dir}/${name}",
        require  => File["${mediawiki_conf_dir}/${name}"],
      }

      # Each instance has a separate vhost configuration
      apache::vhost { $name:
        ensure        => $ensure,
        port          => $port,
        docroot       => $doc_root,
        serveradmin   => $admin_email,
        servername    => $server_name,
        vhost_name    => $ip,
        serveraliases => $server_aliases,
      }
    }
    'deleted': {

      # Remove the MediaWiki instance directory if it is present
      file { "${mediawiki_conf_dir}/${name}":
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
      }

      # Remove the symlink for the mediawiki instance directory
      file { "${doc_root}/${name}":
        ensure   => absent,
        recurse  => true,
      }

      mysql::db { $db_name:
        ensure   => 'absent',
        user     => $db_user,
        password => $db_password,
        host     => 'localhost',
        grant    => ['all'],
      }

      apache::vhost { $name:
        ensure        => 'absent',
        port          => $port,
        docroot       => $doc_root,
      }
    }
  }
}
