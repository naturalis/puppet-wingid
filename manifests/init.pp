# = Class: wingid
#
# This module configures an Ubuntu server for serving WingID.
#
# == Parameters:
#
# $domain::         Specifies the server name that will be used for the virtual
#                   host.
# $doc_root::       Specifies the virtual host's document root. $site_root may
#                   not be contained in this directory.
# $site_root::      Specifies the path to the root of the existing Django site.
#                   The Django site must be created manually before triggering
#                   Puppet with this class.
# $site_name::      Specifies the name of the existing Django site. This is the
#                   name of the directory containing the site's settings.py.
# $venv_path::      Specifies the path to the Python virtualenv directory where
#                   all requirements will be installed.
# $cran_mirror::    Specifies the URL of your favorite CRAN mirror.
#                   See http://cran.r-project.org/mirrors.html. Used to install
#                   the latest R and required R packages.
#
# == Requires:
#
# - puppetlabs-apt
# - puppetlabs-apache
# - stankevich-python
# - forward3ddev-r
#
# == Sample Usage:
#
#   class {'wingid':
#     domain => 'wingid.example.com',
#     doc_root => '/var/www/wingid',
#     site_root => '/opt/wingid/django',
#     site_name => 'mysite',
#     venv_path => '/opt/wingid/django/env',
#     cran_mirror => 'http://cran.sciserv.eu',
#   }
#
class wingid (
        $domain = 'wingid.example.com',
        $doc_root = '/var/www/wingid',
        $site_root,
        $site_name,
        $venv_path,
        $cran_mirror = 'http://cran.r-project.org',
    ) {

    # Construct paths (must have trailing spaces).
    $media_path = "${site_root}/media/"
    $static_admin_path = "${site_root}/${site_name}/static/admin/"
    $static_rest_path = "${site_root}/${site_name}/static/rest_framework/"
    $static_path = "${site_root}/wingid/static/"

    class { 'apt':
        apt_update_frequency => always,
    }

    # Run apt-get update.
    include apt::update

    # Enable unattended upgrades.
    class { 'apt::unattended_upgrades': }


    class {
        # Geomorph requires R >= 3.1.0; install R and the geomorph package from
        # CRAN because Ubuntu comes with an older R version.
        'wingid::cran':
            mirror => $cran_mirror;

        # Install Python and friends.
        'python':
            version    => 'system',
            pip        => true,
            dev        => true,
            virtualenv => true,
            gunicorn   => false;

        # Install Apache.
        'apache':
            package_ensure      => present,
            default_vhost       => false,
            default_mods        => true,
            default_confd_files => true,
            purge_configs       => true;
    }

    # Ubuntu 14.04 comes with outdated versions of these packages. They will be
    # downloaded and compiled while setting up the Python virtualenv.
    apt::builddep {
        'python-sorl-thumbnail':;
    }

    # Install packages.
    package {
        'python-numpy':
            ensure => present;
        'python-pil':
            ensure => present;
        'memcached':
            ensure => present;
        'python-memcache':
            ensure => present;
    }

    exec {
        # Create the SQLite database for WingID.
        'wingid_migrate':
            require => Python::Virtualenv[$venv_path],
            command => "${venv_path}/bin/python manage.py migrate",
            cwd     => $site_root,
            creates => "${site_root}/db.sqlite3";
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

        $site_root:
            ensure => directory,
            mode => 'g+rwx',
            group => 'www-data';

        "${site_root}/${site_name}/static/":
            ensure => directory;

        $static_admin_path:
            ensure => link,
            target => "${venv_path}/lib/python2.7/site-packages/django/contrib/admin/static/admin/";

        $static_rest_path:
            ensure => link,
            target => "${venv_path}/lib/python2.7/site-packages/rest_framework/static/rest_framework/";

        "${site_root}/db.sqlite3":
            require => Exec['wingid_migrate'],
            ensure => file,
            mode => 'g+rw',
            group => 'www-data';
    }

    # Setup the Python virtualenv for WingID.
    python::virtualenv { $venv_path :
        require      => [
            Apt::Builddep['python-sorl-thumbnail'],
            Class['wingid::cran'],
            Package['python-numpy'],
            Package['python-pil'],
            Package['memcached'],
            Package['python-memcache'],
        ],
        ensure       => present,
        version      => 'system',
        requirements => "${site_root}/wingid/requirements.txt",
        systempkgs   => true,
        distribute   => true,
    }

    # Set up the virtual host.
    apache::vhost { $domain:
        require => [
            File[$doc_root],
            Exec['wingid_migrate'],
        ],
        docroot => $doc_root,
        port => '80',
        aliases => [
            { alias => '/media/', path => $media_path },
            { alias => '/static/admin/', path => $static_admin_path },
            { alias => '/static/rest_framework/', path => $static_rest_path },
            { alias => '/static/', path => $static_path },
            { alias => '/docs/', path => "${doc_root}/docs/" },
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
