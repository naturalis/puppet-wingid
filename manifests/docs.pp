# = Class: wingid::docs
#
# This class builds and installs the WingID documentation.
#
# == Parameters:
#
# $sourcedir::  Specifies the path to the Sphinx docs source directory.
# $outdir::     Specifies the target build directory for the documentation.
#
# == Requires:
#
#
# == Sample Usage:
#
#   class { 'wingid::docs' :
#     sourcedir => '/opt/wingid/docs',
#     outdir => '/var/www/wingid/docs',
#   }
#
class wingid::docs (
        $sourcedir,
        $outdir,
    ) {

    package {
        'python-sphinx':
            require => Exec['apt_update'],
            ensure => present;
    }

    exec {
        'wingid_make_docs':
            require => [
                Package['python-sphinx'],
                File[$outdir],
            ],
            command => "/usr/bin/sphinx-build -b html ${sourcedir} ${outdir}",
            cwd     => $sourcedir;
    }

    file {
        $outdir:
            ensure => directory;
    }
}
