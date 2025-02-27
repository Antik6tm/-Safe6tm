#!/bin/bash

LOG_DIR="logs"
mkdir -p "$LOG_DIR"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Début du scan de sécurité." >> "$LOG_DIR/monitoring.log"

# Correction de l'erreur WEB_CMD pour Rkhunter
sudo sed -i 's|^WEB_CMD="/bin/false"|WEB_CMD=""|' /etc/rkhunter.conf

# Vérification des rootkits
chkrootkit > "$LOG_DIR/chkrootkit.log"

rkhunter --update
rkhunter --propupd
rkhunter --check --sk > "$LOG_DIR/rkhunter.log"

# Scan antivirus (Mise à jour de la base)
freshclam

# Scan complet désactivé (trop lent)
# clamscan --infected --recursive --bell --log="$LOG_DIR/clamav.log" /

# Scan plus rapide (cible /etc, /home, /var)
clamscan --infected --recursive --bell --log="$LOG_DIR/clamav.log" /etc /home /var

# Vérification de l'intégrité des fichiers
debsums -s > "$LOG_DIR/debsums.log"

#  Audit de sécurité
lynis audit system --quick > "$LOG_DIR/lynis.log"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Scan de sécurité terminé." >> "$LOG_DIR/monitoring.log"
exit 0
