= cabar/example/README.txt

This directory contains examples for Cabar.

There are three cabar component repositories:

* dev - development: a development workspace.
* plat - platform: a collection of components making a software platform.
* prod - production: a production workspace.

This overlay of componnt repositories demonstrates how a developer can 
edit local versions of a component while still using other
 components from other repositories.

For example, "dev/" and "prod/" both contain versions of the "c2" component and
"dev/c2" directories overlay on "prod/c2" versions 1.1 and 1.2.

= Environment variables

bin/cbr_env sets basic CABAR_* environment variables for the cbr
command, namely:

* CABAR_PATH: overlays dev/, plat/ and prod/ directories.
* CABAR_CONFIG: example/cabar_config.yml

Run "bin/cbr_env --env" to see what it sets.

= Dot Graphs

Cabar can generate graphs of component dependencies.

run "rake" and then browse to the example/doc directory with an SVG viewer.

