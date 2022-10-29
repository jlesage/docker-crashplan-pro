#!/bin/sh

while true
do
    # Start CrashPlan.
    /usr/local/crashplan/bin/startCrashPlanGUI.sh &

    # Wait until it dies.
    wait $!
    RC=$?

    # Exit now if exit was not requested by user.
    if [ ! -f /tmp/.cp_restart_requested ]; then
        exit $RC
    fi

    rm /tmp/.cp_restart_requested
done

# vim: set ft=sh :
