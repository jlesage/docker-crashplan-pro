#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Generate machine id.
echo "Generating machine-id..."
cat /proc/sys/kernel/random/uuid | tr -d '-' > /etc/machine-id

# Set a home directory in passwd, needed by the engine.
sed-patch "s|app:x:$USER_ID:$GROUP_ID::/dev/null:|app:x:$USER_ID:$GROUP_ID::/config:|" /etc/passwd && \

# Make sure required directories exist.
mkdir -p /config/bin
mkdir -p /config/log
mkdir -p /config/cache
mkdir -p /config/var
mkdir -p /config/repository

# Install default configuration if needed.
cp -pr /defaults/conf /config/
[ -f /config/bin/run.conf ] || cp /defaults/run.conf /config/bin/run.conf

# Update CrashPlan Engine max memory if needed.
if [ "${CRASHPLAN_SRV_MAX_MEM:-UNSET}" != "UNSET" ]; then
  if ! echo "$CRASHPLAN_SRV_MAX_MEM" | grep -q "^[0-9]\+[g|G|m|M|k|K]\?$"
  then
    echo "ERROR: Invalid value for CRASHPLAN_SRV_MAX_MEM variable: '$CRASHPLAN_SRV_MAX_MEM'"
    exit 1
  fi

  CUR_MEM_VAL="$(cat /config/bin/run.conf | sed -n 's/.*SRV_JAVA_OPTS=.* -Xmx\([0-9]\+[g|G|m|M|k|K]\?\) .*$/\1/p')"
  if [ "$CRASHPLAN_SRV_MAX_MEM" != "$CUR_MEM_VAL" ]
  then
    echo "Updating CrashPlan Engine maximum memory from $CUR_MEM_VAL to $CRASHPLAN_SRV_MAX_MEM."
    sed -i "s/^\(SRV_JAVA_OPTS=.* -Xmx\)[0-9]\+[g|G|m|M|k|K]\? /\1$CRASHPLAN_SRV_MAX_MEM /" /config/bin/run.conf
  fi
fi

# Clear some log files.
rm -f /config/log/engine_output.log \
      /config/log/engine_error.log \
      /config/log/ui_output.log \
      /config/log/ui_error.log

# Make sure monitored log files exist.
for LOGFILE in /config/log/service.log.0 /config/log/app.log
do
    [ -f "$LOGFILE" ] || touch "$LOGFILE"
done

# Adjust ownership of /config.
chown -R $USER_ID:$GROUP_ID /config

# vim: set ft=sh :
