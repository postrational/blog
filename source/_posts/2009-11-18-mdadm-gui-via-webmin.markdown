---
layout: post
title: "mdadm GUI - A graphical interface to Linux software RAID via Webmin"
date: "2009-11-18"
permalink: "/blog/2009/11/18/mdadm-gui-via-webmin/"
comments: true
categories: tech
published: true
tags: 
---

Anybody who cares about their data understands, that data "is not safe, unless it exists in at least two copies". This redundancy can be achieved by keeping various backups, but it's clear that the only backup scheme which works is the "set it and forget it" kind. If you are technical enough to build your own NAS, or if you run Linux on your desktop, you probably know about [RAID](http://en.wikipedia.org/wiki/RAID), [fake RAID](https://help.ubuntu.com/community/FakeRaidHowto), and [software RAID](http://en.wikipedia.org/wiki/Software_RAID). Using RAID makes your backup strategy completely transparent and your data safe and happy.

<!-- more -->

#### mdadm
[mdadm](http://en.wikipedia.org/wiki/mdadm) is a wonderful Linux utility, which allows you to [set up a software RAID array](http://unthought.net/Software-RAID.HOWTO/Software-RAID.HOWTO.html). Despite the fact that there is a registered [Sourceforge project called mdadm-GUI](http://sourceforge.net/projects/mdadm-gui/), there is no code in it and it seems that no work is currently being done. This leaves us without a graphical user interface to mdadm. This is especially hard on new users, because the CLI commands for monitoring your array give rather cryptic results.

    $ cat /proc/mdstat
    Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
    md0 : active raid1 sda1[0] sdb1[1]
          730660160 blocks [2/2] [UU]
      
    unused devices: <none>
    
    $ sudo mdadm -D /dev/md0
    /dev/md0:
            Version : 00.90
      Creation Time : Mon Jan  5 16:49:53 2009
         Raid Level : raid1
         Array Size : 730660160 (696.81 GiB 748.20 GB)
      Used Dev Size : 730660160 (696.81 GiB 748.20 GB)
       Raid Devices : 2
      Total Devices : 2
    Preferred Minor : 0
        Persistence : Superblock is persistent

        Update Time : Sun Oct 18 15:27:20 2009
              State : active
     Active Devices : 2
    Working Devices : 2
     Failed Devices : 0
      Spare Devices : 0

               UUID : ae9a0180:107c7d2a:85e38229:c66e1e31
             Events : 0.4541759

        Number   Major   Minor   RaidDevice State
           0       8        1        0      active sync   /dev/sda1
           1       8       17        1      active sync   /dev/sdb1



#### Installing Webmin
A GUI for mdadm is provided by [Webmin](http://www.webmin.com/), the browser-based administrative suite. Installation on a Debian-based Linux distribution, such as Ubuntu is trivial.

**1) Add the appropriate repository to your apt.sources list.**  
On Ubuntu, create the following file: `/etc/apt/sources.list.d/webmin.list` and add the following lines to it:

    # Repository for Webmin
    deb http://download.webmin.com/download/repository sarge contrib


**2) Update your APT cache and install**  
Issue the following commands:

    $ sudo apt-get update
    $ sudo apt-get install webmin


**3) Visit your Webmin administration panel**  
Use your browser to access your webmin panel at the following url: <https://localhost:10000>


#### mdadm through Webmin
To administer the Software RAID using webmin login as a sudo-er, go to the page `Hardware > Linux RAID` and play around.

<div class="figure">
<img src="/images/illustrations/2009-11-18/mdadm-gui-via-webmin-1.jpg">
</div>

<div class="figure">
<img src="/images/illustrations/2009-11-18/mdadm-gui-via-webmin-2.jpg">
</div>