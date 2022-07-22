Redmine Git Mirror plugin [![Build Status](https://travis-ci.org/linniksa/redmine_git_mirror.svg?branch=master)](https://travis-ci.org/linniksa/redmine_git_mirror)
==================

Adds ability to clone and fetch remote git repositories to redmine.

## Key Features
* Easy install (just clone to redmine plugins folder)
* Webhooks integration (gitlab and custom)
* Works well with enabled autofetch changesets setting and in mix with other scm types  
* Automatic deletes unreachable commits

# Install

1. Install the plugin in Redmine’s `plugin` folder:
    ```bash
    cd [redmine-root]/plugins
    git clone https://github.com/linniksa/redmine_git_mirror
    ```

2. From Redmine’s root directory, install the plugin's dependencies:
    ```bash
    cd [redmine-root]
    bundle install --without development test
    ```

3. Restart redmine, and enable `Git Mirror` scm type at `redmine.site/settings?tab=repositories`

## Accessing private repositories

At this moment only ssh access with redmine user ssh key is supported. 

# Fetching changes

This plugin supports 2 ways of fetching changes, via cronjob or via hooks.
You can use only one or both of them together.

## Cronjob

Run ```./bin/rails runner "Repository::GitMirror.fetch"```, for example: 

    5,20,35,50 * * * * cd /usr/src/redmine && ./bin/rails runner "Repository::GitMirror.fetch"  -e production >> log/cron_rake.log 2>&1

## Hooks

Hooks is preferred way because you can immediately see changes of you repository.

### GitLab hooks

You can setup per-project or system wide hook, for both variants use `redmine.site/sys/git_mirror/gitlab` as `URL`

###### For system wide setup

Go to `gitlab.site/admin/hooks`, and select only `Repository update events` trigger.

###### For per-project setup

Go to `gitlab.site/user/project/settings/integrations`, and select only `Push` and `Tags` events

### GitHub hooks

You can setup per-project or group wide hook, for both variants 
use `redmine.site/sys/git_mirror/github` as `Payload URL` and `Just the push event` option.

Don't worry about `Content type` both `application/json` and `application/x-www-form-urlencoded` are supported.
