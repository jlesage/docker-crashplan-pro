#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

export HOME=/config
export SWT_GTK3=0
export VERSION_5_UI=true
export CRASHPLAN_DIR=/usr/local/crashplan
export LD_PRELOAD=$CRASHPLAN_DIR/nlib/libwrapper.so
export GDK_PIXBUF_MODULE_FILE=/usr/local/crashplan/loaders.cache

cd /config
exec ${CRASHPLAN_DIR}/electron/code42 --no-sandbox >> /config/log/ui_output.log 2>> /config/log/ui_error.log

# vim: set ft=sh :
