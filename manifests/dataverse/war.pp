class iqss::dataverse::war {

# We only need maven for the development environment
  if $iqss::dataverse::repository == 'local' {

    archive { 'maven3':
      ensure           => present,
      url              => 'ftp://mirror.reverse.net/pub/apache/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.zip',
      target           => '/usr/src', # Just a temporary place.
      follow_redirects => true,
      extension        => 'zip',
      checksum         => false,
    }->exec { 'copy maven3':
      command => '/usr/bin/rsync -av /usr/src/apache-maven-3.3.3/ /usr/share/maven',
      creates => '/usr/share/maven';
    }

    file {
      '/usr/bin/mvn':
        ensure => link,
        target => '/usr/share/maven/bin/mvn';
      '/usr/bin/mvnDebug':
        ensure => link,
        target => '/usr/share/maven/bin/mvnDebug';
    }

    package {
      'git':
        ensure => present;
    }

    file {
      '/dataverse':
        ensure => directory ;
    }->exec {
      'clone the repository':
        command => '/usr/bin/git clone git@github.com:IQSS/dataverse.git',
        cwd     => '/dataverse' ;
    }

    exec {
      'build the war': # We assume as we run 'local' this is the root of the code base in /dataverse
        command => "/usr/bin/mvn clean package && rsync -av /dataverse/target/${dataverse_filename} /usr/src/dataverse.war",
        cwd     => '/dataverse'
    }

  } else {

    exec {
      'Download the file': # Note that if this download fails, the file is corrupt. Remove it then.
        command => "/usr/bin/wget -O /usr/src/dataverse.war $iqss::dataverse::repository",
        unless  => "/usr/bin/test -f /usr/src/dataverse.war" ;
    }

  }


# For the console API command handling.
  include jq

  file {
    '/usr/bin/jq':
      ensure => link,
      target => '/usr/local/bin/jq',
  }

  file {
    '/opt/dataverse':
      ensure  => file,
      recurse => true,
      source  => 'puppet:///modules/iqss/dataverse';
  }

}