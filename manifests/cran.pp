# = Class: wingid::cran
#
# This class installs R from CRAN and the required R packages for WingID.
#
# == Parameters:
#
# $mirror::     Specifies the URL of your favorite CRAN mirror.
#               See http://cran.r-project.org/mirrors.html
#
# == Requires:
#
# - puppetlabs-apt
# - forward3ddev-r
#
# == Sample Usage:
#
#   class {'wingid::cran':
#     mirror => 'http://cran-mirror.cs.uu.nl',
#   }
#
class wingid::cran (
        $mirror = 'http://cran.r-project.org',
    ) {

    include apt

    # Add the CRAN Apt source to /etc/apt/sources.list.d/
    apt::source { "cran":
        location          => "${mirror}/bin/linux/ubuntu",
        release           => "${::lsbdistcodename}/",
        repos             => "",
        required_packages => "debian-keyring debian-archive-keyring",
        key               => "E298A3A825C0D65DFD57CBB651716619E084DAB9",
        key_server        => "keyserver.ubuntu.com",
        pin               => "1000",
        include_src       => false
    }

    # Udate the repositories after CRAN source was added.
    exec { 'apt_update_cran':
        command => "/usr/bin/apt-get update",
        require => Apt::Source['cran'],
    }

    # Install R. This installs the r-base package.
    class { 'r':
        require => Exec['apt_update_cran']
    }

    # Install R packages from the repository.
    package {
        'build-essential': ensure => present;
        'r-base-dev': ensure => latest, require => Package['r-base'];
        'r-recommended': ensure => latest, require => Package['r-base'];
    }

    # Install R packages from CRAN.
    r::package {
        'rgl': require => [Package['r-base'], Package['build-essential']];
        'mass': require => [Package['r-base'], Package['build-essential']];
        'geomorph': require => [Package['r-base'], Package['build-essential']];
    }

}
