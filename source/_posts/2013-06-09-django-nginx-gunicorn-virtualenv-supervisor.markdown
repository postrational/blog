---
layout: post
title: "Setting up Django with Nginx, Gunicorn, virtualenv, supervisor and PostgreSQL"
date: "2013-06-09"
permalink: "/blog/2013/06/09/django-nginx-gunicorn-virtualenv-supervisor/"
comments: true
categories: tech
published: true
tags: code
---

[Django](http://www.djangoproject.com/) is an efficient, versatile and dynamically evolving web application development framework. When Django initially gained popularity, the recommended setup for running Django applications was based around Apache with mod_wsgi. The art of running Django advanced and these days the recommended configuration is more efficient and resilient, but also more complex and includes such tools as: Nginx, Gunicorn, virtualenv, supervisord and PostgreSQL. 

In this text I will explain how to combine all of these components into a Django server running on Linux.

<!-- more -->

### Prerequisites

I assume you have a server available on which you have root privileges. I am using a server running Debian 7, so everything here should work the same on an Ubuntu server or other Debian-based distribution. If you're using an RPM-based distro (such as CentOS), you will need to replace the `apt-get` commands by their `yum` counterparts.

If you don't have a server to play with, I would recommend the inexpensive VPS servers offered by [Digital Ocean](https://www.digitalocean.com/?refcode=053914aba44d). If you click through [this link](https://www.digitalocean.com/?refcode=053914aba44d) when signing up, you'll pay a bit of my server bill :)

I'm also assuming you configured your DNS to point a domain at the server's IP. In this text, I pretend your domain is `example.com`

### Update your system

Let's get started by making sure our system is up to date.

    $ sudo apt-get update
    $ sudo apt-get upgrade

### PostgreSQL

Install PostgreSQL on a Debian-based system:

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

I like to keep all my web apps in the /webapps/ directory. If you prefer /var/www/ or something else, use that instead.

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


Now that you have gunicorn, you can test whether it can server your Django application by running the following command:

    (hello_django) $ gunicorn_django --bind example.com:8001

You should now be able to access the Gunicorn server from htttp://example.com:8001
I intentionally changed port 8000 to 8001 to force your browser to establish a new connection.

Gunicorn is installed and ready to serve your app. Let's set some configuration options to make it more useful. I like to set a number of parameters, so let's put them all into a small BASH script, which I save as `bin/gunicorn_start`

<script src="https://gist.github.com/postrational/5747293.js?file=gunicorn_start.bash"></script>

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

As a rule-of-thumb set the `--workers` (`NUM_WORKERS`) according to the following formula: 2 * CPUs  + 1. The idea being, that at any given time half of your workers will be busy doing I/O. For a single CPU machine it would give you 3.

The `--name` (`NAME`) argument specifies how your application will identify itself in programs such as `top` or `ps`. It defaults to `gunicorn`, which might make it harder to distinguish from other apps if you have multiple Gunicorn-powered applications running on the same server. In order for the `--name` argument to have an effect you need to install a Python module called `setproctitle`. It's tricky to install `setproctitle` into a virtualenv, but you can install the module system-wide and symlink the binary into your virtual env.

    $ sudo apt-get install python-setproctitle
    $ ln -s /usr/lib/pymodules/python2.7/setproctitle.so /webapps/hello_django/lib/python2.7/setproctitle.so

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

Your application should now be automatically started after a system reboot and automatically restarted if it ever crashed for any reason.


### Nginx

Time to set up Nginx as a server for out application and its static files. Install and start Nginx:

    $ sudo apt-get install nginx
    $ sudo service nginx start

You can navigate to your server (http://example.com) with your browser and Nginx should greet you with the words "Welcome to nginx!".

#### Create an Nginx virtual server configuration for Django

Each Nginx virtual server should be described in a file in the `/etc/nginx/sites-available` directory. You select which sites you want to enable by making symbolic links to those in the  `/etc/nginx/sites-enabled` directory.

Create a new nginx server configuration file for your Drupal site running on example.com in `/etc/nginx/sites-available/hello`. The file should contain something along the following lines. A more detailed example is available [from the folks who make Gunicorn](https://github.com/benoitc/gunicorn/blob/master/examples/nginx.conf).

<script src="https://gist.github.com/postrational/5747293.js?file=hello.nginxconf"></script>

Restart Nginx:

    $ sudo service nginx restart 

If you navigate to your site, you should now see your Django welcome-page powered by Nginx and Gunicorn. Go ahead and develop to your heart's content.

If you run into any problems with the above setup, please drop me a line.
