---
layout: post
title: "Recording a website performance test for The Grinder using Chrome DevTools"
date: 2013-09-28
permalink: "/blog/2013/09/28/website-performance-script-for-the-grinder-using-har2grinder/"
comments: true
categories: tech
published: true
tags: performance-testing grinder devtools
---

[The Grinder][grinder] load testing framework is a good tool for stress testing your website or application. It can run tests in parallel on multiple machines, allowing you to check how your application would behave under heavy load. This makes it possible to determine your app's weak points, so you can proceed to optimize them. Unfortunately the [TCPProxy][tcpproxy] component provided with The Grinder sometimes produces flawed testing scripts. 
I created a simple tool called [har2grinder][har2grinder], which produces Grinder test scripts from [HAR][har] files. This allows you to record a browsing session using Chrome's DevTools and then run it in the Grinder.

<!-- more -->


### HTTP Archive (HAR) files

The [HTTP Archive (HAR) files][har] format is able to store a history of HTTP transactions. This allows a web browser to export detailed performance data about web pages it loads. This format is currently a work in progress at the W3C.

Chrome's DevTools allow you to save a history of your browsing including every HTTP request made by the browser during your session. We can convert this record to a script which The Grinder will run multiple times.

### Creating a HAR file using Chrome DevTools

1. Fire up Chrome and open the DevTools.

2. Click the Settings icon 
![Settings icon](/images/illustrations/har2grinder/gear_icon.png) in the bottom right corner and Disable the cache.

3. Open the Network tab of the DevTools.

4. Clear the Network history 
![No entry icon](/images/illustrations/har2grinder/clear_icon.png)

5. Choose the option to Preserve Log upon navigation 
![No entry icon](/images/illustrations/har2grinder/record_icon.png)
(circle icon turns red).

6. Navigate around your site.

    <div class="figure">
    <img src="/images/illustrations/har2grinder/recording_session.png">
    <div class="legend">Copy your recorded browser session in HAR format</div>
    </div>

7. After you navigate to the pages you want to test, right-click on the network history panel and choose **Copy All as HAR**. Save the clipboard to a `.har` file.



### Creating a test script for The Grinder from a HAR file

To convert your recorded navigation to a Grinder test, simply run the `har2grinder` script and redirect its output to a `.py` file.

    $ python har2grinder.py my_website_test.har > my_website_grinder_test.py


### Running tests in The Grinder

Information about using The Grinder can be found in it's [user guide][grinder_manual]. Essentially it boils down to:

1. Download [Grinder binaries from SourceForge][grinder_binaries]
2. Start a GUI console to control your tests using a command such as:

        $ java -classpath lib/grinder.jar net.grinder.Console

3. On the same machine, another machine or a set of machines create a file called `grinder.properties` in the Grinder directory. This will contain the [configuration for Grinder's agents][grinder_properties] which will run your tests:

``` properties grinder.properties
# Which test do you wish to run
grinder.script=my_website_grinder_test.py
# How many tests do you want to run in parallel
grinder.processes=2
grinder.threads=100
# How many times to repeat them
grinder.runs=5
# Specify the IP and port of the host running the console
grinder.consoleHost=127.0.0.1
grinder.consolePort=6372
# Enable logging of test runs for debugging
grinder.logDirectory=log
grinder.numberOfOldLogs=2
```

...and start the agent processes:

    $ java -classpath lib/grinder.jar net.grinder.Grinder grinder.properties

You can now run your performance tests from the Grinder console.


[grinder]: http://grinder.sourceforge.net  "The Grinder, a Java Load Testing Framework"
[grinder_manual]: http://grinder.sourceforge.net/g3/getting-started.html#howtostart "Getting started with The Grinder"
[grinder_binaries]: http://sourceforge.net/projects/grinder/ "Grinder Binaries on SourceForge"
[grinder_properties]: http://grinder.sourceforge.net/g3/properties.html "Grinder Properties file"
[har]: https://dvcs.w3.org/hg/webperf/raw-file/tip/specs/HAR/Overview.html "HTTP Archive (HAR) format"
[tcpproxy]: http://grinder.sourceforge.net/g3/tcpproxy.html "The Grinder's TCPProxy"
[har2grinder]: http://github.com/postrational/har2grinder/ "har2grinder on GitHub"