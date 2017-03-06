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

I assume you have a server available on which you have root privileges. I am using a server running Debian 7, so everything here should also work on an Ubuntu server or other Debian-based distribution. If you're using an RPM-based distro (such as CentOS), you will need to replace the `aptitude` commands by their `yum` counterparts and if you're using FreeBSD you can install the components from ports.

If you don't have a server to play with, I would recommend the inexpensive VPS servers offered by [Digital Ocean][digital_ocean_referal]. If you click through [this link][digital_ocean_referal] when signing up, you'll pay a bit of my server bill :)

I'm also assuming you configured your DNS to point a domain at the server's IP. In this text, I pretend your domain is `example.com`

### Update your system

Let's get started by making sure our system is up to date.

    $ sudo aptitude update
    $ sudo aptitude upgrade

### PostgreSQL

To install PostgreSQL on a Debian-based system run this command:

    $ sudo aptitude install postgresql postgresql-contrib

Create a database user and a new database for the app. Grab a [perfect password from GRC][perfect_passwords].

    $ sudo su - postgres
    postgres@django:~$ createuser --interactive -P
    Enter name of role to add: hello_django
    Enter password for new role: 
    Enter it again: 
    Shall the new role be a superuser? (y/n) n
    Shall the new role be allowed to create databases? (y/n) n
    Shall the new role be allowed to create more new roles? (y/n) n
    postgres@django:~$
    
    postgres@django:~$ createdb --owner hello_django hello
    postgres@django:~$ logout
    $


### Application user

Even though Django has a pretty good [security track record](http://django.readthedocs.org/en/latest/releases/security.html), web applications can become compromised. If the application has limited access to resources on your server, potential damage can also be limited. Your web applications should run as system users with limited privileges.

Create a user for your app, named `hello` and assigned to a system group called `webapps`.

    $ sudo groupadd --system webapps
    $ sudo useradd --system --gid webapps --shell /bin/bash --home /webapps/hello_django hello


### Install virtualenv and create an environment for you app

[Virtualenv](http://virtualenv.org/) is a tool which allows you to create separate Python environments on your system. This allows you to run applications with different sets of requirements concurrently (e.g. one based on Django 1.5, another based on 1.6). virtualenv is easy to install on Debian:

    $ sudo aptitude install python-virtualenv
    
#### Create and activate an environment for your application

I like to keep all my web apps in the `/webapps/` directory. If you prefer `/var/www/`, `/srv/` or something else, use that instead. Create a directory to store your application in `/webapps/hello_django/` and change the owner of that directory to your application user `hello`

    $ sudo mkdir -p /webapps/hello_django/
    $ sudo chown hello /webapps/hello_django/

As the application user create a virtual Python environment in the application directory:

    $ sudo su - hello
    hello@django:~$ cd /webapps/hello_django/
    hello@django:~$ virtualenv .
    
    New python executable in hello_django/bin/python
    Installing distribute..............done.
    Installing pip.....................done.
    
    hello@django:~$ source bin/activate
    (hello_django)hello@django:~$ 
    
Your environment is now activated and you can proceed to install Django inside it.
    
    (hello_django)hello@django:~$ pip install django
    
    Downloading/unpacking django
    (...)
    Installing collected packages: django
    (...)
    Successfully installed django
    Cleaning up...

Your environment with Django should be ready to use. Go ahead and create an empty Django project.

    (hello_django)hello@django:~$ django-admin.py startproject hello
    
You can test it by running the development server:

    (hello_django)hello@django:~$ cd hello
    (hello_django)hello@django:~$ python manage.py runserver example.com:8000
    Validating models...

    0 errors found
    June 09, 2013 - 06:12:00
    Django version 1.5.1, using settings 'hello.settings'
    Development server is running at http://example.com:8000/
    Quit the server with CONTROL-C.

You should now be able to access your development server from http://example.com:8000

#### Allowing other users write access to the application directory

Your application will run as the user `hello`, who owns the entire application directory. If you want regular user to be able to change application files, you can set the group owner of the directory to `users` and give the group write permissions.

    $ sudo chown -R hello:users /webapps/hello_django
    $ sudo chmod -R g+w /webapps/hello_django

You can check what groups you're a member of by issuing the `groups` command or `id`.

    $ id
    uid=1000(michal) gid=1000(michal) groups=1000(michal),27(sudo),100(users)

If you're not a member of `users`, you can add yourself to the group with this command:

    $ sudo usermod -a -G users `whoami`

> %tip%
> Group memberships are assigned during login, so you may need to log out and back in again for the system to recognize your new group.



### Configure PostgreSQL to work with Django

In order to use Django with PostgreSQL you will need to install the `psycopg2` database adapter in your virtual environment. This step requires the compilation of a native extension (written in C). The compilation will fail if it cannot find header files and static libraries required for linking C programs with `libpq` (library for communication with Postgres) and building Python modules (`python-dev` package). We have to install these two packages first, then we can install `psycopg2` using PIP.

Install dependencies:

    $ sudo aptitude install libpq-dev python-dev

Install `psycopg2` database adapter:

    (hello_django)hello@django:~$ pip install psycopg2

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

    (hello_django)hello@django:~$ python manage.py syncdb


### Gunicorn

In production we won't be using Django's single-threaded development server, but a dedicated application server called [gunicorn](http://gunicorn.org/).

Install gunicorn in your application's virtual environment:

    (hello_django)hello@django:~$ pip install gunicorn
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

    (hello_django)hello@django:~$ gunicorn hello.wsgi:application --bind example.com:8001

You should now be able to access the Gunicorn server from http://example.com:8001 . I intentionally changed port 8000 to 8001 to force your browser to establish a new connection.

Gunicorn is installed and ready to serve your app. Let's set some configuration options to make it more useful. I like to set a number of parameters, so let's put them all into a small BASH script, which I save as `bin/gunicorn_start`

<script src="https://gist.github.com/postrational/5747293.js?file=gunicorn_start.bash"></script>


Set the executable bit on the `gunicorn_start` script:

    $ sudo chmod u+x bin/gunicorn_start

You can test your `gunicorn_start` script by running it as the user `hello`.

    $ sudo su - hello
    hello@django:~$ bin/gunicorn_start
    Starting hello_app as hello
    2013-06-09 14:21:45 [10724] [INFO] Starting gunicorn 18.0
    2013-06-09 14:21:45 [10724] [DEBUG] Arbiter booted
    2013-06-09 14:21:45 [10724] [INFO] Listening at: unix:/webapps/hello_django/run/gunicorn.sock (10724)
    2013-06-09 14:21:45 [10724] [INFO] Using worker: sync
    2013-06-09 14:21:45 [10735] [INFO] Booting worker with pid: 10735
    2013-06-09 14:21:45 [10736] [INFO] Booting worker with pid: 10736
    2013-06-09 14:21:45 [10737] [INFO] Booting worker with pid: 10737
    
    ^C (CONTROL-C to kill Gunicorn)
    
    2013-06-09 14:21:48 [10736] [INFO] Worker exiting (pid: 10736)
    2013-06-09 14:21:48 [10735] [INFO] Worker exiting (pid: 10735)
    2013-06-09 14:21:48 [10724] [INFO] Handling signal: int
    2013-06-09 14:21:48 [10737] [INFO] Worker exiting (pid: 10737)
    2013-06-09 14:21:48 [10724] [INFO] Shutting down: Master
    $ exit

Note the parameters set in `gunicorn_start`. You'll need to set the paths and filenames to match your setup.

As a rule-of-thumb set the `--workers` (`NUM_WORKERS`) according to the following formula: 2&nbsp;*&nbsp;CPUs&nbsp;+&nbsp;1. The idea being, that at any given time half of your workers will be busy doing I/O. For a single CPU machine it would give you 3.

The `--name` (`NAME`) argument specifies how your application will identify itself in programs such as `top` or `ps`. It defaults to `gunicorn`, which might make it harder to distinguish from other apps if you have multiple Gunicorn-powered applications running on the same server.

In order for the `--name` argument to have an effect you need to install a Python module called `setproctitle`. To build this native extension `pip` needs to have access to C header files for Python. You can add them to your system with the `python-dev` package and then install `setproctitle`.

    $ sudo aptitude install python-dev
    (hello_django)hello@django:~$ pip install setproctitle

Now when you list processes, you should see which gunicorn belongs to which application.

    $ ps aux
    USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    (...)
    hello    11588  0.7  0.2  58400 11568 ?        S    14:52   0:00 gunicorn: master [hello_app]
    hello    11602  0.5  0.3  66584 16040 ?        S    14:52   0:00 gunicorn: worker [hello_app]
    hello    11603  0.5  0.3  66592 16044 ?        S    14:52   0:00 gunicorn: worker [hello_app]
    hello    11604  0.5  0.3  66604 16052 ?        S    14:52   0:00 gunicorn: worker [hello_app]
    
### Starting and monitoring with Supervisor

Your `gunicorn_start` script should now be ready and working. We need to make sure that it starts automatically with the system and that it can automatically restart if for some reason it exits unexpectedly. These tasks can easily be handled by a service called [supervisord](http://supervisord.org/). Installation is simple:

    $ sudo aptitude install supervisor

When Supervisor is installed you can give it programs to start and watch by creating configuration files in the `/etc/supervisor/conf.d` directory. For our `hello` application we'll create a file named `/etc/supervisor/conf.d/hello.conf` with this content:

<script src="https://gist.github.com/postrational/5747293.js?file=hello.conf"></script>

You can set [many other options](http://supervisord.org/configuration.html#program-x-section-settings), but this basic configuration should suffice. 

Create the file to store your application's log messages:

    hello@django:~$ mkdir -p /webapps/hello_django/logs/
    hello@django:~$ touch /webapps/hello_django/logs/gunicorn_supervisor.log 

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

    $ sudo aptitude install nginx
    $ sudo service nginx start

You can navigate to your server (http://example.com) with your browser and Nginx should greet you with the words "Welcome to nginx!".

#### Create an Nginx virtual server configuration for Django

Each Nginx virtual server should be described by a file in the `/etc/nginx/sites-available` directory. You select which sites you want to enable by making symbolic links to those in the  `/etc/nginx/sites-enabled` directory.

Create a new nginx server configuration file for your Django application running on example.com in `/etc/nginx/sites-available/hello`. The file should contain something along the following lines. A more detailed example is available [from the folks who make Gunicorn](https://github.com/benoitc/gunicorn/blob/master/examples/nginx.conf).

<script src="https://gist.github.com/postrational/5747293.js?file=hello.nginxconf"></script>

Create a symbolic link in the `sites-enabled` folder:

    $ sudo ln -s /etc/nginx/sites-available/hello /etc/nginx/sites-enabled/hello

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


### Translations

This article was actually translated into a number of languages. If you would like, you can read it in
[Spanish](https://wildunix.es/posts/configurar-django-con-nginx-gunicorn-virtualenv-supervisor-y-postgresql/) or
[Chinese](http://zqpythonic.qiniucdn.com/data/20130901152951/index.html).
If you know of other translations, let me know.


[multiple_django]: /blog/2013/10/29/serving-multiple-django-applications-with-nginx-gunicorn-supervisor/ "Serving multiple Django applications with Nginx and Gunicorn"
[perfect_passwords]: https://www.grc.com/passwords.htm "GRC's Ultra High Security Password Generator"
[digital_ocean_referal]: https://www.digitalocean.com/?refcode=053914aba44d "Digital Ocean VPS Hosting"
