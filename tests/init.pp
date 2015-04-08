class {'wingid':
    domain => 'wing-id.naturalis.nl',
    doc_root => '/var/www/wingid',
    site_root => '/opt/wingid/django',
    site_name => 'mysite',
    venv_path => '/opt/wingid/django/env',
}