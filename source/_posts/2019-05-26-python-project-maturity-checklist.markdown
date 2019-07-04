---
layout: post
title: "Python project maturity checklist"
date: 2019-05-26 12:03
permalink: "/blog/2019/05/26/python-project-maturity-checklist/"
comments: true
categories: tech
published: true
tags: python tooling validation testing
---

Did you write a cool and useful Python script? Would you like to share it with the community, but you're not sure how to go about that? If so, then this is the article for you. We'll go over a list of simple steps which can turn your script into a fully fledged open-source project.

<!-- more -->

The Python community has created a rich ecosystem of tools, which can help you during the development and upkeep of your project. Complete the steps in this checklist, and your project will be easier to maintain and you'll be ready to take contributions from the community.

This is an opinionated article. I will run though a long list of tools and practices, I've had good experience with. Some of your favorite tools may be left out, some of my choices you may find unnecessary. Feel free to adapt the list to your liking and leave a comment below.


| Project maturity checklist
:-------:|:--------------------------------------------------:
 &#9744; | [Define your command-line interface (CLI)](#define-cli)
 &#9744; | [Structure your code](#structure-code)
 &#9744; | [Write a `setup.py` file](#setup-py)
 &#9744; | [Add `entry_points` for your script command](#entry-points)
 &#9744; | [Create a `requirements.txt` file](#requirements-txt)
 &#9744; | [Set up a Git repo](#git-repo)
 &#9744; | [Use Black to format your code](#use-black)
 &#9744; | [pre-commit hooks](#pre-commit)
 &#9744; | [Code linters](#code-linters)
 &#9744; | [Create a `tox.ini` config](#tox-ini)
 &#9744; | [Write unit-tests](#unit-tests)
 &#9744; | [Add `docstrings` and documentation](#docstrings)
 &#9744; | [Type annotations and MyPy](#type-annotations)
 &#9744; | [Upload to GitHub](#upload-to-github)
 &#9744; | [README and LICENSE files](#readme-and-license)
 &#9744; | [Continuous integration service](#continuous-integration)
 &#9744; | [Requirements updater](#requirements-updater)
 &#9744; | [Test coverage checker](#coverage-checker)
 &#9744; | [Automated code review](#code-review)
 &#9744; | [Publish your project on PyPI](#publish-on-pypi)
 &#9744; | [Advertise your project](#advertise)


> %tip%
> You can download a printable [PDF version](/images/illustrations/2019-05-26/Project_maturity_checklist.pdf) of the checklist.

I tried to complete the entire checklist in my small open-source project named [`gym-demo`][gym-demo]. Feel free to use it as a reference and submit PRs if you find room for improvement.


<a name="define-cli"></a>
### &#9745; Define your command-line interface (CLI)

If you're going to provide a command-line utility, then you need to define a friendly command-line user interface. Your interface will be more intuitive for users if it follows the [GNU conventions for command line arguments][cli_conventions].

There are many ways to parse command line arguments, but my favorite by far is to use the [`docopt` module][docopt_python] developed by [Vladimir Keleshev][docopt_presentation]. It allows you to define your entire interface in the form of a docstring at the beginning of your script, like so:


```python
"""Usage: gym_demo.py [--steps=NN --no-render --observations] ENV_NAME
Show a random agent playing in a given OpenAI environment.
Arguments:
  ENV_NAME          Name of the Gym environment to run
Options:
  -h --help
  --steps=<STEPS>   How many iteration to run for.  [default: 5000]
  --no-render       Don't render the environment graphically.
  --observations    Print environment observations.
"""
```

Later you can just call the `docopt(__doc__)` command and use the argument values:

```python
import docopt

arguments = docopt(__doc__)
steps = int(arguments.get("--steps"))
render_env = not arguments.get("--no-render")
print_observations = arguments.get("--observations")
env_name = arguments.get("ENV_NAME")
```

> %tip%
> I usually start with Docopt by copying one of the [examples][docopt_examples] and modifying it to my needs.


<a name="structure-code"></a>
### &#9745;  Structure your code

Python has established conventions for most things, this includes the layout of your code directory and naming of some files and directories. Follow these conventions to make your project easier to understand by other Python developers.

#### Code layout

The basic directory structure of your project should resemble this:

    package-name
    ├── LICENSE
    ├── README.md
    ├── main_module_name
    │   ├── __init__.py
    │   └── main.py
    ├── tests
    │   └── test_main.py
    ├── requirements.txt
    └── setup.py

The `package-name` directory contains all of the sources of your package. Usually this is the root directory of your project repository, containing all other files. Choose your package name wisely and check if it's available on PyPI, as this will be the name people will use to install your package using:

    pip install package-name

The `main_module_name` directory is the directory which will be copied
into your user's `site-packages` when your package is installed. You can
define more than one module if you need to, but it's good practice to
nest them under a single module with an identifiable name.

According to the [Python style guide PEP8][pep8_package_names]:

> Modules should have short, all-lowercase names. Underscores can be used in the module name if it improves readability. Python packages should also have short, all-lowercase names, although the use of underscores is discouraged.

If possible, the name of your package and the name of it's main module should be the same. Since underscores are discouraged in package names, you can use `my-project` as the package name and `my_project` as the main module name.

#### Code structure

Whether you're writing code in Python or any other language, you should follow [Clean Code principals][clean_code_book]. One of the most important ideas behind clean code it to split up your logic into short functions, each with a single responsibility.

Your functions should take zero, one or at most two arguments. If your
functions have more than 2 parameters, that's a well known code-smell.
It indicates that your function is probably trying to do more than one
thing and you should split it up into smaller sub-functions.

> %tip%
> Still need more than two parameters? Perhaps your function parameters are related and should come into your function as a single data structure? Or perhaps you should refactor your code so your functions become methods of an object?

In Python, you can sometimes get away with more than two parameters, if you specify default values for the extra ones. This is better, but you should still consider if the function shouldn't be split.

Small functions with a single responsibility and few parameters are easy to write unit-tests for. We'll come back to this.

#### Define a `__main__` function

If you're writing a command-line utility, you should create a separate function which handles the parsing of user input and initiating the logic of your utility. You can call this function `main()` or anything else you think fits.

This logic should be placed in the `__main__` block of your script:

```python
if __name__ == "__main__":
    main()
```

> %tip%
> The condition `__name__ == "__main__"` is only true if you're calling the script directly. It's not true if you include the same Python file as a library module: `from my_module import main`.

The advantage of splitting the main logic into a separate `main()` function is that you'll be able to use the `main` function as an entry point. We'll come back to this when talking about `entry_points`.


<a name="setup-py"></a>
###  &#9745; Write a `setup.py` file

Python has a mature and well maintained packaging utility called `setuptools`. A `setup.py` file is the build script for `setuptools` and every Python project should have one.

Writing a basic `setup.py` file is very easy, all the file has to do is to call the `setup` method with appropriate information about your project.

This example comes from my [`gym-demo`][gym-demo] project:

```python setup.py
    #!/usr/bin/env python
    import os

    from setuptools import setup

    setup(
        name="gym-demo",
        version="0.2.1",
        description="Explore OpenAI Gym environments.",
        long_description=open(
            os.path.join(os.path.abspath(os.path.dirname(__file__)), "README.md")
        ).read(),
        long_description_content_type="text/markdown",
        author="Michal Karzynski",
        author_email="github@karzyn.com",
        packages=["gym_demo"],
        install_requires=["setuptools", "docopt"],
    )
```

The example above assumes you have a `long_description` of your project in a markdown `README.md` file in the same directory. If you don't, you can specify `long_description` as a string.

More information can be found in the [Python packaging tutorial][packaging_tutorial].

#### Using a `setup.py` file

Once you have a `setup.py` file, you can use it to build your Python project's distribution packages like so:

    $ pip install setuptools wheel
    $ python setup.py sdist
    $ python setup.py bdist_wheel

The `sdist` command creates a source distribution (such as a tarball or zip file with Python source code). `bdist_wheel` creates a binary Wheel distribution file which your users may download from PyPI in the future. Both distribution files will be placed in the `dist` subdirectory. 

> %tip%
> The `bdist_wheel` command comes from the `wheel` package.

During development another `setup.py` command is even more useful:

    $ source my_venv/bin/activate
    (my_venv)$ python setup.py develop

This command installs your project inside a [virtual environment][packaging_tutorial_venv] named `my_venv`, but it does so without copying any files. It links your source directory with your `site-packages` directory by creating a link file (such as `my-project.egg-link`). This is very useful, because you can work on your source code directly and test it in your virtual env without reinstalling the project after each change.

You can find out about other `setup.py` commands by running:

    $ python setup.py --help-commands

> %tip%
> If you're not using [virtual environments][packaging_tutorial_venv] you're missing out. <br>
> I would also recommend using [`virtualenvwrapper`][virtualenvwrapper] tools. <br>
> Alternatively you can switch to the new [`pipenv`][pipenv] tool.

[packaging_tutorial]: https://packaging.python.org/tutorials/packaging-projects/ "Packaging Python Projects"
[packaging_tutorial_venv]: https://packaging.python.org/tutorials/installing-packages/#creating-virtual-environments "Creating Virtual Environments"
[virtualenvwrapper]: https://virtualenvwrapper.readthedocs.io/en/latest/ "virtualenvwrapper - a set of extensions virtualenv"
[pipenv]: https://github.com/pypa/pipenv "Pipenv: Python Development Workflow for Humans"


<a name="entry-points"></a>
###  &#9745; Add `entry_points` for your script command

If you're writing a command-line utility, you should create a console script entry point for your command. This will create an executable launcher for your script, which users can easily call at the command line.

To do this, just add an `entry_points` argument to the `setup()` call in your `setup.py` file.  For example, the following `console_scripts` entry will create an executable named `my-command` (or `my-command.exe` on Windows) and place it in the `bin` path of your environment. This means your users can just use `my-command` after they install your package.

```python setup.py
setup(
    # other arguments here...
    entry_points={"console_scripts": ["my-command = my_module.main:main"]},
)
```
`my_module.main:main` specifies which function to call and where to find it. `my_module.main` specifies the path to the Python file `main.py` in `my_module`. And `:main` denotes the `main()` function inside `main.py`. This is the "Python path" syntax and if you know which PEP it's defined in, leave me a note in the comments. Thanks.

> %tip%
> There are other cool things `entry_points` can do. You can use it to [customize build commands][entry_points_setup_commands] of `setup.py` and even to [distribute discoverable services][entry_points_services] for other tools (such as parsers for a specific file format, etc.).

Read more about [automated script creation][entry_points_script_creation] in the `setuptools` [docs][entry_points_script_creation].


<a name="requirements-txt"></a>
###  &#9745; Create a `requirements.txt` file

You should provide your users with information about which other packages your package will require to work properly. The right place to put this information is inside `setup.py` as an `install_requires` list.

```python setup.py
setup(
    # other arguments here...
    install_requires=["colorful", "docopt"],
)
```

It's also very useful to inform your users which versions of each dependency you tested your package with. A good way to do this is to add a `requirements.txt` file in your repository. The file should contain the list of your dependencies along with version numbers, for example:

```text requirements.txt
colorful==0.5.0
docopt==0.6.2
```

Users can then install these precise versions of your dependencies by running:

    $ pip install -r requirements.txt

> %tip%
> It may be useful to create a separate `requirements_test.txt` file for dependencies used only during testing and development.

The easiest way to generate a `requirements.txt` file is to run the `pip freeze` command. Be careful with this though, as it will list all installed packages, whether they are dependencies of your package, the dependencies of these dependencies, or simply unrelated packages you installed in your environment.


<a name="git-repo"></a>
###  &#9745; Set up a Git repo

It's time to put your code under source-control. Everyone is using Git these days, so let's roll with it.

Let's start by adding a Python-specific `.gitignore` file to the root of your project.

    $ curl https://raw.githubusercontent.com/github/gitignore/master/Python.gitignore > .gitignore

You can now create your repo and add all files:

    $ git init
    $ git add --all

Verify that only files you want are being added to the repo with `git status` and create your initial commit.

    $ git commit -m 'Initial commit'

More sample `.gitignore` files may be found in the [GitHub gitignore repo][gitignore].


<a name="use-black"></a>
###  &#9745; Use Black to format your code

The Python community is very lucky for many reasons and one of them is the early adoption of a common code-style guide [the PEP8][pep8]. This is a great blessing, because we don't have to argue which coding style is better, we don't have to define a different style for each project, in each company, etc. We have PEP8 and we should all just stick to PEP8.

To that end, Łukasz Langa crated [Black][black_github] - the uncompromising code formatter. You should install it, run it over your code and then re-run before every commit. Using Black is as easy as:

    (my_venv) $ pip install black
    (my_venv) $ black my_module
    All done! ✨ 🍰 ✨
    1 file reformatted, 7 files left unchanged.

You may disagree with some of the formatting decisions [Black][black_github] makes. I would say, that it's better to have a consistent style, rather then a prettier, but inconsistent one. Let's just all use Black and get along. ☺


<a name="pre-commit"></a>
###  &#9745; Set up pre-commit hooks

The best way to run Black and any other code formatters is to use [`pre-commit`][pre_commit]. This is a tool which is triggered every time you `git commit` and runs code-linters and formatters on any modified files.

Install `pre-commit` as usual:

    (my_venv) $ pip install pre-commit

You configure `pre-commit` by creating a file named `.pre-commit-config.yaml` in the root directory of your project. A simple configuration, which only runs black would look like this:

```yaml .pre-commit-config.yaml
repos:
- repo: https://github.com/ambv/black
  rev: stable
  hooks:
    - id: black
```

You can generate a sample config by calling `pre-commit sample-config`.

Set up a Git pre-commit hook by calling `pre-commit install`.

From now on, each time you run `git commit` Black will be called to check your style. If your style is off, `pre-commit` will prevent you form committing your code and `black` will reformat it.

    (my_venv) $ git commit
    black....................................................................Failed
    hookid: black
    
    Files were modified by this hook. Additional output:
    
    reformatted gym_demo/demo.py
    All done! ✨ 🍰 ✨
    1 file reformatted.

Now simply re-add the reformatted file with `git add` and commit again.


<a name="code-linters"></a>
###  &#9745; Code linters

Python has a great set of code linters, which can help you avoid making common mistakes and keep your style in line with PEP8 and other standard conventions. Many of these tools are maintained by the [Python Code Quality Authority][pycqa].

My favorite Python linting tool is [Flake8][flake8], which checks for compliance with PEP8. It's base functionality can be extended by installing some of its [many plugins][flake8_plugins]. My favorite Flake8 plugins are listed below. 

```text requirements_test.txt
flake8
flake8-blind-except
flake8-bugbear
flake8-builtins
flake8-comprehensions
flake8-debugger
flake8-docstrings
flake8-isort
flake8-quotes
flake8-string-format
```

Once you install all those packages, you can simply run `flake8` to check your code.

```console
(my_venv) $ flake8
./my_package/my_module.py:1:1: D100 Missing docstring in public module
``` 

You can [configure Flake8][flake8_configuration] by adding a `[flake8]` configuration section to `setup.cfg`, `tox.ini`, or `.flake8` files in your project's root directory.

```ini tox.ini
[flake8]
max-line-length=88
max-complexity=6
inline-quotes=double
; ignore:
; C812 - Missing trailing comma
; C813 - Missing trailing comma in Python 3
; D104 - Missing docstring in public package
ignore=C812,C813,D104
```

There are other code linters you may find interesting. For example [Bugbear][flake8_bugbear] finds common sources of bugs, while [Bandit][bandit] finds common security issues in Python code. You can use them both as a [Flake8 plugins][flake8_bandit] of course.


<a name="tox-ini"></a>
###  &#9745; Create a `tox.ini` config

[`tox`][tox] is a great tool, which aims to standardize testing in Python. You can use it to setup a virtual environment for testing your project, create a package, install the package along with its dependencies and then run tests and linters. All of this is automated, so you just need to type one `tox` command.

```console
$ tox
GLOB sdist-make: my-project/setup.py
py3 create: my-project/.tox/py3
py3 installdeps: -Urrequirements.txt, -Urrequirements_test.txt
py3 inst: my-project/.tox/.tmp/package/1/my-project-0.0.1.zip
py3 installed: flake8==3.7.7,flake8-comprehensions==2.1.0,flake8-debugger==3.1.0,flake8-docstrings==1.3.0,my-project==0.0.1
py3 run-test-pre: PYTHONHASHSEED='1354964057'
py3 run-test: commands[0] | flake8 my_project
__________________________________________________________________________________________________________________________________________________________ summary ___________________________________________________________________________________________________________________________________________________________
  py3: commands succeeded
  congratulations :)
```

`tox` is quite configurable, so you can decide which commands are executed or use your `requirements.txt` by creating a `tox.ini` configuration file. The following simple example runs `flake8` and `pytest` in a Python3 venv.

```ini tox.ini
[tox]
envlist=py3

[testenv]
deps=
  -Urrequirements.txt
  -Urrequirements_test.txt
commands=
  flake8
  pytest tests/

[pytest]
timeout=300

[flake8]
max-line-length=88
max-complexity=6
inline-quotes=double
; ignore:
; C812 - Missing trailing comma
; C813 - Missing trailing comma in Python 3
; D104 - Missing docstring in public package
ignore=C812,C813,D104,D400,E203
```

> %tip%
> You can use `tox` to easily run tests on multiple Python versions if they are installed in your system. Just extend the `envlist`, e.g. `envlist=py35,py36,py37`. 

If you automate testing using `tox`, you will be able to just run that one command in your continuous integration environment. Make sure you run `tox` on every commit you want to merge.


<a name="unit-tests"></a>
###  &#9745; Refactor your code to be unit-testable and add tests

Using unit tests is one of the best practices you can adopt. Writing unit tests for your function gives you a chance to take one more look your code. Perhaps the function is too complex and should be simplified? Perhaps there's a bug you didn't notice before or an edge-case you didn't consider?

Writing good unit tests is an art and it takes time, but it's an investment which pays off many times over, especially on a large project which you maintain over a long period. For one, unit-tests make refactoring much easier and less scary. Also, you can learn to write your tests before you write your program (test-driven development), which is a very satisfying way to code.

I would recommend using the [PyTest][pytest] framework for writing your unit tests. It's easy to get started with and it's very powerful and configurable. Writing a simple unit-test is as simple as creating a `test` directory with `test_*.py` files. A simple test looks like this:

```python tests/test_main.py
"""Test suite for my-project."""
import pytest
from my_project import my_function

def test_my_function():
    result = my_function()
    assert result == "Hello World!"
```

Running the tests is as simple as typing `pytest`:

```console
(my_venv) $ pip install pytest
(my_venv) $ pytest
=========================== test session starts ===========================
platform darwin -- Python 3.7.2, pytest-4.5.0, py-1.7.0, pluggy-0.11.0
rootdir: my-project, inifile: tox.ini
plugins: timeout-1.3.3, cov-2.7.1
timeout: 300.0s
timeout method: signal
timeout func_only: False
collected 255 items

tests/test_main.py .......                                          [100%]

======================= 7 passed in 0.35 seconds ========================
```

Make sure to add the `pytest` command to your `tox.ini` file.


<a name="docstrings"></a>
###  &#9745; Add `docstrings` and documentation

Writing good documentation is very important for your users. You should start by making sure each function and module are described by a docstring. The docstring should describe what the function should do in an imperative mood sentence. For example:

```python
def hello_world() -> Text:
    """Return a greeting."""
    return("Hello World!")
``` 

The parameters and return values of your functions should also be included in docstrings:

```python
def get_columns_count_and_width(strings: List[Text]) -> Tuple[int, int]:
    """Calculate how to break a list of strings into multiple columns.
    
    Calculate the optimal column width and number of columns 
    to display a list of strings on screen.

    :param strings: list of strings
    :return: a tuple with the number of columns and column width
    """
    ...
```

> %tip%
> Notice, that I'm also using Python3 type annotations to specify parameter and return types.  

Use the `flake8-docstrings` plugin to verify all your functions have a docstring.

If your project grows larger, you will probably want to create a full-fledged documentation site. You can use [Sphinx][sphinx] or the simpler [MkDocs][mk_docs] to generate the documentation and host the site on [Read the docs][read_the_docs] or [GitHub Pages][github_pages]. 


<a name="type-annotations"></a>
###  &#9745; Add type annotations and a MyPy verification step

Python 3.5 added the option to annotate your code with type information. This is a very useful and clean type of documentation and you should use.

For example, `my_function` below takes a unicode string as an argument and returns a `dict` of strings mapping to numeric or textual values. 

```python
def my_function(name: Text) -> Mapping[str, Union[int, float, Text]]:
    ...
```

[Mypy] is the static type checker for Python. If you type-annotate your code, `mypy` will run through it and make sure that you're using the right parameter types when calling functions.

```console
(my_venv) $ mypy --config-file=tox.ini my_module
my_module/main.py:43:27: error: Argument 1 to "my_function" has incompatible type "int"; expected "List[str]"
```

You can add a call to `mypy` to your `tox` configuration to verify that you're not introducing any type-related mistakes in your commits.


<a name="upload-to-github"></a>
###  &#9745; Upload to GitHub

Alright. If you completed all the previous steps and checked all the boxes, your code is ready to be shared with the world!

Most open-source projects are hosted on GitHub, so your project should probably join them. Follow [these instructions][github_repo_instructions] to setup a repo on GitHub and push your project there.

> %tip%
> Microsoft recently acquired GitHub, which makes some people sceptical, if this should still remain the canonical place for open-source projects online. You can consider [GitLab][gitlab] as an alternative. So far however, Microsoft have been good stewards of GitHub.


<a name="readme-and-license"></a>
###  &#9745; Add README and LICENSE files

The first thing people see when they visit your project's repository is the contents of the `README.md` file. GitHub and GitLab do a good job of rendering [Markdown][markdown]-formatted text, so you can include links, tables, pictures, etc.

Make sure you have a README file and that it contains information about:

* what does your project do?
* how to use it (with examples)?
* how can people contribute code to your project?
* what's the license of the code?
* links to other relevant documentation

More tips on writing a README [here][makeareadme].

The other critically important file you should include is `LICENSE`. Without this file, no one will be able to legally use your code.

If you're not sure what license to choose, use the [MIT license][mit_license]. It's just 160 words, read it. It's simple and permissive and lets everyone use your code however they want.

More info about choosing a license [here][choosealicense].

[markdown]: https://daringfireball.net/projects/markdown/syntax "Markdown syntax"
[makeareadme]: https://www.makeareadme.com/
[mit_license]: https://opensource.org/licenses/MIT
[choosealicense]: https://choosealicense.com/


<a name="continuous-integration"></a>
###  &#9745; Add a continuous integration service

OK, now that your project is online and you prepared a `tox` configuration, it's time to set up a continuous integration service. This will run your style-checking, static code analysis and unit-tests on every pull request (PR) made to your repository.

There are many CI services available for free for open-source projects. I'm partial to [Travis][travis] myself, but [Circle CI][circle_ci] or [AppVeyor][appveyor] are commonly used alternatives.

Setting up Travis CI for your repository is as simple as adding a hidden YAML configuration file named `.travis.yaml`. For example, the following installs and runs `tox` on your project in a Linux virtual machine:

```yaml .travis.yaml
language: python
os: linux
install:
  - pip install tox
script: 
  - tox
git:
  depth: false
branches:
  only:
  - "master"
cache:
  directories:
    - $HOME/.cache/pip
```

All you need to do after commiting `.travis.yaml` to your repo, is to log into [Travis][travis] and activate the CI service for your project.

> %tip%
> You can [set up branch protection][github_branch_protection] on `master` to require status checks to pass before a PR can be merged.

If you'd like to run your CI on multiple versions of Python or multiple operating systems, you can set up a test matrix like so: 


```yaml .travis.yaml
matrix:
  include:
  - os: linux
    sudo: false
    python: '3.6'
    script: tox -e py36
  - os: linux
    dist: xenial
    python: '3.7'
    sudo: true
    script: tox -e py37
```

Travis has fairly good [documentation][travis_docs], which explains its many settings with configuration examples. You can test your configuration on a PR, where you modify the `.travis.yaml` file. Travis will rerun its CI job on every change, so you can tweak settings to your liking.

A completed Travis run will look like [this example][travis_example].

[travis]: https://travis-ci.org/
[travis_example]: https://travis-ci.org/postrational/gym-demo/builds/496207768
[travis_docs]: https://docs.travis-ci.com/
[github_branch_protection]: https://help.github.com/en/articles/configuring-protected-branches "GitHub - Configuring protected branches"
[appveyor]: https://www.appveyor.com/
[circle_ci]: https://circleci.com/


<a name="requirements-updater"></a>
###  &#9745; Add a requirements updater

Breaking changes in dependencies are a common problem in all software development. Your code was working just fine a while ago, but if you try to build it today, it fails, because some package it uses changed in an unforeseen way.

One way of working around this is to freeze all the dependency versions in your `requirements.txt` files, but this just puts the problem off into the future.

The best way to deal with changing dependencies it to use a service, which periodically bumps versions in your `requirements.txt` files and creates a pull request with each version change. Your automated CI can test your code against the new dependencies and let you know if you're running into problems.

Single package version changes are usually relatively easy to deal with, so you can fix your code, if needed before updating the dependency version. This allows you to painlessly keep track of the changes in all the projects you depend on.

I use the [PyUp][pyup] service for this. The service requires no configuration, you just need to sign up using your GitHub credentials and activate it for your repository. PyUp will detect you `requirements.txt` files and start issuing PRs to keep dependencies up to date with PyPI.

> %tip%
> There are alternative services, which also do a good job of updating dependencies. GitHub recently acquired [Dependabot][dependabot], which works with Python and other languages and is free for all projects (not only open-source).

[pyup]: https://pyup.io/ "PyUp - Python dependency checker"
[dependabot]: https://dependabot.com/


<a name="coverage-checker"></a>
###  &#9745; Add test coverage checker

Python unit-testing frameworks have the ability to determine which lines and branches of code were hit when running unit tests. This coverage report is very useful, as it lets you know how much of your code is being exercised by tests and which parts are not.

If you install the `pytest-cov` module, you can use the `--cov` argument to `pytest` to generate a coverage report. 

```console
(my_venv) $ pip install pytest pytest-cov
(my_venv) $ pytest --cov=my_module tests/
========================== test session starts ==========================

tests/test_main.py ...................................             [100%]

------------ coverage: platform darwin, python 3.7.2-final-0 ------------
Name                     Stmts   Miss  Cover
--------------------------------------------
my_module/__init__.py        0      0   100%
my_module/main.py           77     17    78%
my_module/utils.py          41      0   100%
--------------------------------------------
TOTAL                      118     17    86%

====================== 255 passed in 1.25 seconds =======================
```

If you add the `--cov-report=html` argument, you can generate an HTML version of the coverage report, which you can find in the `htmlcov/index.html` file after running tests.

    (my_venv) $ pytest --cov=my_module --cov-report=html tests/

#### Track test coverage over time

Online services, such as [Coveralls][coveralls] or [Codecov][codecov] can track your code coverage with every commit and on every pull request. You can decide not to accept PRs which decrease your code coverage. See an [example report here][coveralls_report]. 

In order to start using [Coveralls][coveralls], sign up using your GitHub credentials and set up tracking for your repository. 

You can report your coverage using the [`coveralls-python`][coveralls-python] package, which provides the `coveralls` command. You can test it manually by specifying the `COVERALLS_REPO_TOKEN` environment variable. You can find your token by going to your repository's settings on the Coveralls site.  

```console
(my_venv) $ pip install coveralls
(my_venv) $ pytest --cov=my_module --cov-report=html tests/
(my_venv) $ COVERALLS_REPO_TOKEN=__my_repo_token__ coveralls
Submitting coverage to coveralls.io...
Coverage submitted!
Job #167.2
https://coveralls.io/jobs/49180746
```

When running on Travis, `coveralls` will be able to detect which repository is being tested, so you don't have to (and shouldn't) put `COVERALLS_REPO_TOKEN` into your `tox.ini` file. Instead use the `-` prefix for the command to allow it fail if you are running `tox` locally.

```ini tox.ini
commands=
  ...
  pytest --cov=my_module --cov-report=html tests/
  - coveralls
```

[coveralls]: https://coveralls.io
[coveralls_report]: https://coveralls.io/builds/23741751/source?filename=gym_demo/demo.py
[codecov]: https://codecov.io/gh/codecov 
[coveralls-python]: https://github.com/coveralls-clients/coveralls-python


<a name="code-review"></a>
### &#9745; Automated code review

The best thing you can do when working as a team is to thoroughly review each other's code. You should point out any mistakes, parts of code which are difficult to understand or badly documented, or anything else which doesn't quite smell right.

If you're working alone, or would like another pair of eyes, you can set up one of the services providing automated code review. These services are still evolving and are not providing a huge value yet, but sometimes they catch something your code linters missed.

Setting up a service like [Code Climate Quality][code_climate_quality] or [Codacy][codacy] is very simple. Just set up an account using your GitHub credentials, add your repository and configure your preferences.

A report can look like [this example][codacy_example_report].

[code_climate_quality]: https://codeclimate.com/
[codacy]: https://www.codacy.com/
[codacy_example_report]: https://app.codacy.com/app/postrational/ngraph-onnx/issues?&filters=W3siaWQiOiJMYW5ndWFnZSIsInZhbHVlcyI6WyJQeXRob24iXX0seyJpZCI6IkNhdGVnb3J5IiwidmFsdWVzIjpbbnVsbF19LHsiaWQiOiJMZXZlbCIsInZhbHVlcyI6W251bGxdfSx7ImlkIjoiUGF0dGVybiIsInZhbHVlcyI6W251bGxdfSx7ImlkIjoiQXV0aG9yIiwidmFsdWVzIjpbbnVsbF19XQ==

<a name="publish-on-pypi"></a>
###  &#9745; Publish your project on PyPI

So, now you're ready to publish your project on PyPI. This is quite a simple operation, unless your package is larger than 60MB or you selected a name, which is already taken.

Before you publish a package, create a release version. Start by bumping your version number to a higher value. Make sure you follow the [semantic versioning][semver] rules and add the version number to `setup.py`.

The next step is to [create a release on GitHub][github_release]. This will create a tag you can use to look up the code associated with a specific version of your package.

Now you'll need to set up an account on the [Test version of PyPI][pypi_test]. 

> %tip%
> You should always start by uploading your package to the test version of PyPI. You should then test your package from test PyPI on multiple environments to make sure it works, before posting it on the official PyPI. 

Use the following instructions to create your packages and upload them to test PyPI:


```console
(my_venv) $ pip install twine
(my_venv) $ rm -rf dist       # remove previously built packages, if any exist
(my_venv) $ python setup.py bdist_wheel
(my_venv) $ python setup.py sdist
(my_venv) $ twine check dist/*
Checking distribution dist/my-package-0.2.2-py3-none-any.whl: Passed
Checking distribution dist/my-package-0.2.2.tar.gz: Passed

(my_venv) $ twine upload --repository-url https://test.pypi.org/legacy/ dist/*
Enter your username: my_username
Enter your password:
Uploading distributions to https://test.pypi.org/legacy/
Uploading my_package-0.2.2-py3-none-any.whl
Uploading my-package-0.2.2.tar.gz
```

You can now visit your project page on test PyPI under the URL: 
https://test.pypi.org/project/my-package/

Once you test your package thoroughly, you can repeat the same steps for the official version of PyPI. Just change the upload command to:

    (my_venv) $ twine upload dist/*

Congratulations, your project is now online and fully ready to be used by the community!

[pypi_test]: https://test.pypi.org/
[github_release]: https://help.github.com/en/articles/creating-releases
[semver]: https://semver.org/ "Semantic Versioning"


<a name="advertise"></a>
###  &#9745; Advertise your project

OK, you're done. Take to Twitter, Facebook, LinkedIn or wherever else your potential users and contributors may be and let them know about your project.

Congratulations and good luck!

[gym_demo]: https://github.com/postrational/gym-demo "Explore OpenAI Gym environments"
[cli_conventions]: https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html "CLI Conventions - POSIX with GNU extensions"
[docopt_python]: https://github.com/docopt/docopt "docopt on GitHub"
[docopt_presentation]: https://www.youtube.com/watch?v=pXhcPJK5cMc "PyCon UK 2012: Create *beautiful* command-line interfaces with Python"
[docopt_examples]: https://github.com/docopt/docopt/tree/master/examples "docopt examples on GitHub"
[pep8]: https://www.python.org/dev/peps/pep-0008/ "PEP8: Python style guide"
[pep8_package_names]: https://www.python.org/dev/peps/pep-0008/#package-and-module-names "PEP8: Package and module naming"
[clean_code_book]: https://isbnsearch.org/isbn/9780132350884 "Clean Code by Robert C. Martin"
[entry_points_services]: https://setuptools.readthedocs.io/en/latest/setuptools.html#dynamic-discovery-of-services-and-plugins
[entry_points_setup_commands]: https://setuptools.readthedocs.io/en/latest/setuptools.html#adding-commands
[entry_points_script_creation]: https://setuptools.readthedocs.io/en/latest/setuptools.html#automatic-script-creation
[black_github]: https://github.com/python/black "Black - The Uncompromising Code Formatter"
[pre_commit]: https://pre-commit.com/ 
[gitignore]: https://github.com/github/gitignore "A collection of .gitignore templates"
[flake8]: http://flake8.pycqa.org/en/latest/ "Flake8: Your Tool For Style Guide Enforcement"
[pycqa]: https://github.com/PyCQA "Python Code Quality Authority"
[flake8_plugins]: https://pypi.org/search/?q=flake8 "Search for Flake8 plugins on PyPI"
[flake8_configuration]: https://flake8.pycqa.org/en/latest/user/configuration.html "Configuring Flake8"
[bandit]: https://github.com/PyCQA/bandit "Bandit - find common security issues in Python"
[flake8_bandit]: https://pypi.org/project/flake8-bandit/
[flake8_bugbear]: https://pypi.org/project/flake8-bugbear/
[tox]: https://tox.readthedocs.io/ "tox automation project"
[pytest]: https://docs.pytest.org/ "pytest testing framework"
[mk_docs]: https://www.mkdocs.org/ "MkDocs - Project documentation with Markdown"
[sphinx]: http://www.sphinx-doc.org/ "Sphinx - documenation tool"
[read_the_docs]: https://readthedocs.org/ "Read The Docs - Python free for open-source docs hosting."
[github_pages]: https://pages.github.com/ "GitHub Pages - static sites served from GitHub repos"
[mypy]: https://mypy.readthedocs.io/ "Mypy - static type checker for Python"
[github_repo_instructions]: https://help.github.com/en/articles/create-a-repo
[gitlab]: http://gitlab.com
[gym-demo]: https://github.com/postrational/gym-demo "Explore OpenAI Gym environments"
