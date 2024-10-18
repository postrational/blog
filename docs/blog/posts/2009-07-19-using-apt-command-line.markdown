---
title: Using APT from the command line
date: 2009-07-19
slug: using-apt-command-line
layout: post
categories:
  - tech
comments: true
---

Debian's [Advanced Packaging Tool (APT)](http://en.wikipedia.org/wiki/Advanced_Packaging_Tool) has been ported over to Ubuntu and many other Linux distributions. There are many useful graphical user interfaces to the system such as [Synaptic](http://en.wikipedia.org/wiki/Synaptic_Package_Manager), but sometimes it's faster or easier to use it from the command line. Here's how.

<!-- more -->

#### Installing
Searching the APT cache to find which package to install. If you want to install APPLICATION_NAME:  
`apt-cache search APPLICATION_NAME`

Installing the appropriate package:  
`sudo apt-get install PACKAGE`


#### Inspecting
Listing all installed packages:  
`dpkg -l`

Finding which package contains FILE:  
`dpkg -S FILE`


#### Upgrading
Update the lists of available packages:  
`sudo apt-get update`

Upgrade all installed packages to the latest available versions:  
`sudo apt-get upgrade`