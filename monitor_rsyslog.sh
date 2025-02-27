#!/bin/bash

LOG_DIR="logs"
ALERT_LOG="$LOG_DIR/system_alerts.log"
mkdir -p "$LOG_DIR"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Vérification des logs système." >> "$ALERT_LOG"

# Vérification de l'existence des logs avant de les scanner
[[ -f "/var/log/syslog" ]] && grep -Ei "fail|error|critical|denied|unauthorized|intrusion|warning" /var/log/syslog >> "$ALERT_LOG"
[[ -f "/var/log/auth.log" ]] && grep -Ei "fail|error|critical|denied|unauthorized" /var/log/auth.log >> "$ALERT_LOG"
[[ -f "/var/log/kern.log" ]] && grep -Ei "fail|error|critical|denied|unauthorized" /var/log/kern.log >> "$ALERT_LOG"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Surveillance des logs système terminée." >> "$ALERT_LOG"
exit 0
