---
date: 2022-07-14
layout: post
categories:
 - tech
tags:
  - machine learning
  - hydra
  - mlflow
  - europython
comments: true
---

# Managing ML experiment configurations with Hydra

Talk about managing complex data science experiment configurations with [Hydra](https://hydra.cc/).

Slides for a [presentation][abstract] I gave the [EuroPython 2022][ep] conference in Dublin, Ireland.

<script defer class="speakerdeck-embed" data-id="c5ccbeeffa084f238529b281d1098975" data-ratio="1.7777777777777777" src="//speakerdeck.com/assets/embed.js"></script>

<!-- more -->

## Abstract

Data science experiments have a lot of moving parts. Datasets, models, hyperparameters all have multiple knobs and dials. This means that keeping track of the exact parameter values can be tedious or error prone.

Thankfully you're not the only ones facing this problem and solutions are becoming available. One of them is Hydra from Meta AI Research. Hydra is an open-source application framework, which helps you handle complex configurations in an easy and elegant way. Experiments written with Hydra are traceable and reproducible with minimal boilerplate code.

In my talk I will go over the main features of Hydra and the OmegaConf configuration system it is based on. I will show examples of elegant code written with Hydra and talk about ways to integrate it with other open-source tools such as MLFlow.

## Talk recording

<iframe width="560" height="315" src="https://www.youtube.com/embed/bNGu8A6F3-8?si=xp_Xc9HJu3ocSjI8" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>


[ep]: https://ep2022.europython.eu/
[abstract]: https://ep2022.europython.eu/session/managing-complex-data-science-experiment-configurations-with-hydra/
