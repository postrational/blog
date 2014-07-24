## Michał's Octopress Blog

### Documentation

Octopress is [Jekyll](https://github.com/mojombo/jekyll) blogging at its finest.
Check out [Octopress.org](http://octopress.org/docs) for guides and documentation.

### Installing Octopress dependencies

    sudo gem install bundler
    brew update
    brew install rbenv ruby-build
    rbenv init
    rbenv rehash
    bundle install
    bundle exec rake generate ...

### Common tasks

#### Creating a new post or page

    bundle exec rake new_page\["page title"\]
    bundle exec rake new_post\["post title"\]

#### Remember this if you run into encoding problems

    export LANG=en_US.utf-8

#### Preview your site

    bundle exec rake preview
    bundle exec rake generate
    python -m SimpleHTTPServer 8080

#### Generate site files and deploy

    bundle exec rake generate && bundle exec rake watch
    bundle exec rake isolate\["about-me"\]
    bundle exec rake integrate
    bundle exec rake generate 
    bundle exec rake watch
    bundle exec rake deploy

#### Commit changes to Repo

    git commit -m 'Customization'
    git push

#### Update Octopress engine

    git pull octopress master     # Get the latest Octopress
    bundle install                # Keep gems updated
    rake update_source            # update the template's source
    rake update_style             # update the template's style

More info: http://octopress.org/docs/updating/

