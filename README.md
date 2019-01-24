Redmine Git Mirror plugin
==================

Adds ability to clone and fetch remote git repositories to redmine.

## Key Features
* Easy install (just clone to redmine plugins folder)
* Webhooks integration (gitlab and custom)
* Works well with enabled autofetch changesets setting and in mix with other scm types  
* Automatic deletes unreachable commits

## Install

    cd [redmine_root]/plugins
    git clone https://github.com/linniksa/redmine_git_mirror

Restart redmine, and enable `Git Mirror` scm type at `redmine.site/settings?tab=repositories`

You should add ```./bin/rails runner "Repository::GitMirror.fetch"``` script to cronjobs. 

## GitLab integration

You can setup per-project or system wide hook to `redmine.site/sys/git_mirror/gitlab`, 
anable WS support in redmine at `redmine.site/settings?tab=repositories` and specify api-key as Secret of webhook.
It's allow redmine to immediately fetch changes pushed to gitlab.

###### For per-project setup

Select only `Push` and `Tags` events

###### For system wide setup

Select only `Repository update events`
