---
date: 2019-07-11
layout: post
categories:
 - tech
tags:
  - open-source
  - python
  - tooling
  - europython
comments: true
---

# From Python script to open-source project

Talk discussing state-of-the-art tools and techniques to convert your script into a full open-source project.

Slides for a [presentation][abstract] I gave the [EuroPython 2019][ep] conference in Basel, Switzerland.

<script defer class="speakerdeck-embed" data-id="db98b61862a0408c9eee0c3ed1fff241" data-ratio="1.7777777777777777" src="//speakerdeck.com/assets/embed.js"></script>

<!-- more -->

## Abstract

The Python community has a rich set of tools which can help verify the quality of your code through automated code-review and linting. You can benefit by taking advantage of this ecosystem. Complete the steps in this checklist, and your project will be easier to maintain, you'll be ready to take contributions from the community and those contributions will be up to high standards. Your project will also keep up with other projects on PyPI and you will be alerted if any new release causes an incompatibility with your code.

The same checklist can be used for non open-source projects as well.

The project maturity checklist includes:

* Properly structure your code
* Use a setup.py file
* Add entry_points for your script command
* Create a requirements.txt file
* Use Black to format your code
* Create a tox.ini config and include code linters
* Set up a Git repo
* Refactor your code to be unit-testable and add tests
* Add missing docstrings
* Add type annotations and a MyPy verification step
* Upload to GitHub
* Add a continuous integration service (e.g. Travis)
* Add a requirements updater (e.g. pyup.bot)
* Add test coverage checker (e.g. coveralls)
* Add a Readme file and documentation
* Publish your project on PyPI
* Advertise your project

## Talk recording

<iframe width="560" height="315" src="https://www.youtube.com/embed/25P5apB4XWM?si=VYdUblKvNAO_y2ZJ" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>


## Related article

For more information check out this [blog post](2019-05-26-python-project-maturity-checklist.md).

[ep]: https://ep2019.europython.eu/
[abstract]: https://ep2019.europython.eu/conference/talks/cqCkLpC-from-python-script-to-open-source-project.html
