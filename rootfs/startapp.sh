#!/usr/bin/with-contenv sh

#
# CrashPlan is not shutting down when receiving a signal, unless it is sent
# twice.
#
# This small wrapper is used to prevent CrashPlan to receive termination
# signals directly.  Instead, the wrapper traps signals and send CTRL+q key
# presses to CrashPlan, allowing the application to terminate.
#

exit_crashplan() {
    xdotool key "Escape"
    xdotool key "ctrl+q"
}
trap 'exit_crashplan $PID' TERM INT QUIT

# Start CrashPlan in background.
/usr/local/crashplan/bin/startCrashPlanGUI.sh &

# And wait for its termination.
PID=$!
wait $PID

# Exit this script.
EXIT_STATUS=$?
exit $EXIT_STATUS

# vim: set ft=sh :
