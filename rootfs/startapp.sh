#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

export SWT_GTK3=0
export LD_LIBRARY_PATH=$CRASHPLAN_DIR

FULL_CP="$CRASHPLAN_DIR/lib/com.backup42.desktop.jar:$CRASHPLAN_DIR/lang:$CRASHPLAN_DIR/skin:$CRASHPLAN_DIR"

source $CRASHPLAN_DIR/bin/run.conf

cd $CRASHPLAN_DIR
exec ${JAVACOMMON} ${GUI_JAVA_OPTS} -classpath $FULL_CP com.backup42.desktop.CPDesktop >> /config/log/ui_output.log 2>> /config/log/ui_error.log

# vim: set ft=sh :
