# rancher-deploy-script

These scripts do have some custom things going on in them, but I'm sure you'll be able to take some value from them if you're trying to get up and running with Jenkins/Docker/Rancher.

It may that at some point in the future, or maybe even now, Rancher release a CLI that makes this a lot easier, but right now, these are the scripts I wrote to get working what I needed working.

Feel free to ask questions in issues if you're using these and are unsure about something.

## Known issues

* If you have multiple services with the same name but in different stacks in the same environment, this script will not be able to pick the correct one as it only grabs the first result of services that match a name. Consider not doing that.
