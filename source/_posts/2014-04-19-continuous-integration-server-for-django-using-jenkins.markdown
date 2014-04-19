---
layout: post
title: "Setting up Jenkins as a continuous integration server for Django"
date: 2014-04-19 14:00
permalink: "/blog/2014/04/19/continuous-integration-server-for-django-using-jenkins/"
comments: true
categories: tech
published: true
tags: continuous-integration django jenkins
---

[Jenkins][jenkins] is an easy-to-use open-source continuous integration server. In this post we'll go through steps needed to set up Jenkins to deploy your Django application and run unit tests whenever someone commits code to your project's repository. If the new code causes any of your tests to fail, Jenkins will send the commiter an email alert.

<!-- more -->

### Prerequisites

In this post I will assume that you want to set up Jenkins on a Debian server named `test-server`. I will further assume that:

* the server is hosting a test version of your application at the URL `http://test-server`
* the application is running in a `virtualenv` located in the directory `/webapps/hello_django/`
* the application code itself is located in `/webapps/hello_django/trunk/`
* you're using an SVN repository located at `svn://svn-server/hello_django/trunk`

Take a look at my previous post for more information about [setting up Django in a virtualenv][blog-django-nginx].

### Installing Jenkins

Jenkins provides packages for most system distributions. Installation is very simple and consists of adding the Jenkins repository to your package system and installing the package. On Debian this can be performed using the following steps:

    ### Add the Jenkins repository to the list of repositories
    $ sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
    
    ### Add the repository's public key to your system's trusted keychain
    $ wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
    
    ### Download the repository index and install
    $ sudo apt-get update
    $ sudo apt-get install jenkins

Installation is very similar on other systems. For details take a look at the [Jenkins installation docs][jenkins-installation].

By default Jenkins runs on port `8080` and listens on all network interfaces. After installing the package, you can visit Jenkins under the URL: http://test-server:8080

The default setup provides no security at all, so if your server is accessible outside of a trusted network you will need to secure it. Jenkins documentation describes a [basic security][jenkins-basic-security] setup, which you can extend by [proxying Jenkins][jenkins-proxy] through your secured Apache or Nginx server, using HTTPs, etc.

### Preparation steps

Since we will want Jenkins to deploy our application to the directory from which it runs, ie. `/webapps/hello_django/trunk/`, we will need to give the `jenkins` user access to write to this directory. We can do this by changing the directory's owner to `jenkins` for example:

    $ sudo chown jenkins /webapps/hello_django/trunk/

If you want the `jenkins` user to restart your web or application server after a new version of your code is deployed, you should add an appropriate entry to your server's `/etc/sudoers` file, such as:

    jenkins ALL=NOPASSWD: /usr/sbin/apachectl

On your SVN server create a user named `jenkins` with access to the source code of your project.


### Creating a build configuration for your Django project

#### Making a new build configuration

1. Navigate to your Jenkins installation and click **New Item**. 
2. Specify the name of the build you are creating, for example `hello-django-trunk`
3. Select the **Build a free-style software project** option.

#### Configuring build location

1. On the build configuration screen, click **Advanced...** in the **Advanced Project Options** section.
2. Mark the checkbox **Use custom workspace**.
3. Specify `/webapps/hello_django/trunk/` as the **Directory**.

#### Configuring the source code repository

1. In the **Source Code Management** section, select **Subversion**.
2. Specify your **Repository URL** as `svn://svn-server/hello_django/trunk`
3. Set **Credentials** to the username and password of the `jenkins` SVN user.
4. Set **Local module directory** to a single dot `.` to indicate that we will be checking out code directly into the workspace directory.

<div class="figure">
<img src="/images/illustrations/2014-04-19/jenkins-source-code-management-configuration.png">
<div class="legend">Subversion configuration for Jenkins</div>
</div>

> %tip%
> If you are using Git, you should install the [Jenkins Git Plugin][jenkins-git-plugin] and use a Git URL for your repository instead.

#### Configuring build triggers

We will want Jenkins to deploy our application to the test server and run our tests after every commit. We can accomplish this, in at least two ways: a) we can ask Jenkins to periodically poll the SVN server for information about new commits, or b) we can add a post-commit hook to our repository to trigger a build after every commit remotely. The first option is easier to set up, but slightly wasteful, as we end up polling our source-code repository for information even during times when no one is working. Choose the option which suits your needs best.

To configure polling of your source code repository every 10 minutes:

1. Check the **Poll SCM** box in the **Build Triggers** section.
2. Enter the following string as **Schedule**: `H/10 * * * *`

Alternatively, to enable builds to be actively triggered by your source code repository's `post-commit` hook:

1. Check the **Trigger builds remotely (e.g., from scripts)** box.
2. Enter a long random string as the **Authentication Token**.

<div class="figure">
<img src="/images/illustrations/2014-04-19/jenkins-build-triggers-configuration.png">
<div class="legend">Build triggers (choose one or the other)</div>
</div>

If you want builds to be triggered actively by your source code repository, you will need to create a script called `post-commit` (in the `hooks` directory of your SVN repo root or the `.git/hooks` directory when using Git). Your hook script should execute a command such as `curl` to send an HTTP request to Jenkins which will trigger the build. The token is used here for security.


```bash
#!/bin/bash
curl http://test-server:8080/job/hello-django-trunk/build?token=xZrJ5WsSfJkGpNsriOlY4PtQ7hC5olzDhNE
```

> %tip%
> Once you set up Jenkins user authentication, the command above will not work. There is a [plugin][jenkins-build-token-root-plugin] which can fix this. Note that when using this plugin the build trigger URL changes, so your command will have to be modified slightly.


```bash
#!/bin/bash
curl http://test-server:8080/buildByToken/build?job=hello-django-trunk&xZrJ5WsSfJkGpNsriOlY4PtQ7hC5olzDhNE
```

More information about using hooks: in [SVN][hooks-svn] and [Git][hooks-git].


#### The actual build script

Here we finally get to the meat of the matter. In the **Build** section we can enter all commands which should be executed to deploy our application to the test server and run tests.

1. In the **Build** section click the **Add build step** button.
2. Select **Execute shell** from the drop-down.
3. Adjust the following script to your needs and enter it in the **Command** text area:

```bash
#!/bin/bash
source /webapps/hello_django/activate     # Activate the virtualenv
cd /webapps/hello_django/trunk/
python manage.py migrate                  # Apply South's database migrations
python manage.py compilemessages          # Create translation files
python manage.py collectstatic --noinput  # Collect static files
sudo apachectl graceful                   # Restart the server, e.g. Apache
python manage.py test app1 app2 app3 app4 # Run the tests
```

#### Send emails when tests fail

If a commit causes our tests to fail, we want to alert the guilty commiter. 

1. In the **Post-build Actions** section click the **Add post-build action** button.
2. Select **E-mail Notification** from the dropdown.
3. Check the box **Send separate e-mails to individuals who broke the build**.
4. Click **Save** the bottom of the screen.

> %tip%
> There is an important caveat here. Emails will be sent to addresses which combine the SVN username and a default domain suffix. This means that your users will need to have mailboxes (or aliases) in the same domain named as their SVN users are. For example, if my SVN username is `michal`, I would have to have the e-mail `michal@email-server`.

### Set up Jenkins to send emails

1. Navigate to **Jenkins** > **Manage Jenkins** > **Configure System**.
2. Scroll down to the **E-mail Notification** section.
3. Set **Default user e-mail suffix** to `@email-server` where `email-server` is the fully. qualified domain name of your organization's mail system.
4. Click the **Advanced** button and enter your SMTP server configuration to allow the Jenkins user to send email.
5. Check the box **Test configuration by sending test e-mail** and send yourself a message to test the settings.

OK, we're done. From now on, whenever code is submitted to your repository, Jenkins should pick it up, deploy your Django application, run tests and alert the commiter if something he did broke a test. 

> %tip%
> If your test server is available outside of your trusted network, make sure you proceed to [lock it down tight][jenkins-security].

[jenkins]: http://jenkins-ci.org/ "Jenkins - An extendable open source continuous integration server"
[jenkins-installation]: https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins "Installing Jenkins"
[jenkins-security]: https://wiki.jenkins-ci.org/display/JENKINS/Securing+Jenkins "Securing Jenkins"
[jenkins-basic-security]: https://wiki.jenkins-ci.org/display/JENKINS/Standard+Security+Setup "Standard Security Setup"
[jenkins-proxy]: https://wiki.jenkins-ci.org/display/JENKINS/Installing+Jenkins+on+Ubuntu#InstallingJenkinsonUbuntu-SettingupanApacheProxyforport80\%3E8080 "Setting up a proxy for Jenkins"
[jenkins-git-plugin]: https://wiki.jenkins-ci.org/display/JENKINS/Git+Plugin "Git Plugin"
[jenkins-build-token-root-plugin]: https://wiki.jenkins-ci.org/display/JENKINS/Build+Token+Root+Plugin "Build Token Root Plugin"
[blog-django-nginx]: /blog/2013/06/09/django-nginx-gunicorn-virtualenv-supervisor/ "Setting up Django with Nginx, Gunicorn, virtualenv, supervisor and PostgreSQL"
[hooks-svn]: http://svnbook.red-bean.com/nightly/en/svn.reposadmin.create.html
[hooks-git]: http://git-scm.com/book/ch7-3.html