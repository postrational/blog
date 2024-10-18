---
title: Performance testing Django applications with The Grinder
date: 2014-01-18
slug: performance-testing-django-applications-with-the-grinder
layout: post
categories:
  - tech
tags:
  - django
  - grinder
  - performance-testing
comments: true
---

Performance testing web applications is a little tricky when we want to test features accessible only to logged in users. Automated test recorders intercept session cookies and hardcode them into test scenarios. When we run these tests later, different session IDs are generated and recorded cookie values don't grant access anymore. This text demonstrates how to write a scenario for [The Grinder][grinder] to test a Django application. Tests include user login, submitting CSRF-protected forms and AJAX requests.

<!-- more -->

#### Test scenario example

Let's dive right in. The code below is a sample test scenario for The Grinder. It represents various aspects of interaction between the test agent and your application including:

* logging a user in
* accessing password protected pages and API calls:
    * GETting a page
    * submitting a CSRF-protected form
    * sending an AJAX `XMLHttpRequest`


```python
from net.grinder.script.Grinder import grinder
from net.grinder.script import Test
from net.grinder.plugin.http import HTTPRequest, HTTPPluginControl
from HTTPClient import Cookie, CookieModule, CookiePolicyHandler, NVPair

HOST_DOMAIN = 'example.com'
HOST_URL = 'http://%s' % HOST_DOMAIN


def create_request(test, headers=None):
    request = HTTPRequest()
    if headers: 
        request.headers = headers
    test.record(request)
    return request


def get_csrf_token(thread_context):
    cookies = CookieModule.listAllCookies(thread_context)
    csrftoken = ''
    for cookie in cookies:
        if cookie.getName() == 'csrftoken':
            csrftoken = cookie.getValue()
    return csrftoken


class TestRunner:
    def __call__(self):
        print "O, hai!"
        
        thread_context = HTTPPluginControl.getThreadHTTPClientContext()
        
        create_request(Test(1100, 'Connect to host')).GET(HOST_URL + '/')
        
        create_request(Test(1200, 'Get login page')).GET(HOST_URL + '/login/')
        
        # Log a user in using username, password and CSRF token read from cookie
        create_request(Test(1300, 'Log in user')).POST(HOST_URL + '/login/', (
            NVPair('csrfmiddlewaretoken', get_csrf_token(thread_context)),
            NVPair('username', 'michal'),
            NVPair('password', 'myfakepassword'),
            NVPair('next', '%2F'),))
        
        create_request(Test(1400, 'Access page requiring login')).GET(HOST_URL + '/user/area/')
        
        create_request(Test(1500, 'Post to form requiring login')).POST(HOST_URL + '/user/area/action', (
            NVPair('csrfmiddlewaretoken', get_csrf_token(thread_context)),
            NVPair('param1', 'value'),
            NVPair('param2', 'value')))
        
        # Prepare an "AJAX" request with appropriate headers, indluding CSRF token from cookie
        ajax_request = create_request(Test(1600, 'Send an AJAX request requiring login'), [
            NVPair('X-Requested-With', 'XMLHttpRequest'),
            NVPair('X-CSRFToken', get_csrf_token(thread_context)),
        ])
        ajax_request.POST(HOST_URL + '/user/area/action', (
            NVPair('param1', 'value'),
            NVPair('param2', 'value')))
        
        print "Kthnxbye!"
```



#### How does it work?

Django as well as many other web applications use a simple authentication mechanism. First, the user provides a username and password combination. The application then verifies user data, opens a session and sends a session cookie back to the user. A session ID contained in the cookie uniquely identifies the user's open session. As long as each request from the user comes in accompanied by the cookie, the user is considered logged in, at least until the session expires on the server.

The example test scenario file above depends on The Grinder's ability to parse and resubmit cookies, so you don't actually have to worry about the `sessionid` cookie.


#### A note on CSRF tokens and testing AJAX methods

Another obstacle to overcome when running automated tests on Django are [anti cross-site request forgery tokens][django_csrf]. These tokens are generated dynamically for every form and Django requires that they be submitted with every POST request. 

In the example test scenario we don't parse HTML forms, but instead rely on the fact that Django also sets a cookie with the CSRF token value. We fetch the cookie value (using the `get_csrf_token` function) and submit it as a field named `csrfmiddlewaretoken` in POST data. 

```python
create_request(Test(1500, 'Post to form requiring login')).POST(HOST_URL + '/user/area/action', (
    NVPair('csrfmiddlewaretoken', get_csrf_token(thread_context)),
    NVPair('param1', 'value'),
    NVPair('param2', 'value'),
))
```

We can also simulate AJAX requests by sending appropriate headers, namely `X-Requested-With` and `X-CSRFToken`. The anti-CSRF token value is read from cookie and written in the latter header.

```python
ajax_request = create_request(Test(1600, 'Send an AJAX request requiring login'), [
    NVPair('X-Requested-With', 'XMLHttpRequest'),
    NVPair('X-CSRFToken', get_csrf_token(thread_context)),
])
```

If you're still having trouble with CSRF and keep testing 403 errors instead of your application, you can disable CSRF completely using a small bit of middleware. Just make sure you don't leave this on in production.


```python
class StressTestingMiddleware(object):
    def process_request(self, request):
        setattr(request, '_dont_enforce_csrf_checks', True)
```

#### Final result

When your tests are prepared and properly vetted you can leverage the power of The Grinder to run them from as many parallel agent machines (and/or threads) as you require. Your test output will include execution time statistics for every test step.

<div class="figure">
<img src="/images/illustrations/2014-01-18/sample_grinder_output.png">
<div class="legend">Partial output of a sample test run</div>
</div>

[grinder]: http://grinder.sourceforge.net  "The Grinder, a Java Load Testing Framework"
[django_csrf]: https://docs.djangoproject.com/en/dev/ref/contrib/csrf/ "Django's Cross Site Request Forgery protection"