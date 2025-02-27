#!/bin/bash

LOG_DIR="logs"
ALERT_LOG="$LOG_DIR/system_alerts.log"
mkdir -p "$LOG_DIR"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Vérification des logs système." >> "$ALERT_LOG"

grep -Ei "fail|error|critical|denied|unauthorized|intrusion|warning" /var/log/syslog >> "$ALERT_LOG"
grep -Ei "fail|error|critical|denied|unauthorized" /var/log/auth.log >> "$ALERT_LOG"
grep -Ei "fail|error|critical|denied|unauthorized" /var/log/kern.log >> "$ALERT_LOG"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Surveillance des logs système terminée." >> "$ALERT_LOG"
exit 0
