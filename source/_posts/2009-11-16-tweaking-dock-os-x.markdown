---
layout: post
title: "Tweaking the Dock in OS X"
date: "2009-11-16"
permalink: "/blog/2009/11/16/tweaking-dock-os-x/"
comments: true
categories: tech
published: true
tags: 
---

The Dock in OS X has quite a few hidden features, which are not accessible through its simple System Preferences panel. Here are some of them.

<!-- more -->

### Pin Point
You can pin the Dock to the left or right edge of your screen (or top/bottom if your dock is on the side of the screen). To do this, you can use these commands:

    #Pin Dock to the left/top edge:
    defaults write com.apple.dock pinning -string start
    killall Dock
    
    #Pin Dock to the right/bottom edge:
    defaults write com.apple.dock pinning -string end
    killall Dock
    
    #Reset to default:
    defaults delete com.apple.dock pinning
    killall Dock


### Spacers
If you want to add spacers, to divide your Dock'ed applications into groups you can use the following command. This will add one empty spacer to the end of your Dock, which you can reposition or delete like any icon.

    defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}'
    killall Dock


All the above commands modify the Preference List file stored in:  
`~/Library/Preferences/com.apple.Dock.plist`

If you mess something up too much, you can remove this file and re-start with an empty Dock.


**More info:**  
<http://www.usingmac.com/2007/12/6/leopard-tweaking-another-terminal-commands>