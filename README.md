# feed2thread

I've joined the [POSSE](https://justin.searls.co/posse) and publish as much as I can
to [justin.searls.co](https://justin.searls.co) and syndicate it elsewhere. Just
like I use [feed2toot](https://feed2toot.readthedocs.io/en/latest/) to
cross-post my web site's posts to Mastodon, I wanted to cross-post to Threads as
well, so I made this thing that reads from an Atom XML feed and generates
Threads posts. It's meant to be run on a schedule (e.g.
[cron](https://en.wikipedia.org/wiki/Cron) job) to regularly check the feed, and
does its best to avoid double-posts by keeping track of post URLs that have
already been processed in a local cache file.

## Prerequisites

If you've done this whole dance to post to Instagram, prepare to be delighted
by how much simpler Meta made it for the Threads API:

1. [Create a Facebook developer account](https://developers.facebook.com/docs/development/register/)
2. [Create an app with the Threads use case](https://developers.facebook.com/docs/development/create-an-app/threads-use-case). Make sure it has these permissions:
    * `threads_basic`
    * `threads_content_publish`
3. Add your Threads account as a [Threads Test User](https://developers.facebook.com/docs/development/create-an-app/threads-use-case#step-8--user-tokens-for-testing), accept the Web Permissions invite, then generating a user access token
4. Click on the test user to find its Threads User ID, noted here as a `THREADS_USER_ID`
5. With that access token, (set here to a `THREADS_ACCESS_TOKEN` env var)

## What this gem does

To get an idea of what this gem is doing under the hood, namely it will:

1. Trade whatever access token you hand it for a [refreshed long-lived token](https://developers.facebook.com/docs/threads/get-started/long-lived-tokens#refresh-a-long-lived-token), and then save that updated/refreshed token to your feed2thread configuration (long-lived tokens expire after 60 days and must be refreshed before they expire or else you need to generate a new one; keep this in mind if you don't plan to run `feed2thread` continuously or if the configuration file isn't writable)
2. Load your Atom feed and for each `<entry>` collect the `<title>` as the thread's text and URL of its `<link rel="alternate">` as the unique ID of the post
3. For each such entry, [create a threads media container](https://developers.facebook.com/docs/threads/posts#single-thread-posts)
5. Once the container is created, [publish it](https://developers.facebook.com/docs/threads/posts#step-2--publish-a-threads-media-container)
6. Success or failure, save a cache entry that indicates the URL of the entry was processed so we don't repeatedly post (or fail to post) the same thing over and over again

## Install and usage

```
$ gem install feed2thread
```

Next, create a configuration file in YAML to tell feed2thread everything it needs
to run. Make sure this file is writable, as the gem will refresh the facebook
access token on each run:

```yaml
feed_url: https://example.com/feed.xml
threads_user_id: 9000
access_token: EAADXD
```

If the above were saved as `feed2thread.yml`, we could then run the app from
the command line:

```
$ feed2thread
```

In addition to overwriting the `access_token` in your configuration
file, a `feed2thread.cache.yml` will also be created (or updated) in the same
directory. This file is used internally by feed2thread to keep track of which
entry URLs in the atom feed have been processed and can be ignored on the next
run.

## Options

For available options, run `feed2thread --help`:

```
$ feed2thread --help
Usage: feed2thread [options]
  --config PATH        Path of feed2thread YAML configuration (default: feed2thread.yml)
  --cache-path PATH    Path of feed2thread's cache file to track processed entries (default: feed2thread.cache.yml)
  --limit POST_COUNT   Max number of Instagram posts to create on this run (default: unlimited)
  --skip-token-refresh Don't attempt to exchange the access token for a new long-lived access token
  --populate-cache     Populate the cache file with any posts found in the feed WITHOUT posting them to Instagram
```

## Running continuously with Docker

We publish a Docker image [using GitHub
actions](https://github.com/searls/feed2thread/blob/main/.github/workflows/main.yml)
tagged as `latest` for every new commit to the `main` branch, as well as with a
release tag tracking every release of the gem on
[rubygems.org](https://rubygems.org). The images are hosted [here on GitHub's
container
registry](https://github.com/searls/feed2thread/pkgs/container/feed2thread)


You can also use Docker to run this on your own automation platform like Proxmox or Kubernetes.

```
$ docker run --rm -it \
  -v ./your_config_dir:/srv/config
  ghcr.io/searls/feed2thread
```

To configure the container, there are just four things to know:

1. A volume containing your configuration and cache files must be mounted to `/config`
2. By default, feed2thread will run with `--config /config/feed2thread.yml`, but you can
customize this by configuring the command value as needed
3. By default, feed2thread is run as a daemon every 60 seconds, and that duration can be overridden
by setting a `SLEEP_TIME` environment variable to the number of seconds you'd like
to wait between runs
4. If you'd rather run `feed2thread` as ad hoc as opposed to via the included daemon
(presumably to handle scheduling it yourself), simply change the entrypoint to
`/srv/exe/feed2thread`

### Running the docker image specifically on your Synology NAS

I run this on my [Synology DS 920+](https://www.pcmag.com/reviews/synology-diskstation-ds920-plus), using the [DSM's Container Manager](https://www.synology.com/en-global/dsm/feature/container-manager) app.

There are just a few things to know to set this up:

At the time of this writing, the `Action > Import > Add from URL` feature of the Container Manager's
"Image" tab does not support GitHub Container Registry URLs. However, if you connect [via SSH](https://kb.synology.com/en-my/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet):

```
$ sudo -s
# Enter your user password.
$ docker pull ghcr.io/searls/feed2thread:latest
```

Once downloaded, the image will appear in the app. From there, select
`ghcr.io/searls/feed2thread`, hit Run, and complete the wizard, setting any custom
command line flags (once the container is created, this cannot be edited), as
well as choosing a location to mount the `/config` volume and setting a
`SLEEP_TIME` environment variable (these can be changed after the fact).

## Frequently Asked Questions

### Why didn't my post show up?

Look at your cache file (by default, `feed2thread.cache.yml`) and you should see
all the Atom feed entry URLs that succeeded, failed, or were (by the `--populate-cache` option) skipped. If you don't see the error in the log, try
removing the relevant URL from the cache and running `feed2thread` again.

