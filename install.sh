#!/bin/bash

# Variables
USER="fmdx"
TUNER_PORT="/dev/ttyUSB0"
PASSWORD="password"  # Modifier avec le mot de passe voulu pour xdrd

# Mettre à jour le système et installer les outils nécessaires
sudo apt update
sudo apt install -y git libssl-dev pkgconf

# Cloner le dépôt xdrd
mkdir -p ~/build && cd ~/build
git clone https://github.com/kkonradpl/xdrd.git

# Se déplacer dans le répertoire xdrd et compiler
cd xdrd
make

# Installer xdrd
sudo make install

# Ajouter l'utilisateur au groupe dialout pour l'accès aux ports série
sudo adduser $(whoami) dialout

# Appliquer le groupe sans devoir se déconnecter/reconnecter
newgrp dialout

# Créer le fichier de service systemd pour démarrer xdrd au démarrage
sudo bash -c "cat > /etc/systemd/system/xdrd.service" <<EOL
[Unit]
Description=xdrd
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/xdrd -p $PASSWORD -s $TUNER_PORT
User=$USER
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=xdrd

[Install]
WantedBy=multi-user.target
EOL

# Démarrer et activer le service au démarrage
sudo systemctl daemon-reload
sudo systemctl enable xdrd
sudo systemctl start xdrd

# Vérifier le statut du service
sudo systemctl status xdrd
