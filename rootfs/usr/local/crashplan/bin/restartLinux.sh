#!/bin/sh

APP_NAME="CrashPlanService"
APP_DESC="CrashPlan Engine"

CRASHPLAN_DIR=/usr/local/crashplan

LOG_FILE="$CRASHPLAN_DIR/log/restart.`date +'%Y-%m-%d_%H.%M.%S'`.log"

_findpid() {
    /bin/ps -o pid,args | grep "$APP_NAME" | grep -v grep | awk '{ print $1 }'
}

_log() {
    echo "$(date) : $*" >> $LOG_FILE 2>&1
}

_exit() {
    EXIT_CODE=$?

    _log "Exiting restart script"
    sleep 1

    exit $?
}
trap _exit EXIT

_log "$(pwd)/$(basename $0)"

_log "Stopping $APP_DESC ... "
PID_TO_KILL=`_findpid`
if [ -n "$PID_TO_KILL" ]; then
    kill $PID_TO_KILL
    for i in $(seq 1 10); do
        sleep 1
        PID=`_findpid`
        if [ -z "$PID" ] || [ "$PID" != "$PID_TO_KILL" ]; then
            break
        fi
    done
fi
PID=`_findpid`
if [ -n "$PID" ] && [ "$PID" = "$PID_TO_KILL" ]; then
    _log "Still running, killing PID=$PID ... "
    kill -9 $PID
    sleep 2
fi
PID=`_findpid`
if [ -n "$PID" ] && [ "$PID" = "$PID_TO_KILL" ]; then
    _log "ERROR: Failed to kill $APP_DESC (PID $PID_TO_KILL)"
    exit 1
else
    _log "OK"
fi

_log "Waiting for $APP_DESC to be restarted automatically ..."
for i in $(seq 1 30); do
    PID=`_findpid`
    if [ -n "$PID" ]; then
        break
    fi
    sleep 1
done
if [ -n "$PID" ]; then
   _log "New $APP_DESC process started with PID $PID"
else
    _log "ERROR: $APP_DESC process not started after 30 seconds"
    exit 1
fi
