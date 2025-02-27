#!/bin/bash

ALERT_LOG="logs/security_alerts.log"
> "$ALERT_LOG"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Vérification des alertes de sécurité." >> "$ALERT_LOG"

grep "INFECTED" logs/chkrootkit.log >> "$ALERT_LOG"
grep "Warning" logs/rkhunter.log >> "$ALERT_LOG"
grep "Infected" logs/clamav.log >> "$ALERT_LOG"

echo "[Fichiers modifiés - debsums]" >> "$ALERT_LOG"
wc -l < logs/debsums.log >> "$ALERT_LOG"

echo "[Audit - Lynis]" >> "$ALERT_LOG"
grep -E "Warning|Suggestion|[0-9]+.*finding" logs/lynis.log >> "$ALERT_LOG"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Vérification terminée." >> "$ALERT_LOG"
exit 0
