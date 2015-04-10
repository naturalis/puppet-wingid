class { 'wingid' :
    domain => 'wingid.example.com',
    doc_root => '/var/www/wingid',
    site_root => '/opt/wingid/django',
    site_name => 'website',
    venv_path => '/opt/wingid/django/env',
    cran_mirror => 'http://cran.sciserv.eu',
}

class { 'wingid::docs' :
    sourcedir => '/opt/wingid/docs',
    outdir => '/var/www/wingid/docs',
}
