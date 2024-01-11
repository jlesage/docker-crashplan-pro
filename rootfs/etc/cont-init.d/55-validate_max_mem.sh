#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

if [ "${CRASHPLAN_SRV_MAX_MEM:-UNSET}" = "UNSET" ]; then
    exit 0
fi

if ! echo "$CRASHPLAN_SRV_MAX_MEM" | grep -q "^[0-9]\+[g|G|m|M|k|K]$"
then
  echo "ERROR: invalid value for CRASHPLAN_SRV_MAX_MEM variable: '$CRASHPLAN_SRV_MAX_MEM'."
  exit 1
fi

MEM_VALUE="$(echo "$CRASHPLAN_SRV_MAX_MEM" | sed 's/[^0-9]*//g')"
MEM_UNIT="$(echo "$CRASHPLAN_SRV_MAX_MEM" | sed 's/[0-9]*//g' | tr '[:lower:]' '[:upper:]')"

MEM_UNIT="${MEM_UNIT:-UNSET}"

if [ "$MEM_UNIT" = "G" ]; then
    MEM_VALUE="$(expr "$MEM_VALUE" \* 1024 \* 1024 \* 1024)"
elif [ "$MEM_UNIT" = "M" ]; then
    MEM_VALUE="$(expr "$MEM_VALUE" \* 1024 \* 1024)"
elif [ "$MEM_UNIT" = "K" ]; then
    MEM_VALUE="$(expr "$MEM_VALUE" \* 1024)"
fi

if [ "$MEM_VALUE" -lt $(expr 1024 \* 1024 \* 1024) ]; then
    echo "ERROR: CRASHPLAN_SRV_MAX_MEM variable must have a minimum value of 1024MB (1GB)."
    if [ "$MEM_UNIT" = "UNSET" ]; then
        echo "       Current value ('$CRASHPLAN_SRV_MAX_MEM') doesn't have any unit set.  Verify this is not an oversight."
    fi
    exit 1
fi

# vim:ft=sh:ts=4:sw=4:et:sts=4
