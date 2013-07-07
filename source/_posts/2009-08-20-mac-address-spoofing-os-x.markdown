---
layout: post
title: "MAC address spoofing on OS X"
date: "2009-08-20"
permalink: "/blog/2009/08/20/mac-address-spoofing-os-x/"
comments: true
categories: tech
published: true
tags: 
---

Sometimes you need to connect to a network, which is designed to only allow connections from certain network interface cards, filtered by their [MAC address](http://en.wikipedia.org/wiki/MAC_address). This filtering can be avoided by changing or [spoofing](http://en.wikipedia.org/wiki/Spoofing_attack) your computer's MAC.

    sudo ifconfig en0 lladdr 00:00:00:00:00:00 # <- the new MAC address
    sudo ifconfig en0 down
    sudo ifconfig en0 up

Your original Media Access Control address will be restored after a reboot.