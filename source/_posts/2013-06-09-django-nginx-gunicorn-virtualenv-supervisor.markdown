---
layout: post
title: "Setting up Django with Nginx, Gunicorn, virtualenv, supervisor and PostgreSQL"
date: "2013-06-09"
permalink: "/blog/2013/06/09/django-nginx-gunicorn-virtualenv-supervisor/"
comments: true
categories: tech
published: true
tags: django nginx gunicorn virtualenv supervisord postgresql
---

[Django](http://www.djangoproject.com/) is an efficient, versatile and dynamically evolving web application development framework. When Django initially gained popularity, the recommended setup for running Django applications was based around Apache with mod_wsgi. The art of running Django advanced and these days the recommended configuration is more efficient and resilient, but also more complex and includes such tools as: Nginx, Gunicorn, virtualenv, supervisord and PostgreSQL. 

In this text I will explain how to combine all of these components into a Django server running on Linux.

<!-- more -->

### Prerequisites

I assume you have a server available on which you have root privileges. I am using a server running Debian 7, so everything here should also work on an Ubuntu server or other Debian-based distribution. If you're using an RPM-based distro (such as CentOS), you will need to replace the `apt-get` commands by their `yum` counterparts and if you're using FreeBSD you can install the components from ports.

If you don't have a server to play with, I would recommend the inexpensive VPS servers offered by [Digital Ocean](https://www.digitalocean.com/?refcode=053914aba44d). If you click through [this link](https://www.digitalocean.com/?refcode=053914aba44d) when signing up, you'll pay a bit of my server bill :)

I'm also assuming you configured your DNS to point a domain at the server's IP. In this text, I pretend your domain is `example.com`

### Update your system

Let's get started by making sure our system is up to date.

    $ sudo apt-get update
    $ sudo apt-get upgrade

### PostgreSQL

To install PostgreSQL on a Debian-based system run this command:

    $ sudo apt-get install postgresql postgresql-contrib

Create a database and user with privileges.

    $ sudo su - postgres
    postgres@django:~$ createdb hello
    postgres@django:~$ createuser -P
    Enter name of role to add: hello_django
    Enter password for new role: 
    Enter it again: 
    Shall the new role be a superuser? (y/n) n
    Shall the new role be allowed to create databases? (y/n) n
    Shall the new role be allowed to create more new roles? (y/n) n
    postgres@django:~$ psql
    psql (9.1.9)
    Type "help" for help.

    postgres=# GRANT ALL PRIVILEGES ON DATABASE hello TO hello_django;
    GRANT
    postgres=# \q
    postgres@django:~$ logout
    $

### Install virtualenv and create an environment for you app

[Virtualenv](http://virtualenv.org/) is a tool which allows you to create separate Python environments on your system. This allows you to run applications with different sets of requirements concurrently (e.g. one based on Django 1.5, another based on 1.6). virtualenv is easy to install on Debian:

    $ sudo apt-get install python-virtualenv
    
#### Create and activate an environment for your application

I like to keep all my web apps in the `/webapps/` directory. If you prefer `/var/www/` or something else, use that instead.

    $ cd /webapps/
    $ virtualenv hello_django
    
    New python executable in hello_django/bin/python
    Installing distribute..............done.
    Installing pip.....................done.
    
    $ cd hello_django
    $ source bin/activate
    (hello_django) $ 
    
Your environment is now activated and you can proceed to install Django inside it.
    
    (hello_django) $ pip install django
    
    Downloading/unpacking django
    (...)
    Installing collected packages: django
    (...)
    Successfully installed django
    Cleaning up...

Your environment with Django should be ready to use. Go ahead and create an empty Django project.

    (hello_django) $ django-admin.py startproject hello
    
You can test it by running the development server:

    (hello_django) $ cd hello
    (hello_django) $ python manage.py runserver example.com:8000
    Validating models...

    0 errors found
    June 09, 2013 - 06:12:00
    Django version 1.5.1, using settings 'hello.settings'
    Development server is running at http://example.com:8000/
    Quit the server with CONTROL-C.

You should now be able to access your development server from http://example.com:8000

### Configure PostgreSQL to work with Django

In order to use Django with PostgreSQL you will need to install the `psycopg2` database adapter in your virtual environment. This step requires the compilation of a native extension (written in C). The compilation will fail if it cannot find header files and static libraries required for linking C programs with `libpq` (library for communication with Postgres) and building Python modules (`python-dev` package). We have to install these two packages first, then we can install `psycopg2` using PIP.

Install dependencies:

    $ sudo apt-get install libpq-dev python-dev

Install `psycopg2` database adapter:

    (hello_django) $ pip install psycopg2

You can now configure the databases section in your `settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'hello',
        'USER': 'hello_django',
        'PASSWORD': '1Ak5RTQt7mtw0OREsfPhJYzXIak41gnrm5NWYEosCeIduJck10awIzoys1wvbL8',
        'HOST': 'localhost',
        'PORT': '',                      # Set to empty string for default.
    }
}
```

And finally build the initial database for Django:

    (hello_django) $ ./manage.py syncdb

### Gunicorn

In production we won't be using Django's single-threaded development server, but a dedicated application server called [gunicorn](http://gunicorn.org/).

Install gunicorn in your application's virtual environment:

    (hello_django) $ pip install gunicorn
    Downloading/unpacking gunicorn
      Downloading gunicorn-0.17.4.tar.gz (372Kb): 372Kb downloaded
      Running setup.py egg_info for package gunicorn

    Installing collected packages: gunicorn
      Running setup.py install for gunicorn

        Installing gunicorn_paster script to /webapps/hello_django/bin
        Installing gunicorn script to /webapps/hello_django/bin
        Installing gunicorn_django script to /webapps/hello_django/bin
    Successfully installed gunicorn
    Cleaning up...


Now that you have gunicorn, you can test whether it can serve your Django application by running the following command:

    (hello_django) $ gunicorn_django --bind example.com:8001

You should now be able to access the Gunicorn server from http://example.com:8001 . I intentionally changed port 8000 to 8001 to force your browser to establish a new connection.

Gunicorn is installed and ready to serve your app. Let's set some configuration options to make it more useful. I like to set a number of parameters, so let's put them all into a small BASH script, which I save as `bin/gunicorn_start`

<script src="https://gist.github.com/postrational/5747293.js?file=gunicorn_start.bash"></script>

Set the executable bit on the `gunicorn_start` script:

    $ chmod u+x bin/gunicorn_start

You can test your `gunicorn_start` script by running it:

    $ ./bin/gunicorn_start 
    Starting hello_app
    2013-06-09 21:14:07 [2792] [INFO] Starting gunicorn 0.17.4
    2013-06-09 21:14:07 [2792] [DEBUG] Arbiter booted
    2013-06-09 21:14:07 [2792] [INFO] Listening at: unix:/webapps/hello_django/run/gunicorn.sock (2792)
    2013-06-09 21:14:07 [2792] [INFO] Using worker: sync
    2013-06-09 21:14:07 [2798] [INFO] Booting worker with pid: 2798
    2013-06-09 21:14:07 [2799] [INFO] Booting worker with pid: 2799
    2013-06-09 21:14:07 [2800] [INFO] Booting worker with pid: 2800
    
Note the parameters set in `gunicorn_start`. You'll need to set the paths and filenames to match your setup.

As a rule-of-thumb set the `--workers` (`NUM_WORKERS`) according to the following formula: 2&nbsp;*&nbsp;CPUs&nbsp;+&nbsp;1. The idea being, that at any given time half of your workers will be busy doing I/O. For a single CPU machine it would give you 3.

The `--name` (`NAME`) argument specifies how your application will identify itself in programs such as `top` or `ps`. It defaults to `gunicorn`, which might make it harder to distinguish from other apps if you have multiple Gunicorn-powered applications running on the same server.

In order for the `--name` argument to have an effect you need to install a Python module called `setproctitle`. To build this native extension `pip` needs to have access to C header files for Python. You can add them to your system with the `python-dev` package and then install `setproctitle`.

    $ sudo apt-get install python-dev
    (hello_django) $ pip install setproctitle

Now when you list processes, you should see which gunicorn belongs to which application.

    $ ps aux
    USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    (...)
    michal   16124  0.0  1.9  56168  9860 ?        S    15:37   0:00 gunicorn: master [hello_app]
    michal   16130  0.0  4.5  73520 23004 ?        S    15:37   0:00 gunicorn: worker [hello_app]
    michal   16131  0.0  4.5  73496 23004 ?        S    15:37   0:00 gunicorn: worker [hello_app]
    michal   16132  0.0  4.5  73504 23004 ?        S    15:37   0:00 gunicorn: worker [hello_app]


### Starting and monitoring with Supervisor

Your `gunicorn_start` script should now be ready and working. We need to make sure that it starts automatically with the system and that it can automatically restart if for some reason it exits unexpectedly. These tasks can easily be handled by a service called [supervisord](http://supervisord.org/). Installation is simple:

    $ sudo apt-get install supervisor

When Supervisor is installed you can give it programs to start and watch by creating configuration files in the `/etc/supervisor/conf.d` directory. For our `hello` application we'll create a file named `/etc/supervisor/conf.d/hello.conf` with this content:

<script src="https://gist.github.com/postrational/5747293.js?file=hello.conf"></script>

You can set [many other options](http://supervisord.org/configuration.html#program-x-section-settings), but this basic configuration should suffice. 

Create the file to store your application's log messages:

    $ mkdir -p /webapps/hello_django/logs/
    $ touch /webapps/hello_django/logs/gunicorn_supervisor.log 

After you save the configuration file for your program you can ask supervisor to reread configuration files and update (which will start your the newly registered app).

    $ sudo supervisorctl reread
    hello: available
    $ sudo supervisorctl update
    hello: added process group

You can also check the status of your app or start, stop or restart it using supervisor.

    $ sudo supervisorctl status hello                       
    hello                            RUNNING    pid 18020, uptime 0:00:50
    $ sudo supervisorctl stop hello  
    hello: stopped
    $ sudo supervisorctl start hello                        
    hello: started
    $ sudo supervisorctl restart hello 
    hello: stopped
    hello: started

Your application should now be automatically started after a system reboot and automatically restarted if it ever crashed for some reason.


### Nginx

Time to set up Nginx as a server for out application and its static files. Install and start Nginx:

    $ sudo apt-get install nginx
    $ sudo service nginx start

You can navigate to your server (http://example.com) with your browser and Nginx should greet you with the words "Welcome to nginx!".

#### Create an Nginx virtual server configuration for Django

Each Nginx virtual server should be described by a file in the `/etc/nginx/sites-available` directory. You select which sites you want to enable by making symbolic links to those in the  `/etc/nginx/sites-enabled` directory.

Create a new nginx server configuration file for your Django application running on example.com in `/etc/nginx/sites-available/hello`. The file should contain something along the following lines. A more detailed example is available [from the folks who make Gunicorn](https://github.com/benoitc/gunicorn/blob/master/examples/nginx.conf).

<script src="https://gist.github.com/postrational/5747293.js?file=hello.nginxconf"></script>

Create a symbolic link in the `sites-enabled` folder:

    $ ln -s /etc/nginx/sites-available/hello /etc/nginx/sites-enabled/hello

Restart Nginx:

    $ sudo service nginx restart 

If you navigate to your site, you should now see your Django welcome-page powered by Nginx and Gunicorn. Go ahead and develop to your heart's content.

> %tip%
> At this stage you may find that instead of the Django welcome-page, you encounter the default "*Welcome to nginx!*" page. This may be caused by the `default` configuration file, which is installed with Nginx and masks your new site's configuration. If you don't plan to use it, delete the symbolic link to this file from `/etc/nginx/sites-enabled`.

If you run into any problems with the above setup, please drop me a line.

### Final directory structure

If you followed this tutorial, you should have created a directory structure resembling this:

    /webapps/hello_django/
    ├── bin                          <= Directory created by virtualenv
    │   ├── activate                 <= Environment activation script
    │   ├── django-admin.py
    │   ├── gunicorn
    │   ├── gunicorn_django
    │   ├── gunicorn_start           <= Script to start application with Gunicorn
    │   └── python
    ├── hello                        <= Django project directory, add this to PYTHONPATH
    │   ├── manage.py
    │   ├── project_application_1
    │   ├── project_application_2
    │   └── hello                    <= Project settings directory
    │       ├── __init__.py
    │       ├── settings.py          <= hello.settings - settings module Gunicorn will use
    │       ├── urls.py
    │       └── wsgi.py              <= hello.wsgi - WSGI module Gunicorn will use
    ├── include
    │   └── python2.7 -> /usr/include/python2.7
    ├── lib
    │   └── python2.7
    ├── lib64 -> /webapps/hello_django/lib
    ├── logs                         <= Application logs directory
    │   ├── gunicorn_supervisor.log
    │   ├── nginx-access.log
    │   └── nginx-error.log
    ├── media                        <= User uploaded files folder
    ├── run
    │   └── gunicorn.sock 
    └── static                       <= Collect and serve static files from here


### Uninstalling the Django application

If time comes to remove the application, follow these steps.

Remove the virtual server from Nginx `sites-enabled` folder:

    $ sudo rm /etc/nginx/sites-enabled/hello_django

Restart Nginx:

    $ sudo service nginx restart 

If you never plan to use this application again, you can remove its config file also from the `sites-available` directory

    $ sudo rm /etc/nginx/sites-available/hello_django


Stop the application with Supervisor:
    
    $ sudo supervisorctl stop hello
    
Remove the application from Supervisor's control scripts directory:

    $ sudo rm /etc/supervisor/conf.d/hello.conf
    
If you never plan to use this application again, you can now remove its entire directory from `webapps`:

        $ sudo rm -r /webapps/hello_django


### Running multiple applications

If you would like some help with setting up a Nginx server to run multiple Django applications, check out [my next article][multiple_django].

[multiple_django]: /blog/2013/10/29/serving-multiple-django-applications-with-nginx-gunicorn-supervisor/ "Serving multiple Django applications with Nginx and Gunicorn"
