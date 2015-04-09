class { 'wingid' :
    domain => 'wingid.example.com',
    doc_root => '/var/www/wingid',
    site_root => '/opt/wingid/django',
    site_name => 'mysite',
    venv_path => '/opt/wingid/django/env',
    cran_mirror => 'http://cran.sciserv.eu',
}