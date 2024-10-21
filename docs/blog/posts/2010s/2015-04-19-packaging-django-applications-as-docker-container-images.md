---
title: Packaging Django applications into Docker container images
date: 2015-04-19T12:40:00
slug: packaging-django-applications-as-docker-container-images
layout: post
categories:
  - tech
tags:
  - django
  - docker
  - container
comments: true
---

[Docker][docker-about] is an open-source software container management system. It allows you to create an isolated, self-contained environment to run your application. In this article we will walk thought steps needed to create a Docker image containing a Django application and demonstrate how to run it and access the container.

<!-- more -->

#### Benefits of Docker

So why is this Docker thing so popular these days? The basic answer is that it makes your applications portable. Django applications can make use of Python's `virtualenv` to create isolated environments, but if some of your apps use Python 2 and some use Python 3, you may need to install a whole slew of additional libraries on your host server.

With Docker on the other hand, each container includes a specific version of the Linux kernel and all other dependencies of your app. You install dependencies such as `libjpeg` in the container, not on the host, so if your apps need different version of this or any other system libraries, you won't run into problems.

* An application running in a Docker container is sandboxed and doesn't have access to the host machine. This limits the potential security implications of a breach if someone were to exploit a bug in your app.
* Docker containers are much lighter then full VMs, because they don't run the operating system and rely on the host's kernel. The only processes running in the container are the ones your application requires.
* Once created the same container can be shared among developers and run in your testing and production environments.

You can find more information about Docker in its [FAQ pages][docker-faq].

### In this article

* Installing Docker
* Creating a Docker image with your Django application
  * Creating an entry-point script which starts Gunicorn
  * Creating a Dockerfile
  * Building a Docker container image
* Running a Docker container with your application
  * Running the container in detached mode
  * Passing additional arguments to Gunicorn
  * Running Django management commands in the container
  * Backing up user media files
  * Writing logs to the Docker host
  * Running the container with custom Django settings


### Prerequisites

The following procedure was tested on systems running **Debian 7** and **Ubuntu 14.04LTS**. Everything should also work other Debian-based distributions. If you're using an RPM-based distro (such as CentOS), you will need to replace the `apt-get` commands by their `yum` counterparts and if you're using FreeBSD you can install the components from ports. If you don't have a server to play with, I can recommend the inexpensive VPS servers offered by [Digital Ocean][digital_ocean_referal].


### Installing Docker

A Docker package is available in the **Debian 8** repositories, so installing is as simple as:

    $ sudo apt-get install docker.io

On **Debian 7** and **Ubuntu**, you will have to run an installation script provided by Docker:

    $ sudo apt-get install wget
    $ wget -qO- https://get.docker.com/ | sh

If you want to be able to run Docker containers as your user, not only as `root`, you should add yourself to the group called `docker` using the following command. 

    $ sudo usermod -aG docker `whoami`

!!! note

    Remember to log out and back in to pick up your new groups.

Once Docker is installed, you can test it by running the following command. This will take a few minutes, so be patient.

    $ docker run -i -t ubuntu:14.04 /bin/bash
    Unable to find image 'ubuntu:14.04' locally
    14.04: Pulling from ubuntu
    511136ea3c5a: Pull complete
    f3c84ac3a053: Pull complete
    a1a958a24818: Pull complete
    9fec74352904: Pull complete
    d0955f21bf24: Already exists
    Digest: sha256:2a214fd5c1c2048ef34bb79b5411efe4aa1e082b53ac1de3191992fe3ec64395
    Status: Downloaded newer image for ubuntu:14.04
    root@a8fd0ab40b7e:/#

The above command actually downloaded (pulled) a docker container with Ubuntu 14.04 from the official Docker base images repository. After the image was downloaded, Docker fired up the container and started `bash` inside. 
Feel free to look around. It looks like a normal Ubuntu system, except that only your `bash` process is running here:

    root@a8fd0ab40b7e:/# ps aux
    USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
    root         1  0.0  0.0  18160  1984 ?        Ss   13:07   0:00 /bin/bash
    root        23  0.0  0.0  15560  1148 ?        R+   13:10   0:00 ps aux

Type `exit` or hit `Ctrl-D` to exit `bash` and stop the container.

You can list all running Docker containers using the `docker ps` command. If you add the `--all` switch you will also list containers, which were running previously, but are currently closed.

    $ docker ps --all
    CONTAINER ID        IMAGE          COMMAND        CREATED          STATUS       PORTS    NAMES
    a8fd0ab40b7e        ubuntu:14.04   "/bin/bash"    6 minutes ago    Exited (0)            sad_galileo


### Creating a Docker image with your Django application

Let's proceed to create the Docker image for our Django application.

We will need a directory to work in and a copy of our application's source. Let's create a directory called `dockyard`, where we will be making our containers and a subdirectory for the Docker image we are creating.

    $ mkdir -p dockyard/hello_django_docker
    $ cd dockyard/hello_django_docker

For the purposes of this article I uploaded a sample Django app to Github, so we can grab a copy of the source code using the following command:

    $ git clone https://github.com/postrational/hello_django.git

We should now have a working directory containing the source code of our Django application. Please note that I assume that a PIP-compatible `requirements.txt` file and the Django `manage.py` script are in the main source code directory named `hello_django`. The project's `settings.py` file is located in the subdirectory `hello`.

    ~/dockyard/hello_django_docker    # Our working directory
    `-- hello_django                  # Main project source directroy (from repo)
        |-- hello
        |   |-- __init__.py
        |   |-- settings.py           # Project settings
        |   |-- urls.py
        |   `-- wsgi.py               # Project's WSGI start script
        |-- manage.py                 # Django's management command
        |-- project_application_1
        |   `-- (more files...)
        |-- project_application_2
        |   `-- (more files...)
        `-- requirements.txt          # File generated using pip freeze


With the code in place, let's proceed to create Docker-related files.


#### Create an entry-point script

A Docker container can use an script as the default command which will be fired when the container is run.
In our case we will use the following script as the entry point.

```bash title="docker-entrypoint.sh"
#!/bin/bash
python manage.py migrate                  # Apply database migrations
python manage.py collectstatic --noinput  # Collect static files

# Prepare log files and start outputting logs to stdout
touch /srv/logs/gunicorn.log
touch /srv/logs/access.log
tail -n 0 -f /srv/logs/*.log &

# Start Gunicorn processes
echo Starting Gunicorn.
exec gunicorn hello.wsgi:application \
    --name hello_django \
    --bind 0.0.0.0:8000 \
    --workers 3 \
    --log-level=info \
    --log-file=/srv/logs/gunicorn.log \
    --access-logfile=/srv/logs/access.log \
    "$@"
```

The above entry point script does a few things:

* starts by running a few management commands, to apply the changes made in the application source code
* proceeds to create two log files in `/srv/logs/` and to run the `tail -f` command which will output the logs to the console
* finally is starts `gunicorn` which will serve our Django application
* the `"$@"` notation in the last line will allow you to pass additional arguments to `gunicorn` when you start the container.

Save the script as `docker-entrypoint.sh` and change its permissions to make it executable:

    $ chmod u+x docker-entrypoint.sh

#### Create the Dockerfile

We will now make the container definition file named `Dockerfile`. Create the file and give it the following content.

```make title="Dockerfile"
############################################################
# Dockerfile to run a Django-based web application
# Based on an Ubuntu Image
############################################################

# Set the base image to use to Ubuntu
FROM ubuntu:14.04

# Set the file maintainer (your name - the file's author)
MAINTAINER Michal Karzynski

# Set env variables used in this Dockerfile (add a unique prefix, such as DOCKYARD)
# Local directory with project source
ENV DOCKYARD_SRC=hello_django
# Directory in container for all project files
ENV DOCKYARD_SRVHOME=/srv
# Directory in container for project source files
ENV DOCKYARD_SRVPROJ=/srv/hello_django

# Update the default application repository sources list
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y python python-pip

# Create application subdirectories
WORKDIR $DOCKYARD_SRVHOME
RUN mkdir media static logs
VOLUME ["$DOCKYARD_SRVHOME/media/", "$DOCKYARD_SRVHOME/logs/"]

# Copy application source code to SRCDIR
COPY $DOCKYARD_SRC $DOCKYARD_SRVPROJ

# Install Python dependencies
RUN pip install -r $DOCKYARD_SRVPROJ/requirements.txt

# Port to expose
EXPOSE 8000

# Copy entrypoint script into the image
WORKDIR $DOCKYARD_SRVPROJ
COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
```

`Dockerfile` specifies the steps needed to create our container image:

1. Use Ubuntu 14.04 as the base image of our container. Docker will download the image named `ubuntu:14.04` and all subsequent commands will be executed inside of a running container with this base OS.
2. We set some environment variables in our container using the `ENV` commands. These variables can be used later in the `Dockerfile`, but will also be available in the environment of all programs executed in the container. For this reason we use a prefix (`DOCKYARD`), so that our variables don't accidentally override anything else.
3. We run `apt-get` to install any system tools and libraries we may need.
4. We prepare all directories our application will use in the `/srv/` directory of our container. Using the `VOLUME` command we make some of these directories available to other containers. This will come in handy later, see "Backing up user media files".
5. Next we use the `COPY` command to copy the source code of our app into the container.
6. We use the `requirements.txt` file from the source code to install Python dependencies.
7. We use the `EXPOSE` command to make the Gunicorn port (8000) accessible outside of our container.
8. Finally we copy over `docker-entrypoint.sh` and define it as the script which should execute when the container is started.

You may want to refer to the [Dockerfile documentation][docker-dockerfile] for more information about the available commands.


#### Build the Docker container image

All the pieces are now in place. Let's just review to make sure the files we created are in the right spot:


    ~/dockyard/hello_django_docker
    |-- docker-entrypoint.sh         # We added the executable entry script here
    |-- Dockerfile                   # And the Dockerfile here
    `-- hello_django
        |-- hello
        |   |-- __init__.py
        |   |-- settings.py
        |   |-- urls.py
        |   `-- wsgi.py
        |-- manage.py
        |-- project_application_1
        |-- project_application_2
        `-- requirements.txt

We can now build the Docker container image. I will call the image `michal/hello_django`. 

!!! note

    Docker image names follow the convention of `user-name/image-name`. When you upload your image to a repository it will be added to your user account based on the name.


    $ docker build -t michal/hello_django ~/dockyard/hello_django_docker
    Sending build context to Docker daemon 80.38 kB
    Sending build context to Docker daemon
    Step 0 : FROM ubuntu:14.04
    (...)
    Successfully built 03c7aeb70a09

You will see output of many commands as the container is put together. At the end you should be able to see you newly created image when running the `docker images` command:

    $ docker images
    REPOSITORY            TAG      IMAGE ID       CREATED         VIRTUAL SIZE
    michal/hello_django   latest   17a441b8bdbd   2 seconds ago   394.6 MB

### Running a Docker container with your application

Now that the container image is created, we can use it to start a container.

    $ docker run --publish=8001:8000 michal/hello_django:latest

This command starts a new container from the `michal/hello_django` image.

!!! note

    It also makes the container's port 8000, which is the default Gunicorn port available on port 8001 of the Docker host. Reassigning ports in this way allows you to have multiple Django applications running in different containers. You just need to assign port 8000 of each container to a different port on the Docker host.

Once the container is started in this way, you should be able to navigate to port 8001 of the Docker host and see the famous Django start page declaring that "It worked!".

Visit your docker host in a browser (use the IP or domain of you machine): http://docker.host:8001

You can stop the container by hitting Ctrl-C in the terminal.

#### Running the container in detached mode

Starting and stopping a container as we did above is useful for debugging, but in most other cases you will want to start the container without attaching it to a terminal session. 

Use the `--detach=true` argument when starting the container.

    $ docker run --name=hello_django \
        --detach=true \
        --restart=always \
        --publish=8001:8000 \
        michal/hello_django:latest
    81512acac0e4875a218587737ea31ce09aae746e4a8248461e16ab601bb1b0aa

Note, that we specified the name of the container (`--name=hello_django`). We also specified that the container should always be restarted if the process inside stops or crashes (`--restart=always`).

You can now check that the container is running by listing all running Docker containers using the `docker ps` command.

    $ docker ps
    CONTAINER ID        IMAGE                        COMMAND                CREATED             STATUS              PORTS                    NAMES
    2c7cbc6fd5b8        michal/hello_django:latest   "/docker-entrypoint.   3 seconds ago       Up 3 seconds        0.0.0.0:8001->8000/tcp   hello_django

You can also follow the logs which are being output by the processes running in the container using the `docker logs` command.

    $ docker logs -f hello_django

You can stop and restart the container:

    $ docker stop hello_django
    $ docker start hello_django
    $ docker restart hello_django

And you can delete the container when you're done with it.

    $ docker stop hello_django
    $ docker rm hello_django


#### Passing additional arguments to Gunicorn

Docker will pass any arguments specified after the name of the image to the command which starts the container. In our case those arguments will be passed to the `docker-entrypoint.sh` script, which in turn will pass them to the `gunicorn` command which it starts.

If we want to change the number of Gunicorn worker processes running in the container, we just need to add the `--workers` argument to the end of `docker run`.

    $ docker run \
        michal/hello_django:latest \
        --workers 5


#### Backing up user media files

As we noted earlier, the `VOLUME` command in the Dockerfile made some directories accessible from other containers. If you would like to make a backup up of files stored in the `/srv/media/` directory, you can start another container using the `--volumes-from` argument. The volume directories will be accessible in the newly stared container.

    $ docker run --rm -i -t --volumes-from=hello_django ubuntu:14.04 /bin/bash
    root@ed95f0967489:/# cd /srv/media/
    root@d0198a264b3a:/srv/media# apt-get install -y ssh-client
    root@d0198a264b3a:/srv/media# scp -r * user@remote-host:~/path/to/backup

You can find more information about [managing volumes in containers in the docs][docker-volumes].

#### Writing logs to a directory on the Docker host

You can also mount a Docker host machine directory as a volume inside the container, using the `--volume` argument.

    $ sudo mkdir -p /var/log/webapps/hello
    $ docker run --name=hello_django \
        --detach=true \
        --restart=always \
        --publish=8001:8000 \
        --volume=/var/log/webapps/hello:/srv/logs \
        michal/hello_django:latest \
        --workers 5
    $ tail -f /var/log/webapps/hello/*.log

You can find more information about [managing volumes in containers in the docs][docker-volumes].

#### Using custom Django settings

In many cases you will want to use different settings when running your Django application in development, during testing and in production. 

In order to do this, create a new settings file on the Docker host. Let's assume you save it in the directory `/etc/webapps/hello_django/local_settings.py`. In the file import all of your project's default settings and override only what's needed. 

```python title="local_settings.py"
    from hello.settings import *
    DATABASES = {
        # Databases for this instance of the container
    }
```

You can then use the `--volume` argument to mount the single file `local_settings.py` into your container and use the `--env` argument to set the `DJANGO_SETTINGS_MODULE` environment variable to the new settings module.

    $ docker run --name=hello_django \
        --detach=true \
        --restart=always \
        --publish=8001:8000 \
        --env="DJANGO_SETTINGS_MODULE=hello.local_settings" \
        --volume=/etc/webapps/hello_django/local_settings.py:/srv/hello_django/hello/local_settings.py \
        michal/hello_django:latest \
        --workers 5


#### Running Django management commands in the container

You will probably want to run some Django management commands on the Docker host. In order to do this you can start another container from the same image and specify another command which will be started instead of the entrypoint script. If you use `/bin/bash`, you will arrive at a shell in the container. From here you can execute Django's `manage.py` commands.

    $ docker run --rm -i -t --entrypoint=/bin/bash michal/hello_django:latest
    root@ac0073a6bb9c:/srv/hello_django# ./manage.py createsuperuser
    Username (leave blank to use 'root'): michal
    Email address: michal@docker.image
    Password:
    Password (again):
    Superuser created successfully.

Thanks for reading. If you find any issues with this article of have any other ideas, leave a comment below.


[docker-about]: https://www.docker.com/whatisdocker/ "What is Docker?"
[docker-faq]: http://docs.docker.com/faq/ "Docker - Frequently asked questions"
[docker-dockerfile]: https://docs.docker.com/reference/builder/ "Dockerfile reference"
[docker-volumes]: http://docs.docker.com/userguide/dockervolumes/ "Managing Data in Containers"
[digital_ocean_referal]: https://www.digitalocean.com/?refcode=053914aba44d "Digital Ocean VPS Hosting"