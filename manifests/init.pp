class wingid ( $site_root, $site_name ) {

    # Install Apache
    class { 'apache':
      default_mods        => false,
      default_confd_files => false,
    }

    # Set up the virtual host
    apache::vhost { 'wing-id.naturalis.nl':
        port => '80',
        aliases => [
            { alias => '/media/', path => "${site_root}/media/" },
            { alias => '/static/admin/', path => "${site_root}/${site_name}/static/admin/" },
            { alias => '/static/rest_framework/', path => "${site_root}/${site_name}/static/rest_framework/" },
            { alias => '/static/', path => "${site_root}/wingid/static/" },
        ],

        # WSGI
        wsgi_application_group      => '%{GLOBAL}',
        wsgi_daemon_process         => 'wingid',
        wsgi_daemon_process_options => {
            display-name => '%{GROUP}',
            deadlock-timeout => '10',
            python-path => "${site_root}:${site_root}/env/lib/python2.7/site-packages",
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
