# = Class: wingid
#
# This class installs R and several required packages from CRAN.
#
# == Parameters:
#
# $mirror::     Specifies the URL of your favorite CRAN mirror.
#               See http://cran.r-project.org/mirrors.html
#
# == Requires:
#
# - puppetlabs-apt
#
# == Sample Usage:
#
#   class {'wingid::r':
#     mirror => 'http://cran-mirror.cs.uu.nl',
#   }
#
class wingid::r (
        $mirror = 'http://cran.r-project.org',
    ) {

    include apt

    # Add the CRAN Apt source to /etc/apt/sources.list.d/
    apt::source { "cran":
        location          => "${mirror}/bin/linux/ubuntu",
        release           => "${::lsbdistcodename}/",
        repos             => "",
        required_packages => "debian-keyring debian-archive-keyring",
        key               => "E084DAB9",
        key_server        => "keyserver.ubuntu.com",
        pin               => "1000",
        include_src       => false
	}

    exec { "apt-get update":
        command => "apt-get update",
    }

	package {
        "r-base": ensure => latest;
        "r-base-dev": ensure => latest;
        "r-recommended": ensure => latest;
        "build-essential": ensure => present;
    }

    # Install R packages.
    cran::package{'rgl': ensure => present}
    cran::package{'mass': ensure => present}
    cran::package{'geomorph': ensure => present}

}
