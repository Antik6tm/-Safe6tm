#!/bin/bash
set -e
set -o pipefail

# Vérification des privilèges root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté avec des privilèges root."
    echo "Relancez-le avec 'sudo'."
    exit 1
fi

# Vérification des commandes nécessaires
command -v systemctl >/dev/null 2>&1 || { echo >&2 "La commande systemctl est requise mais n'est pas installée. Abandon."; exit 1; }
command -v apt >/dev/null 2>&1 || { echo >&2 "La commande apt est requise mais n'est pas installée. Abandon."; exit 1; }

# Journalisation
LOG_FILE="/var/log/system_config.log"
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "### Début du script ###"

# Bloc 1 : Désactivation des services inutiles
log_message "Bloc 1 : Désactivation des services inutiles..."
services_to_disable=(
    "saned.service"
    "postfix.service"
    "bluetooth.service"
    "avahi-daemon.service"
    "wpa_supplicant.service"
    "cups.service"
    "smbd"
    "rygel"
    "nfs-server"
    "rpcbind"
    "NetworkManager-wait-online.service"
    "ModemManager"
)

for service in "${services_to_disable[@]}"; do
    if systemctl list-units --full -all | grep -q "$service"; then
        systemctl stop "$service" && log_message "Service $service arrêté."
        systemctl disable "$service" && log_message "Service $service désactivé."
        systemctl mask "$service" && log_message "Service $service masqué."
    else
        log_message "Service $service non trouvé ou déjà désactivé."
    fi
done

# Bloc 7 : Suppression de l'utilisateur `saned`
log_message "Bloc 7 : Suppression de l'utilisateur saned..."
if id "saned" &>/dev/null; then
    userdel -r saned && log_message "Utilisateur saned supprimé."
else
    log_message "Utilisateur saned non présent."
fi

# Bloc 2 : Vérification des services Apache, MySQL, et PHP
log_message "Bloc 2 : Vérification des services Web (Apache, MySQL, PHP)..."
if dpkg -l | grep -q apache2; then
    log_message "Apache2 est installé."
else
    log_message "Apache2 n'est pas installé."
fi

if dpkg -l | grep -q mysql; then
    log_message "MySQL est installé."
else
    log_message "MySQL n'est pas installé."
fi

if php -v &>/dev/null; then
    php_version=$(php -v | head -n 1)
    log_message "PHP est installé : $php_version"
else
    log_message "PHP n'est pas installé."
fi

# Bloc 2 bis : Désactivation de SSH si inutile
log_message "Bloc 2 bis : Désactivation de SSH..."
if systemctl list-units --full -all | grep -q "ssh.service"; then
    systemctl stop ssh.service && log_message "Service SSH arrêté."
    systemctl disable ssh.service && log_message "Service SSH désactivé."
    apt remove --purge -y openssh-server && log_message "Paquet openssh-server supprimé."
else
    log_message "SSH non installé ou déjà désactivé."
fi

# Bloc 4 : Suppression des paquets inutiles
PACKAGES_TO_REMOVE=(
    "telnet"
    "vsftpd"
    "proftpd"
    "tftpd-hpa"
    "snmp"
)

log_message "Bloc 4 : Suppression des paquets inutiles..."
for package in "${PACKAGES_TO_REMOVE[@]}"; do
    if dpkg -l | grep -q "^ii  $package "; then
        apt remove --purge -y "$package" && log_message "Paquet $package supprimé."
    else
        log_message "Paquet $package non installé."
    fi
done

# Nettoyage des dépendances inutilisées
log_message "Nettoyage des dépendances inutilisées..."
apt autoremove -y && log_message "Dépendances inutilisées supprimées."
apt autoclean -y && log_message "Caches de paquets nettoyés."

# Bloc 5 : Vérification des services actifs
log_message "Bloc 5 : Vérification des services actifs..."
systemctl list-units --type=service --state=running | tee -a "$LOG_FILE"

log_message "### Fin du script ###"
