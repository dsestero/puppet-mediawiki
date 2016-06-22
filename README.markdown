# Mediawiki module for Puppet (forked by dsestero from NexusIS)

####Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with download_uncompress](#setup)
    * [What download_uncompress affects](#what-puppet-mediawiki-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with download_uncompress](#beginning-with-puppet-mediawiki)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

##Overview

This is the mediawiki module. It deploys and manages multiple mediawiki instances using a single installation of the MediaWiki software.

## Module Description

This is the mediawiki module. It deploys and manages multiple mediawiki instances using a single installation of the MediaWiki software. 

This module has been designed and tested for CentOS 6, Red Hat Enterprise Linux 6, Debian Squeeze, Debian Wheezy, and Ubuntu Precise.

This fork from NexusIS/puppet-mediawiki brings several bug fixing and improvement to the module, and is motivated by the fact that NexusIS after a problem occurred to its servers messed the module up, and is little responsive to pull requests. Furthermore, now the module follows the guidelines set by PuppetLabs for publishing modules on PuppetForge.

##Setup

###What puppet-mediawiki affects

The module installs the mysql rdbms, apache web server, most mediawiki suggested packages and the mediawiki package itself; each mediawiki instance configures a database and an apache virtualHost.

The module performs a wget from the (possibly specified) url to get the MediaWiki software.

###Setup Requirements

This modules requires the following other modules to be installed:

* puppetlabs/apache

    in order to configure the mediawiki sites

* puppetlabs/mysql

    in order to set up each mediawiki instance db

* puppetlabs/stdlib

    to use standard functions to validate input and `file_line` resource to manage configuration files
	
* saz/memcached

    in order to improve mediawiki performance by using memcached system (memory caching).

###Beginning with puppet-mediawiki	

To download and unzip SoftwareXY.zip from the base url specified by the key `distributions_base_url` defined in hiera, it is possible to use a declaration as the following:

```
download_uncompress {'dwnl_inst_swxy':
   download_base_url  => "http://jee.invallee.it/dist",
   distribution_name  => "SoftwareXY.zip"
   dest_folder   => '/tmp',
   creates       => "/tmp/SXYInstallFolder",
   uncompress    => 'tar.gz',
}
```




## Usage

First, install the mediawiki package which will be used by all wiki instances:

  class { 'mediawiki':
    server_name      => 'www.example.com',
    admin_email      => 'admin@puppetlabs.com',
    db_root_password => 'really_really_long_password',
    doc_root         => '/var/www/wikis'
    max_memory       => '1024'
  }
    
Next, create an individual wiki instance:

  mediawiki::instance { 'my_wiki1':
    db_password => 'super_long_password',
    db_name     => 'wiki1',
    db_user     => 'wiki1_user',
    port        => '80',
    ensure      => 'present'
  }

Using this module, one can create multiple independent wiki instances. To create another wiki instance, add the following puppet code:

  mediawiki::instance { 'my_wiki2':
    db_password => 'another_super_long_password',
    db_name     => 'another_wiki',
    db_user     => 'another_wiki_user'
    port        => '80',
    ensure      => 'present'
  }

You can now also manage Extensions:

  mediawiki::manage_extension{'ConfirmAccount':
    ensure    =>  present,
    instance  =>  'my_wiki1',
    source    =>  'https://codeload.github.com/wikimedia/mediawiki-extensions-ConfirmAccount/legacy.tar.gz/REL1_22',
    doc_root  =>  '/var/www/wikis', 
    require   =>  Mediawiki::Instance['my_wiki1']
  }


## Preconditions

Since puppet cannot ensure that all parent directories exist you need to
manage these yourself. Therefore, make sure that all parent directories of
`doc_root` directory, an attribute of `mediawiki` class, exist.

## Notes On Testing

Puppet module tests reside in the `spec` directory. To run tests, execute 
`rake spec` anywhere in the module's directory. More information about module 
testing can be found here:

[The Next Generation of Puppet Module Testing](http://puppetlabs.com/blog/the-next-generation-of-puppet-module-testing)

## Reference

This module is based on puppet-mediawiki by martasd available at
https://github.com/martasd/puppet-mediawiki.
