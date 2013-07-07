---
layout: post
title: "How to run multiple websites from one Django project"
date: "2010-10-19"
permalink: "/blog/2010/10/19/run-multiple-websites-one-django-project/"
comments: true
categories: tech
published: true
tags: 
---

It is sometimes beneficial to run two or more web sites or subdomains of a site from a single Django code base. Each Django app in the project can then power a website on a different domain, but all the apps can still share a single database with a single administrative interface.

<!-- more -->

In order to achieve this, one needs to prepare separate WSGI sockets for each website. You can provide a separate `settings.py` file for each website, thus selecting which apps will be active on that site and which `urls.py` file will be the `ROOT_URLCONF` and handle the routing of requests for that domain.

In this example I will show how to set up two subdomains of one site running on the WebFaction hosting service.

### Preliminaries
First of all, we need to set up:  
1) a single WebFaction application running Django,  
2) a WebFaction domain with two subdomains (separate domains could also be used),  
3) a WebFaction website running on both domains and powered by the Django application.  

### Apache configuration
Secondly, we need to edit the `http.conf` file, which is stored in the `~/webapps/APPLICATION_NAME/apache2/conf` directory.
In this file, we need to create a `<VirtualHost>` directive for each subdomain we are using...

    # Virtual hosts setup
    NameVirtualHost *
    <VirtualHost *>
        ServerName subdomain1.example.com
    
        WSGIDaemonProcess APPLICATION_NAME processes=5 python-path=/home/USERNAME/webapps/APPLICATION_NAME:/home/USERNAME/webapps/APPLICATION_NAME/lib/python2.6 threads=1
        WSGIScriptAlias / /home/USERNAME/webapps/APPLICATION_NAME/subdomain1.wsgi
    </VirtualHost>
    
    <VirtualHost *>
        ServerName subdomain2.example.com
        
        WSGIDaemonProcess APPLICATION_NAME_www processes=5 python-path=/home/USERNAME/webapps/APPLICATION_NAME:/home/USERNAME/webapps/APPLICATION_NAME/lib/python2.6 threads=1
        WSGIScriptAlias / /home/USERNAME/webapps/APPLICATION_NAME/subdomain2.wsgi
    </VirtualHost>

The `WSGIDaemonProcess` directive specifies the configuration of the server deamon processes which will power each domain. In the example above, each domain is powered by 5 separate processes. This consumes 5 times more memory then a single process, but allows you to handle more requests simultaneously. This directive also allows you to specify the `PYTHONPATH` specific to your Django codebase and library directory.

The `WSGIScriptAlias` allows you to specify, which file will start the `WSGI` socket for the domain.

### WSGI startup files
Next we need to create the two .wsgi files:  
`/home/USERNAME/webapps/APPLICATION_NAME/subdomain1.wsgi`  
`/home/USERNAME/webapps/APPLICATION_NAME/subdomain2.wsgi`  

Each file should contain the following code with appropriately `subdomain1` or `subdomain2`, and `PROJECT_NAME` should be changed to the name of the directory which holds your Django project files.

<pre><code class="python">
import os
import sys
from django.core.handlers.wsgi import WSGIHandler

os.environ['DJANGO_SETTINGS_MODULE'] = 'PROJECT_NAME.subdomain1_settings' # or PROJECT_NAME.subdomain2_settings
application = WSGIHandler()
</code></pre>

### `settings.py` files
Next, we need to set up the two `settings.py` files. I would actually recommend setting up 3 of these, one to hold information, which is common to all domains, let's leave it named `settings.py` and the two domain-specific files: `subdomain1_settings.py` and `subdomain2_settings.py`. 

The subdomain specific settings files will inherit all the defaults from the common `settings.py` file, and override only those values which are specific to the domain. For instance, lets create a subdomain specific settings file, which runs a different then default set of apps and uses a different `urls.py` as `ROOT_URLCONF`. Such a file should contain the following code:

<pre><code class="python">
from settings import *

SITE_ID = 1

ROOT_URLCONF = 'subdomain1_urls'

INSTALLED_APPS = (
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.sites',
    'django.contrib.messages',
    
    # other apps specific to this domain
)
</code></pre>

### `urls.py` files
Now, we just need to make the two url configuration files, which will handle the routing of requests coming into our domains. These are standard `url.py`, they just have to be named, as specified in the `settings.py` files, so `subdomain1_urls.py` and `subdomain2_urls.py`.

### Conclusion
So there you have it. This technique works well on WebFaction, and I'm sure can be replicated on other hosting services, which allow you to modify Apache configuration files.

One thing to keep in mind is that running two separate `WSGI` processes will use twice as much memory as running one. You can tweak the memory usage to your needs by specifying how many processes each `WSGI` socket is handled by.
