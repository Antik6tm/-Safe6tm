#!/bin/bash

LOG_DIR="logs"
mkdir -p "$LOG_DIR"

echo "Début du scan complet de sécurité."

./run_security_checks.sh
./monitor_rsyslog.sh
./check_security_alerts.sh
./notify_security_alerts.sh

echo "Scan complet terminé."
exit 0
