#!/bin/bash

# Vérification des privilèges root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root."
    exit 1
fi

# Variables
INTERFACE="eth0"
TEL_IPS="{ 10.1.10.1, 192.0.0.4 }"  # Adresses IPv4 du téléphone suspect
TEL_MAC="9C:73:B1:0E:4B:9F"
LOG_FILE="/var/log/nftables_block.log"
ALERT_LOG="/var/log/nftables_alerts.log"
RULES_BACKUP="/etc/nftables_backup.conf"
NOTIFY_FILE="$HOME/Desktop/security_alert.txt"

# Vérification de la présence de nftables
if ! command -v nft &> /dev/null; then
    echo "nftables n'est pas installé. Veuillez l'installer et réessayer."
    exit 1
fi

# Fonction de journalisation
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_alert() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$ALERT_LOG"
}

log_message "### Début de la configuration de nftables ###"

# Sauvegarde de la configuration actuelle avant modification
nft list ruleset > "$RULES_BACKUP"

# Réinitialisation des règles existantes
nft flush ruleset

# Configuration de nftables
nft -f - <<EOF
table inet firewall {

    chain input {
        type filter hook input priority 0; policy drop;

        # Autoriser le trafic sur l'interface loopback
        iif "lo" accept

        # Autoriser les connexions établies et associées
        ct state established,related accept

        # Autoriser uniquement OpenVPN (TCP et UDP) sur les ports spécifiés
        tcp dport { 1194, 443, 8443, 7770 } accept
        udp dport { 1194, 443, 8443, 7770 } accept

        # Bloquer les paquets invalides
        ct state invalid log prefix "nftables DROP INVALID: " drop

        # Bloquer les ports non sécurisés (SSH, Telnet, SMB, NetBIOS, mDNS)
        tcp dport { 22, 23, 139, 445 } log prefix "nftables DROP SSH/Telnet/SMB: " drop
        udp dport { 137, 138, 5353 } log prefix "nftables DROP NetBIOS/mDNS: " drop

        # Bloquer le téléphone suspect par IP et MAC (IPv4 uniquement)
        ip saddr $TEL_IPS log prefix "nftables DROP Phone IP: " drop
        ether saddr $TEL_MAC log prefix "nftables DROP Phone MAC: " drop

        # Protection contre les attaques SYN Flood et limitation des connexions
        tcp flags syn ct state new limit rate 10/second accept
        tcp flags syn ct state new log prefix "nftables DROP SYN FLOOD: " drop

        # Bloquer tout le trafic UDP entrant sauf DNS (nécessaire pour la résolution des noms)
        ip protocol udp log prefix "nftables DROP UDP: " drop

        # Bloquer le trafic multicast et broadcast
        ip daddr 224.0.0.0/4 log prefix "nftables DROP MULTICAST: " drop

        # Journaliser et bloquer tout autre paquet entrant
        log prefix "nftables DROP INPUT: " drop
    }

    chain output {
        type filter hook output priority 0; policy drop;

        # Autoriser uniquement les requêtes DNS vers Quad9 et Cloudflare
        ip daddr { 9.9.9.9, 149.112.112.112, 1.1.1.1, 1.0.0.1 } udp dport 53 accept
        ip daddr != { 9.9.9.9, 149.112.112.112, 1.1.1.1, 1.0.0.1 } udp dport 53 log prefix "nftables DROP DNS non autorisé: " drop

        # Autoriser le trafic HTTP et HTTPS
        tcp dport { 80, 443 } accept

        # Autoriser OpenVPN (TCP et UDP)
        tcp dport { 1194, 8443, 7770 } accept
        udp dport { 1194, 8443, 7770 } accept

        # Bloquer tout autre trafic sortant non autorisé
        log prefix "nftables DROP OUTPUT: " counter drop

        # Bloquer les requêtes ICMP sortantes (pour éviter fingerprinting)
        ip protocol icmp log prefix "nftables DROP ICMP: " drop
    }
}
EOF

# Activer et recharger nftables
systemctl enable nftables
systemctl restart nftables

log_message "### Configuration de nftables terminée ###"
