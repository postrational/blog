---
title: Setting up Django in Virtualenv on WebFaction's Apache with mod_wsgi
date: 2013-09-14T19:00:00
slug: django-in-virtualenv-on-webfactions-apache-with-mod-wsgi
layout: post
categories:
  - tech
tags:
  - django
  - virtualenv
  - webfaction
  - apache
  - mod_wsgi
comments: true
draft: true
---

If you want to run a Django application on [WebFaction](http://www.webfaction.com?affiliate=postrational), you may simply use their automatic application creation scripts. Unfortunately, if you want to place your application in a Virtualenv, the automatic installer will not help you. I'm sure that WebFaction will eventually add an  installer to set this up, but for now, you can use the following tutorial. In this text we set up a Django project in a Virtualenv running on WebFaction's Apache with mod_wsgi.

<!-- more -->

### Create a new application

Let's begin by setting up a generic `mod_wsgi` application in your WebFaction control panel. Log into the control panel, choose the option to [add a new application](https://my.webfaction.com/new-application) and specify the following settings:

* Name: `test_app`
* App category: `mod_wsgi `
* App type : `mod_wsgi 3.4 / Python 2.7`

The new application will be created in your home directory (`~`) under: `~/webapps/test_app`. 

The directory will contain two subdirectories: 

* `apache2` - contains the Apache configuration files (`apache2/conf`) and scripts which let you control the server (`apache2/bin`)
* `htdocs` - contains default page files. 

Configure a [new website](https://my.webfaction.com/new-website) to hook up your application to a domain. Test the website by visiting it in your browser. You should be greeted by a message beginning with the following text:

    Welcome to your mod_wsgi website! It uses: Python 2.7....

If you see the above, then the generic application is set up correctly and we can proceed to turn it into a Virtualenv Django application.

### Remove htdocs

The `htdocs` directory will not be needed, so feel free to remove it.

    $ cd ~/webapps/test_app
    $ rm -r htdocs

### Install Virtualenv

Check if Virtualenv is installed on your server:

    $ virtualenv --version
    -bash: virtualenv: command not found

If Virtualenv is installed, you will see a version number when running the above command. If it's missing you'll see a `command not found` error message instead.

Steps to install Vitrualenv on a WebFaction server are the following:

    $ mkdir -p ~/lib/python2.7/
    $ easy_install-2.7 pip
    $ pip install virtualenv

If you get an permission denied error try this command to install virtualenv inside your user folder:

    $  pip install --user virtualenv

Verify that installation was successful:

    $ virtualenv --version
    1.10.1

### Create a virtual environment

Let's proceed to turn our application directory into a virtual Python environment:

    $ cd ~/webapps/test_app
    $ virtualenv .

This adds the folders and scripts for a virtual environment inside of the directory which WebFaction created for our application.

You can now activate the created environment:

    $ source bin/activate
    (test_app) $


### Install Django and other dependencies

Once the initial Virtualenv setup is complete, you can install Django inside it's `lib/python2.7/site-packages` directory.

    (test_app) $ pip install django
    
Verify that Django installed correctly:

    (test_app) $ django-admin.py --version
    1.5.2

Your project will probably depend on other packages. You can install those from a `REQUIREMENTS.txt` file, which you can generate on your development server with the `pip freeze` command.

    (test_app) $ pip install -r REQUIREMENTS.txt


### Start a Django project

Let's create a new Django project inside the virtual environment:

    (test_app) $ django-admin.py startproject test_django
    
    
### Directory structure

At this stage you should have created a directory structure resembling this:

    ~/webapps/test_app
    |-- apache2
    |   |-- bin
    |   |   |-- httpd
    |   |   |-- httpd.worker
    |   |   |-- restart             <== Scripts which start, stop and restart Apache
    |   |   |-- start
    |   |   `-- stop
    |   |-- conf
    |   |   |-- httpd.conf          <== Apache configuration file
    |   |   `-- mime.types
    |   |-- lib
    |   |-- logs                    <== Apache error log is here
    |   `-- modules
    |-- bin                         <== Virtualenv scipts and binaries
    |   |-- activate                <== Virtualenv activation script
    |   |-- django-admin.py
    |   |-- easy_install
    |   |-- easy_install-2.7
    |   |-- pip
    |   |-- pip-2.7
    |   |-- python -> python2.7
    |   |-- python2 -> python2.7
    |   `-- python2.7
    |-- include
    |-- lib
    |   `-- python2.7
    |       `-- site-packages       <== Virtualenv's Python packages directory
    `-- test_django                 <== Your Django project directory
        |-- manage.py
        `-- test_django
            |-- __init__.py
            |-- settings.py
            |-- urls.py
            `-- wsgi.py             <== WSGI script file which Apache runs through mod_wsgi


### Configure an Apache VirtualHost

We are now ready to configure Apache to serve our Django-powered webapp. In order to do this, we'll need to modify the contents of the Apache configuration file located under `apache2/conf/httpd.conf`. Copy the original file to a backup for reference and make a note of the following values:

* port number on which Apache listens to connections. This value is located in the line with the `Listen` directive of the original `httpd.conf`. In the example below we set this to `12345`,
* name of your application (`test_app`),
* domain name which your website uses (`example.com`),
* complete path to your application's virtualenv and project directory:
`/home/my_username/webapps/test_app` and `/home/my_username/webapps/test_app/test_django`,
* complete path to your application's WSGI script:
`/home/my_username/webapps/test_app/test_django/test_django/wsgi.py`.

Use these values to customize the configuration template below and save it as your new `httpd.conf`:

```apache
ServerRoot "/home/my_username/webapps/test_app/apache2"

LoadModule dir_module        modules/mod_dir.so
LoadModule env_module        modules/mod_env.so
LoadModule log_config_module modules/mod_log_config.so
LoadModule mime_module       modules/mod_mime.so
LoadModule rewrite_module    modules/mod_rewrite.so
LoadModule setenvif_module   modules/mod_setenvif.so
LoadModule wsgi_module       modules/mod_wsgi.so

KeepAlive Off
Listen 12345
MaxSpareThreads 3
MinSpareThreads 1
ServerLimit 1
SetEnvIf X-Forwarded-SSL on HTTPS=1
ThreadsPerChild 5

WSGIRestrictEmbedded On
WSGILazyInitialization On

NameVirtualHost *
<VirtualHost *>
    ServerName  example.com

    # Logging configuration
    LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    CustomLog /home/my_username/logs/user/access_test_app.log combined
    ErrorLog /home/my_username/logs/user/error_test_app.log

    # Django WSGI settings
    WSGIDaemonProcess test_app processes=5 python-path=/home/my_username/webapps/test_app/test_django:/home/my_username/webapps/test_app/lib/python2.7/site-packages:/home/my_username/webapps/test_app/lib/python2.7 threads=1
    WSGIProcessGroup test_app
    WSGIScriptAlias / /home/my_username/webapps/test_app/test_django/test_django/wsgi.py
</VirtualHost>
```

Save the configuration to `~/webapps/test_app/apache2/conf/httpd.conf` and restart Apache.

    $ ./apache2/bin/restart

Visit your website again and you should be presented with Django congratulating you for setting your server up correctly.

## Serving static and media files

The recommended way to serve static and media files on WebFaction is to use Nginx directly. 

Let's begin by creating the directories for static and media files.

    $ cd ~/webapps/test_app
    $ mkdir media static

In order to tell Django where the files should be stored, we should place the appropriate lines in the project's `settings.py` file. I like to keep the location of `media` and `static` folders relative to the source code project, so I would set them in this way:

```python
import os
MEDIA_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '../../media/').replace('\\','/'))
STATIC_ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '../../static/').replace('\\','/'))
```

Let's collect the static files from all applications to the `static` directory:

    $ cd ~/webapps/test_app
    $ source bin/activate
    (test_app) $ cd test_app
    (test_app) $ python manage.py collecstatic

We can now serve our static files. In the WebFaction control panel, add two [new applications](https://my.webfaction.com/new-application) named `test_app_media` and `test_app_static`. Both will be defined using these settings:

* App category: `Symbolic link`
* App type: `Symbolic link to static-only app`
* Extra info: the path to the file folder, i.e. `/home/my_username/webapps/test_app/media` or `/home/my_username/webapps/test_app/static`

The final step is to add these Nginx-powered folders to our website definition. On the website settings screen for your domain, in the Contents section, choose to add an application. Choose the option to reuse an existing application and set the `test_app_media` to serve everything under `http://example.com/media` and `test_app_static` for `http://example.com/static`.

<figure>
  <img src="/images/illustrations/2013-09-14/webfaction-website-content.png">
  <figcaption>Contents section of website settings</figcaption>
</figure>


## Separating development and production settings

You will want to use slightly different settings for your development and production environments. In order to separate them you can create three separate settings files:

* `settings.py` - global settings, which apply to both environments
* `settings_dev.py` - your development environment specific settings
* `settings_prod.py` - production environment specific settings

The `settings_prod.py` file should only contain the settings which are specific to this environment, but also import all the global settings. We can do this by importing global settings like this:

```python
from .settings import *

# Define production-specific settings 
DEBUG = False
TEMPLATE_DEBUG = DEBUG

DATABASES = {
    # ... production server database settings ...
}

```

Django checks the environment variable named `DJANGO_SETTINGS_MODULE` to determine which settings file to use. If this environment variable is undefined, it will fall back to `test_app.settings`.

In order to use your new settings module in the shell, we can add a line to the end of the script which activates our virtual environment (`bin/activate`).

    export DJANGO_SETTINGS_MODULE=test_app.settings_prod

Apache and mod_wsgi don't know about our new settings yet. We can set the `DJANGO_SETTINGS_MODULE` dynamically inside the `wsgi.py` script. Create a `wsgi_prod.py` script which will contain the following:

```python
import os
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "test_app.settings_prod")
from django.core.wsgi import get_wsgi_application
application = get_wsgi_application()
```

Now instruct Apache to use this WSGI script by setting the `WSGIScriptAlias` directive line to:

```apache
WSGIScriptAlias / /home/my_username/webapps/test_app/test_django/test_django/wsgi_prod.py
```

Restart Apache and your application should run with production settings applied.