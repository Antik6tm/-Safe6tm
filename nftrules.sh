#!/bin/bash

# Vérification des privilèges root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root."
    exit 1
fi

# Variables
INTERFACE="eth0"
TEL_IPS="{ 10.1.10.1, 192.0.0.4 }"  # Adresses IPv4 du téléphone
TEL_MAC="9C:73:B1:0E:4B:9F" 
LOG_FILE="/var/log/nftables_block.log"
RULES_BACKUP="/etc/nftables.conf"

# Vérification de la présence de nftables
if ! command -v nft &> /dev/null; then
    echo "nftables n'est pas installé. Veuillez l'installer et réessayer."
    exit 1
fi

# Fonction de journalisation
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "### Début de la configuration de nftables ###"

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

        # Autoriser uniquement OpenVPN TCP (1194 ou 443)
        tcp dport { 1194, 443 } accept

        # Bloquer les paquets invalides
        ct state invalid drop

        # Bloquer les ports non sécurisés (SSH, Telnet, SMB, NetBIOS, mDNS)
        tcp dport { 22, 23, 139, 445 } drop
        udp dport { 137, 138, 5353 } drop

        # Bloquer le téléphone suspect par IP et MAC (IPv4 uniquement)
        ip saddr $TEL_IPS drop
        ether saddr $TEL_MAC drop

        # Protection contre les attaques SYN Flood et limitation des connexions
        tcp flags syn ct state new limit rate 10/second accept
        tcp flags syn ct state new drop

        # Bloquer tout le trafic UDP entrant sauf DNS (nécessaire pour la résolution des noms)
        ip protocol udp drop

        # Bloquer le trafic multicast et broadcast
        ip daddr 224.0.0.0/4 drop

        # Journaliser les paquets bloqués avec une limite pour éviter le flood
        limit rate 5/minute log prefix "nftables input drop: "
        drop
    }

    chain output {
        type filter hook output priority 0; policy accept;

        # Autoriser uniquement les requêtes DNS vers Quad9 et Cloudflare
        ip daddr { 9.9.9.9, 149.112.112.112, 1.1.1.1, 1.0.0.1 } udp dport 53 accept
        ip daddr != { 9.9.9.9, 149.112.112.112, 1.1.1.1, 1.0.0.1 } udp dport 53 drop

        # Bloquer les requêtes UDP vers d'autres ports
        udp dport != 53 drop

        # Bloquer tout trafic TCP sortant sauf vers HTTPS, HTTP et OpenVPN
        tcp dport != { 80, 443, 1194 } drop

        # Bloquer les requêtes ICMP sortantes (pour éviter fingerprinting)
        ip protocol icmp drop
    }
}
EOF

# Sauvegarde des règles
nft list ruleset > "$RULES_BACKUP"

# Activation et redémarrage du service nftables
systemctl enable nftables
systemctl restart nftables

log_message "### Configuration de nftables terminée ###"
