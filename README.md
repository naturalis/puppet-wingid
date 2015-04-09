# Puppet WingID module

This is the [Puppet][1] module for [WingID][2]. This module configures an Ubuntu
server for serving WingID.

## Requirements

This Puppet module was prepared for Ubuntu servers and was tested on Ubuntu
14.04. First install Puppet and the required puppet modules as root:

    apt-get install puppet
    puppet module install puppetlabs-apache
    puppet module install puppetlabs-apt
    puppet module install stankevich-python
    puppet module install forward3ddev-r

This Puppet module does *not* clone the WingID repository for you. You have to
do this yourself:

    git clone https://github.com/naturalis/wingid.git

For convenience, the WingID repository also contains the Django site in the
`django/` directory. On a production server, make sure to change the following
settings in `django/website/settings.py`:

    SECRET_KEY = 'RANDOM_STRING_HERE'
    DEBUG = False
    TEMPLATE_DEBUG = False
    ALLOWED_HOSTS = ['wingid.example.com']

## Install

To install this Puppet module, clone this repository in `/etc/puppet/modules/`
and rename the directory to "wingid" (i.e. `mv puppet-wingid wingid`).

## How to use

Put the following code in a Puppet manifest (e.g. `wingid.pp` or `site.pp`):

    class { 'wingid' :
        domain => 'wingid.example.com',
        doc_root => '/var/www/wingid',
        site_root => '/opt/wingid/django',
        site_name => 'mysite',
        venv_path => '/opt/wingid/django/env',
        cran_mirror => 'http://cran.sciserv.eu',
    }

Change the arguments as required (see the list of parameters below). In the
above example, `/opt/wingid/` is the location where the WingID repository was
cloned.

Finally, trigger the Puppet run as root:

    puppet apply wingid.pp

WingID should now be accessible on the provided domain.

### Class parameters

    $domain::         Specifies the server name that will be used for the virtual
                      host.
    $doc_root::       Specifies the virtual host's document root. $site_root may
                      not be contained in this directory.
    $site_root::      Specifies the path to the root of the existing Django site.
                      The Django site must be created manually before triggering
                      Puppet with this class.
    $site_name::      Specifies the name of the existing Django site. This is the
                      name of the directory containing the site's settings.py.
    $venv_path::      Specifies the path to the Python virtualenv directory where
                      all requirements will be installed.
    $cran_mirror::    Specifies the URL of your favorite CRAN mirror.
                      See http://cran.r-project.org/mirrors.html. Used to install
                      the latest R and required R packages.

[1]: https://puppetlabs.com/puppet/what-is-puppet
[2]: https://github.com/naturalis/wingid
