#!/bin/bash

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec des privilèges root. Veuillez réessayer avec 'sudo'."
    exit 1
fi

# Variables pour les logs
LOG_FILE="/var/log/security_tools_install.log"

# Fonction pour journaliser
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Début de l'installation des outils de sécurité."

# Mise à jour des dépôts
log_message "Mise à jour des dépôts..."
apt update -y

# Fonction pour installer un outil si nécessaire
install_tool() {
    local TOOL="$1"
    if ! dpkg -l | grep -q "^ii.*$TOOL"; then
        log_message "Installation de $TOOL..."
        apt install -y "$TOOL"
    else
        log_message "$TOOL est déjà installé."
    fi
}

# Liste des outils de sécurité à installer
TOOLS=(
    # Tests d'intrusion et évaluation des vulnérabilités
    "nessus"
    "openvas"

    # Analyse réseau et surveillance
    "wireshark"
    "nmap"
    "tcpdump"
    "iftop"
    "net-tools"
    "rsyslog"

    # Analyse forensique
    "volatility"
    "foremost"

    # Sécurité Web
    "nikto"

    # Stéganographie et cryptographie
    "steghide"

    # Outils antivirus et anti-malware
    "clamav"
    "chkrootkit"
    "rkhunter"

    # Outils divers
    "macchanger"
    "debsums"
    "lynis"
)

# Installation des outils de sécurité
for TOOL in "${TOOLS[@]}"; do
    install_tool "$TOOL"
done

log_message "Installation des outils terminée avec succès."

exit 0
