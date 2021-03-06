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
#     mirror => 'http://cran.sciserv.eu',
#   }
#
class wingid::cran (
        $mirror = 'http://cran.r-project.org',
    ) {

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

    # Install R.
    class { 'r':
        require => Apt::Source['cran']
    }

    # Install R packages from the CRAN Ubuntu repository.
    package {
        'build-essential':
            require => Exec['apt_update'],
            ensure => present;
        'r-base-dev':
            ensure => latest,
            require => Class['r'];
        'r-recommended':
            ensure => latest,
            require => Class['r'];
        'r-cran-rgl':
            ensure => present,
            require => Class['r'];
        'r-cran-mass':
            ensure => present,
            require => Class['r'];
    }

    # Install R packages that cannot be installed from the CRAN Ubuntu
    # repository. These are obtained directly from CRAN and may need to be
    # compiled.
    r::package { 'geomorph':
        require => [
            Class['r'],
            Package['build-essential']
        ],
        repo => $mirror,
        dependencies => true,
    }

}
