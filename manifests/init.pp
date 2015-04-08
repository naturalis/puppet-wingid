# = Class: wingid
#
# This class installs an Apache Virtual Host for the WingID Django app.
#
# == Parameters:
#
# $domain::     Specifies the server name for the virtual host.
# $site_root::  Specifies the path to the root of the Django site.
# $site_name::  Specifies the name of the Django site. This is the name of the
#               directory containing the site's settings.py.
# $venv_path::  Specifies the path to the Python virtualenv directory where all
#               requirements are installed.
#
# == Requires:
#
# - puppetlabs-apache
# - stankevich-python
#
# == Sample Usage:
#
#   class {'wingid':
#     domain => 'wing-id.naturalis.nl',
#     site_root => '/srv/www/wingid/htdocs',
#     site_name => 'mysite',
#     venv_path => '/srv/www/wingid/htdocs/env',
#   }
#
class wingid (
        $domain = 'wing-id.naturalis.nl',
        $site_root,
        $site_name,
        $venv_path,
    ) {

    file { $site_root:
        ensure => present,
    }

    package { 'python-numpy':
        ensure => present,
    }

    # Install Python and friends.
    class { 'python' :
        version    => 'system',
        pip        => true,
        dev        => true,
        virtualenv => true,
        gunicorn   => false,
    }

    # Setup the Python virtualenv for WingID.
    python::virtualenv { $venv_path :
        ensure       => present,
        version      => 'system',
        requirements => "${site_root}/wingid/requirements.txt",
        systempkgs   => true,
        distribute   => true,
        owner        => 'www-data',
        group        => 'www-data',
        timeout      => 0,
    }

    # Install and configure Apache.
    class { 'apache':
        package_ensure => present,
        default_mods => true,
        default_confd_files => true,
        purge_configs => true,
    }

    # Set up the virtual host.
    apache::vhost { $domain:
        port => '80',
        aliases => [
            { alias => '/media/', path => "${site_root}/media/" },
            { alias => '/static/admin/', path => "${site_root}/${site_name}/static/admin/" },
            { alias => '/static/rest_framework/', path => "${site_root}/${site_name}/static/rest_framework/" },
            { alias => '/static/', path => "${site_root}/wingid/static/" },
        ],

        # Configure WSGI.
        wsgi_application_group      => '%{GLOBAL}',
        wsgi_daemon_process         => 'wingid',
        wsgi_daemon_process_options => {
            display-name => '%{GROUP}',
            deadlock-timeout => '10',
            python-path => "${site_root}:${$venv_path}/lib/python2.7/site-packages",
        },
        wsgi_import_script_options  => {
            process-group => 'wingid',
            application-group => '%{GLOBAL}'
        },
        wsgi_process_group          => 'wingid',
        wsgi_script_aliases         => {
            '/' => "${site_root}/${site_name}/wsgi.py"
        },
        wsgi_pass_authorization => 'On',
    }

}
