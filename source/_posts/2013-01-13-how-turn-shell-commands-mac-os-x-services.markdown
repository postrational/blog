---
layout: post
title: "How to turn shell commands into Mac OS X services"
date: "2013-01-13"
permalink: "/blog/2013/01/13/how-turn-shell-commands-mac-os-x-services/"
comments: true
categories: tech
published: true
tags: 
---

OS X has a nice functionality called services which allow you (and applications you install) to expand the functionality of your system by adding commands, which will be visible in a special menu. Services may also be available in contextual menus, for instance when you right-click on a file or folder in the Finder.

<div class="figure">
<img src="/images/illustrations/2013-01-13/services_menu.png">
<div class="legend">Services menu in Finder</div>
</div>

<!-- more -->

<div class="figure">
<img src="/images/illustrations/2013-01-13/services_context_menu.png">
<div class="legend">A contextual services menu in Finder</div>
</div>

It's easy to create your own service commands using any shell or scripting commands you may already have written in most shell scripting languages, Perl, Python or Ruby.

### How to hide OS X desktop icons 
The command to turn on or off desktop icons in OS X Finder, you need the following commands.

Hide Desktop icons:

    defaults write com.apple.finder CreateDesktop FALSE && killall Finder

Show desktop icons:

    defaults write com.apple.finder CreateDesktop TRUE && killall Finder

In order to turn a command like that into a Finder service, you need just a few simple steps.

#### 1. Launch Automator (from your Applications folder) and when asked to choose a type for your document select "Service".

<div class="figure">
<img src="/images/illustrations/2013-01-13/services_automator_create_service.png">
<div class="legend">Automator - create a new Service</div>
</div>

#### 2. From the library on the left select "Run Shell Script" action from the "Utilities" category. 
Drag-and-drop the action to the space on the right.

#### 3. Set the following parameters:
Service receives: No input in Finder <br />
Shell: /bin/bash <br />
And add your command to the command line.

<div class="figure">
<img src="/images/illustrations/2013-01-13/services_automator_service.png">
<div class="legend">Automator - "Run Shell Script" action</div>
</div>

#### 4. Save the service to a name you choose and you're done.
The service should now appear in the Services menu in the Finder.

<div class="figure">
<img src="/images/illustrations/2013-01-13/services_menu.png">
<div class="legend">Services menu in Finder</div>
</div>

The Services files you create are stored in the following directory: <br />
`~/Library/Services/`