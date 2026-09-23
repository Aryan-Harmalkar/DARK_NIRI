#!/bin/bash
# clock-info.sh: Provides system timezone, uptime, and NTP sync telemetry for QuickShell Clock

TZ_NAME=""
if [ -L /etc/localtime ]; then
    TZ_NAME=$(readlink -f /etc/localtime 2>/dev/null | sed 's|.*/zoneinfo/||')
fi
if [ -z "$TZ_NAME" ] && command -v timedatectl >/dev/null 2>&1; then
    TZ_NAME=$(timedatectl show --property=Timezone --value 2>/dev/null)
fi
[ -z "$TZ_NAME" ] && TZ_NAME="Local"

TZ_ABBR=$(date +%Z 2>/dev/null || echo "UTC")
TZ_OFFSET=$(date +%:z 2>/dev/null || echo "+00:00")

UPTIME=""
if command -v uptime >/dev/null 2>&1; then
    UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
fi
if [ -z "$UPTIME" ] && [ -r /proc/uptime ]; then
    UPTIME=$(awk '{printf("%dh %dm", $1/3600, ($1%3600)/60)}' /proc/uptime 2>/dev/null)
fi
[ -z "$UPTIME" ] && UPTIME="Unknown"

NTP="no"
if command -v timedatectl >/dev/null 2>&1; then
    NTP_VAL=$(timedatectl show --property=NTPSynchronized --value 2>/dev/null)
    if [ "$NTP_VAL" = "yes" ]; then
        NTP="yes"
    fi
fi

cat <<JSON
{"tz_name":"$TZ_NAME","tz_abbr":"$TZ_ABBR","tz_offset":"$TZ_OFFSET","uptime":"$UPTIME","ntp":"$NTP"}
JSON
