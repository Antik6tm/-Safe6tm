#!/bin/bash

ALERT_LOG="logs/security_alerts.log"
SYS_ALERT_LOG="logs/system_alerts.log"
NOTIFY_FILE="$HOME/Desktop/security_alert.txt"

# Vérification de l'existence des fichiers de logs
if [[ ! -f "$ALERT_LOG" ]] || [[ ! -f "$SYS_ALERT_LOG" ]]; then
    echo "Erreur : Les fichiers de logs d'alerte n'existent pas." > "$NOTIFY_FILE"
    exit 1
fi

# Vérification des alertes de sécurité
if grep -qE "INFECTED|Warning|Infected|MODIFIED|fail|error|critical|denied|unauthorized|intrusion" "$ALERT_LOG" "$SYS_ALERT_LOG"; then
    echo "Alerte de sécurité détectée !" > "$NOTIFY_FILE"
    echo "Consultez $ALERT_LOG et $SYS_ALERT_LOG pour plus d'informations." >> "$NOTIFY_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Alerte détectée !" >> "$LOG_DIR/monitoring.log"
else
    rm -f "$NOTIFY_FILE"
fi
exit 0

