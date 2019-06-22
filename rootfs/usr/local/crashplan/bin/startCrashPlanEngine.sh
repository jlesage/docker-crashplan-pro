#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

export CRASHPLAN_DIR=/usr/local/crashplan

export LD_PRELOAD=$CRASHPLAN_DIR/uname_wrapper.so
export LD_LIBRARY_PATH=$CRASHPLAN_DIR

export JAVACOMMON="$CRASHPLAN_DIR/jre/bin/java"

cd $CRASHPLAN_DIR
exec $CRASHPLAN_DIR/bin/CrashPlanService

# vim: set ft=sh :
