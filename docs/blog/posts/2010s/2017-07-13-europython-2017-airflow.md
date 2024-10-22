---
title: Elegant workflows with Apache Airflow
date: 2017-07-13T14:35:00
layout: post
categories:
  - tech
tags:
  - python
  - airflow
  - workflow
  - graphs
comments: true
---

# Elegant workflows with Apache Airflow

Talk about developing powerful workflows in Python code with [Apache Airflow][airflow].

Slides for a [presentation][abstract] I gave the [EuroPython 2017][ep] conference in Rimini, Italy.

<script async class="speakerdeck-embed" data-id="895cc9f6ed0b4545b27ac1d9ece68b68" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

<!-- more -->

## Abstract

Every time a new batch of data comes in, you start a set of tasks. Some tasks can run in parallel, some must run in a sequence, perhaps on a number of different machines. That’s a workflow.

Did you ever draw a block diagram of your workflow? Imagine you could bring that diagram to life and actually run it as it looks on the whiteboard. With Airflow you can just about do that.

Apache Airflow is an open-source Python tool for orchestrating data processing pipelines. In each workflow tasks are arranged into a directed acyclic graph (DAG). Shape of this graph decides the overall logic of the workflow. A DAG can have many branches and you can decide which of them to follow and which to skip at execution time.

This creates a resilient design because each task can be retried multiple times if an error occurs. Airflow can even be stopped entirely and running workflows will resume by restarting the last unfinished task. Logs for each task are stored separately and are easily accessible through a friendly web UI.

In my talk I will go over basic Airflow concepts and through examples demonstrate how easy it is to define your own workflows in Python code. We’ll also go over ways to extend Airflow by adding custom task operators, sensors and plugins.

## Talk recording

<iframe width="560" height="315" src="https://www.youtube.com/embed/XJf-f56JbFM?si=t6Njz4UkXWiBV-R2" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>

## Related article

You can read more about developing workflows with Apache Airflow in my [previous article][related].


[ep]: https://ep2017.europython.eu/en/
[abstract]: https://ep2017.europython.eu/conference/talks/developing-elegant-workflows-in-python-code-with-apache-airflow
[airflow]: https://airflow.apache.org/
[related]: /blog/2017/03/19/developing-workflows-with-apache-airflow/