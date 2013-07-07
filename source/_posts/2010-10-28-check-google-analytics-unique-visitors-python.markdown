---
layout: post
title: "Check Google Analytics unique visitors from Python"
date: "2010-10-28"
permalink: "/blog/2010/10/28/check-google-analytics-unique-visitors-python/"
comments: true
categories: tech
published: true
tags: 
---

You may want to check your Google Analytics data programmatically. This allows you to write some logic around your analytics data, such as sending e-mails in certain situations or just providing a status update for you to inspect without the hassle of logging into your account with a browser.

For a simple example, I use a utility called [GeekTool](http://projects.tynsoe.org/en/geektool/) to display certain information, such as [incoming email](http://www.commandlinefu.com/commands/view/3380/), directly on my desktop for quick reference. I decided to also display updates of my Analytics profiles in this way, displaying a daily summary of unique visitors for each site I monitor. The end result looks like this:

<div class="figure">
<img src="/images/illustrations/check-google-analytics-unique-visitors-python-geektool.png">
<div class="legend">Google Analytics unique visitor counters displayed by GeekTool</div>
</div>

<!-- more -->

### Install the Google Data APIs Python Client Library
Visit the [gdata-python-client](http://code.google.com/p/gdata-python-client/) page, grab the latest version and install.

    wget http://gdata-python-client.googlecode.com/files/gdata-2.0.17.tar.gz
    tar -xzf gdata-2.0.17.tar.gz
    cd gdata-2.0.17
    sudo python setup.py install
    

### Test the installation
Test that the installation was success full by downloading the [`account_feed_demo.py`](http://gdata-python-client.googlecode.com/hg/samples/analytics/account_feed_demo.py) script and running it.

    curl -o account_feed_demo.py http://gdata-python-client.googlecode.com/hg/samples/analytics/account_feed_demo.py
    python account_feed_demo.py

Follow the onscreen instructions and try to log into your account.


### Design your query
If you want to display yesterday's unique visitors, then you can follow this tutorial directly. The only piece of data you will need is the ID of your website profile's table in Google Analytics. If you successfully logged in with the `account_feed_demo.py` script, then it displayed, among other things the following information:

    -------- First 1000 Profiles in Account Feed --------
    Web Property ID = UA-ACCOUNT_ID-4
    Account Name    = ACCOUNT_NAME
    Account Id      = ACCOUNT_ID
    Profile Name    = michal.karzynski.pl
    Profile ID      = PROFILE_ID
    Table ID        = ga:TABLE_ID
    
What you will need to make the below script work is just your `TABLE_ID` or a list of these IDs for each site you want to monitor.

You may display all sorts of other data from Google Analytics and other Google services. There's a very useful utility, which allows you to design a data request for the `gdata` API, called [`gdataExplorer`](http://code.google.com/apis/analytics/docs/gdata/gdataExplorer.html). Visit that page if you want to display other types of data.


### Connect with Google's gdata API using Python
This is the script which can collect your unique visitor counts from Analytics. It's faily straight forward, but if you have questions, leave them in the comments.

<pre><code class="python">
#!/usr/bin/python
# (CC-by) 2010 Copyleft Michal Karzynski, GenomikaStudio.com 
import datetime
import gdata.analytics.client
import gdata.sample_util

email="YOUREMAILADDRESS@gmail.com"  # Set these values
password="YOUREMAILPASSWORD"
table_ids = (
            'ga:TABLE_ID',          # TABLE_ID for first website
            'ga:TABLE_ID',          # TABLE_ID for second website
                                    # (...)
            )

SOURCE_APP_NAME = 'Genomika-Google-Analytics-Quick-Client-v1'
client = gdata.analytics.client.AnalyticsClient(source=SOURCE_APP_NAME)
client.client_login(email, password, source=SOURCE_APP_NAME, service=client.auth_service)

today = datetime.date.today()
yesterday = today - datetime.timedelta(days=1)

print "Visitors yesterday"
for table_id in table_ids:   
    data_query = gdata.analytics.client.DataFeedQuery({
            'ids': table_id,
            'start-date': yesterday.isoformat(),
            'end-date': yesterday.isoformat(),
            'dimensions': 'ga:date',
            'metrics': 'ga:visitors'})
    feed = client.GetDataFeed(data_query)
    print "%s : %s" % (feed.data_source[0].table_name.text, feed.entry[0].metric[0].value)
    

</code></pre>



### Security disclaimer
The above script is a simple example of how to connect to your Google profile using your email/password for authentication. For security reasons, I wouldn't recommend storing your password in cleartext anywhere other then on your personal computer. Authenticating properly, using OAuth is a bit more complex. There is a [very nice write up of using Google's OAuth on Mikhail Panchenko's blog](http://mihasya.com/blog/google-data-api-with-oauth-using-the-gdata-python-client/)...