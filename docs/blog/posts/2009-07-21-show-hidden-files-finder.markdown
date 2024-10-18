---
title: Show hidden files in the Finder
date: 2009-07-21
slug: show-hidden-files-finder
layout: post
categories:
  - tech
comments: true
---

It's sometimes necessary to view and manipulate files hidden in your system. Unfortunately the Mac OS X  file browser, the Finder, does not display these files by default and has no easy way to access this option. This simple hack allows you to choose whether hidden files are displayed or not.

<!-- more -->

### Method
In order to change this setting, launch the Terminal and paste in the following command:  

    defaults write com.apple.Finder AppleShowAllFiles YES

The next thing you'll need to do is to restart the Finder. You can quit the Finder by issuing this command:  

    killall Finder
    
The Finder should restart automatically, if it does not, you can launch it from the Dock.

### Explanation
This command updates the user's [defaults database](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/defaults.1.html) with the value `YES`. The updated variable is called `AppleShowAllFiles` and is stored in this file: `~/Library/Preferences/com.apple.finder.plist`

You can read the current value of the variable by issuing this command:  
`defaults read com.apple.Finder AppleShowAllFiles`

You can also access this variable by using the [Property List Editor](http://osx.iusethis.com/app/propertylisteditor) to edit the mentioned file. The Property List Editor is a part of [Apple Developer Tools](http://en.wikipedia.org/wiki/Apple_Developer_Tools).


### Undo
As you can probably guess, you can prevent hidden files from being shown, by setting the value back to `NO`.

    defaults write com.apple.Finder AppleShowAllFiles NO
    killall Finder