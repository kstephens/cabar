cabar/example/README.txt

This directory contains examples for Cabar.

There are three cabar component repositories:

dev - development: a development workspace.
plat - platform: a collection of components making a software platform.
prod - production: a production workspace.

This overlay of componnt repositories demonstrates how a developer can 
edit local versions of a component while still using other
 components from other repositories.

For example, "dev/" and "prod/" both contain versions of the "c2" component and
"dev/c2" directories overlay on "prod/c2" versions 1.1 and 1.2.

bin/cbr_env sets basic CABAR_* environment variables for the cbr
command, namely:

CABAR_PATH: overlays dev/, plat/ and prod/ directories.
CABAR_CONFIG: example/cabar_config.yml
CABAR_TOP_LEVEL: specifies that c1 should be required by default.

