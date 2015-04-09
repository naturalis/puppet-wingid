# = Class: wingid
#
# This class installs an Apache Virtual Host for the WingID Django app.
#
# == Parameters:
#
# $domain::     Specifies the server name for the virtual host.
# $doc_root::   Specifies the virtual host's document root. $site_root may not
#               be contained in this directory.
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
#     doc_root => '/var/www/wingid',
#     site_root => '/opt/wingid/django',
#     site_name => 'mysite',
#     venv_path => '/opt/wingid/django/env',
#   }
#
class wingid (
        $domain = 'wing-id.naturalis.nl',
        $doc_root = '/var/www/wingid',
        $site_root,
        $site_name,
        $venv_path,
    ) {

    # Construct paths.
    $media_path = "${site_root}/media/"
    $static_admin_path = "${site_root}/${site_name}/static/admin/"
    $static_rest_path = "${site_root}/${site_name}/static/rest_framework/"
    $static_path = "${site_root}/wingid/static/"

    # Install packages.
    package {
        'python-numpy': ensure => present;
        'python-pil': ensure => present;
        'python-memcache': ensure => present;
    }

    # Directories and symbolic links.
    file {
        $doc_root:
            ensure => directory,
            owner => 'www-data',
            group => 'www-data';
        $media_path:
            ensure => directory,
            owner => 'www-data',
            group => 'www-data';
        "${site_root}/${site_name}/static/":
            ensure => directory;
        $static_admin_path:
            ensure => link,
            target => "${venv_path}/lib/python2.7/site-packages/django/contrib/admin/static/admin/";
        $static_rest_path:
            ensure => link,
            target => "${venv_path}/lib/python2.7/site-packages/rest_framework/static/rest_framework/";
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
    }

    # Install and configure Apache.
    class { 'apache':
        package_ensure => present,
        default_vhost => false,
        default_mods => true,
        default_confd_files => true,
        purge_configs => true,
    }

    # Set up the virtual host.
    apache::vhost { $domain:
        require => File[$doc_root],
        docroot => $doc_root,
        port => '80',
        aliases => [
            { alias => '/media/', path => $media_path },
            { alias => '/static/admin/', path => $static_admin_path },
            { alias => '/static/rest_framework/', path => $static_rest_path },
            { alias => '/static/', path => $static_path },
        ],
        directories => [
            {
                'path'     => $doc_root,
                'provider' => 'directory',
            },
            {
                'path'     => $media_path,
                'provider' => 'directory',
            },
            {
                'path'     => $static_admin_path,
                'provider' => 'directory',
            },
            {
                'path'     => $static_rest_path,
                'provider' => 'directory',
            },
            {
                'path'     => $static_path,
                'provider' => 'directory',
            },
            {
                'path'     => "${site_root}/${site_name}/wsgi.py",
                'provider' => 'files',
            },
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
