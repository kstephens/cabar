= cabar/example/README.txt

This directory contains examples for Cabar.

There are three cabar component repositories:

* repo/dev - development: a development workspace.
* repo/plat - platform: a collection of components making a software platform.
* repo/prod - production: a production workspace.

This overlay of componnt repositories demonstrates how a developer can 
edit local versions of a component while still using other
 components from other repositories.

For example, "repo/eev/" and "repo/erod/" both contain versions of the "c2" component and
"repo/dev/c2" directories overlay on "repo/prod/c2" versions 1.1 and 1.2.

= Environment variables

bin/cbr_env sets basic CABAR_* environment variables for the cbr
command, namely:

* CABAR_PATH: overlays repo/dev/, repo/plat/ and repo/prod/ directories.
* CABAR_CONFIG: example/cabar_config.yml

Run "bin/cbr_env --env" to see what it sets.

= Dot Graphs

Cabar can generate graphs of component dependencies.

run "rake" and then browse to the example/doc directory with an SVG viewer.

