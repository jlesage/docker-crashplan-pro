#!/bin/sh

trap "exit" TERM QUIT INT
trap "kill_cp" EXIT

kill_cp() {
    RC=$?
    if [ -n "${CP_PID:-}" ]; then
        kill "$CP_PID"
        wait $CP_PID
        exit $?
    fi
    exit $RC
}

while true
do
    # Start CrashPlan.
    /usr/local/crashplan/bin/startCrashPlanGUI.sh &

    # Wait until it dies.
    CP_PID=$!
    wait $CP_PID
    RC=$?
    CP_PID=

    # Exit now if exit was not requested by user.
    if [ ! -f /tmp/.cp_restart_requested ]; then
        exit $RC
    fi

    rm /tmp/.cp_restart_requested
done

# vim: set ft=sh :
