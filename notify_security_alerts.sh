#!/bin/bash

ALERT_LOG="logs/security_alerts.log"
SYS_ALERT_LOG="logs/system_alerts.log"
NOTIFY_FILE="security_alert.txt"

if grep -qE "INFECTED|Warning|Infected|MODIFIED|fail|error|critical|denied|unauthorized|intrusion" "$ALERT_LOG" "$SYS_ALERT_LOG"; then
    echo "Alerte de sécurité détectée !" > "$NOTIFY_FILE"
    echo "Consultez $ALERT_LOG et $SYS_ALERT_LOG pour plus d'informations."
else
    rm -f "$NOTIFY_FILE"
fi
exit 0
