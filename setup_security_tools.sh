#!/bin/bash

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec sudo."
    exit 1
fi

LOG_FILE="/var/log/setup_security.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Début de l'installation et configuration des outils de sécurité."


# Activation des services
systemctl enable rsyslog
systemctl restart rsyslog

# Configuration de Rsyslog pour séparer les logs critiques
echo "*.crit    /var/log/critical.log" > /etc/rsyslog.d/10-critical.conf
echo "*.*    /var/log/all_logs.log" > /etc/rsyslog.d/20-alllogs.conf
systemctl restart rsyslog

# Rotation des logs
cat <<EOF > /etc/logrotate.d/security_logs
/var/log/critical.log
/var/log/all_logs.log
/var/log/security_scan/*.log
{
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
EOF

log_message "Installation et configuration terminées."
exit 0
