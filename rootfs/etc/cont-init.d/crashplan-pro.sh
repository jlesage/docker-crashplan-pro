#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

get_cp_max_mem() {
    if [ -f "$1" ]; then
        cat "$1" | sed -n 's/.*<javaMemoryHeapMax>\(.*\)<\/javaMemoryHeapMax>.*/\1/p'
    fi
}

# Generate machine id.
# NOTE: CrashPlan requires the machine-id to be the same to avoid re-login.
# Thus, it needs to be saved into the config directory.
if [ ! -f /config/machine-id ]; then
    log "generating machine-id..."
    cat /proc/sys/kernel/random/uuid | tr -d '-' > /config/machine-id
fi
ln -sf /config/machine-id /etc/machine-id

# Set a home directory in passwd, needed by the engine.
sed-patch "s|app:x:$USER_ID:$GROUP_ID::/dev/null:|app:x:$USER_ID:$GROUP_ID::/config:|" /etc/passwd && \

# Make sure required directories exist.
mkdir -p /config/bin
mkdir -p /config/log
mkdir -p /config/cache
mkdir -p /config/var
mkdir -p /config/repository/metadata
mkdir -p /config/.code42

# Redirect log directory.
ln -sf /config/log /config/.code42/log

# Determine if it's a first/initial installation or an upgrade.
FIRST_INSTALL=0
UPGRADE=0
if [ ! -d /config/conf ]; then
    log "handling initial run..."
    FIRST_INSTALL=1
elif [ ! -f /config/cp_version ]; then
    log "handling upgrade to CrashPlan version $(cat /defaults/cp_version)..."
    UPGRADE=1
elif [ "$(cat /config/cp_version)" != "$(cat /defaults/cp_version)" ]; then
    log "handling upgrade from CrashPlan version $(cat /config/cp_version) to $(cat /defaults/cp_version)..."
    UPGRADE=1
fi

# Install defaults.
if [ "$FIRST_INSTALL" -eq 1 ] || [ "$UPGRADE" -eq 1 ]; then
    # Copy default config files.
    cp -r /defaults/conf /config/

    # Set the current CrashPlan version.
    cp /defaults/cp_version /config/

    # Clear the cache.
    rm -rf /config/cache/*
fi

# run.conf was used before CrashPlan 7.0.0.
if [ -f /config/bin/run.conf ]; then
    mv /config/bin/run.conf /config/bin/run.conf.old
fi

# Update CrashPlan Engine max memory if needed.
if [ "${CRASHPLAN_SRV_MAX_MEM:-UNSET}" != "UNSET" ]; then
  # Validate the max memory value.
  if ! echo "$CRASHPLAN_SRV_MAX_MEM" | grep -q "^[0-9]\+[g|G|m|M|k|K]\?$"
  then
    log "ERROR: invalid value for CRASHPLAN_SRV_MAX_MEM variable: '$CRASHPLAN_SRV_MAX_MEM'."
    exit 1
  fi

  # Convert the max memory value to megabytes.
  MEM_VALUE="$(echo "$CRASHPLAN_SRV_MAX_MEM" | sed 's/[^0-9]*//g')"
  MEM_UNIT="$(echo "$CRASHPLAN_SRV_MAX_MEM" | sed 's/[0-9]*//g' | tr '[:lower:]' '[:upper:]')"
  if [ "${MEM_UNIT:-UNSET}" == "G" ]; then
    CRASHPLAN_SRV_MAX_MEM="$(expr "$MEM_VALUE" \* 1024)m"
  elif [ "${MEM_UNIT:-UNSET}" == "K" ]; then
    CRASHPLAN_SRV_MAX_MEM="$(expr "$MEM_VALUE" / 1024)m"
  fi

  CUR_MEM_VAL=UNSET
  if [ -f /config/conf/my.service.xml ]; then
    SRV_FILE="/config/conf/my.service.xml"
    CUR_MEM_VAL="$(get_cp_max_mem /config/conf/my.service.xml)"
  else
    SRV_FILE="/config/conf/default.service.xml"
  fi

  # Update the configuration file if the value changed.
  if [ "${CUR_MEM_VAL:-UNSET}" != "$CRASHPLAN_SRV_MAX_MEM" ]
  then
    if [ "${CUR_MEM_VAL:-UNSET}" == "UNSET" ]; then
      log "updating CrashPlan Engine maximum memory to $CRASHPLAN_SRV_MAX_MEM"
    else
      log "updating CrashPlan Engine maximum memory from $CUR_MEM_VAL to $CRASHPLAN_SRV_MAX_MEM"
    fi
    sed -i "s/<javaMemoryHeapMax.*/<javaMemoryHeapMax>$CRASHPLAN_SRV_MAX_MEM<\/javaMemoryHeapMax>/" "$SRV_FILE"
  fi
fi

# On some systems (e.g QNAP NAS), instead of the loopback IP address
# (127.0.0.1), the IP address of the host is used by the CrashPlan UI to connect
# to the engine.  This connection cannot succeed when using the Docker `bridge`
# network mode.
# Make sure to fix this situation by forcing the loopback IP address in
# concerned configuration files.
if [ -f /config/conf/my.service.xml ]; then
    sed -i 's|<serviceHost>.*</serviceHost>|<serviceHost>127.0.0.1</serviceHost>|' /config/conf/my.service.xml
fi
if [ -f /config/var/.ui_info ]; then
    sed -i 's|,[0-9.]\+$|,127.0.0.1|' /config/var/.ui_info
fi

# Clear some log files.
rm -f /config/log/engine_output.log \
      /config/log/engine_error.log \
      /config/log/ui_output.log \
      /config/log/ui_error.log

# Make sure monitored log files exist.
for LOGFILE in /config/log/service.log /config/log/app.log
do
    [ -f "$LOGFILE" ] || touch "$LOGFILE"
done

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# vim: set ft=sh :
