#!/bin/bash

# Variables
USER=$(whoami)  # Utilise l'utilisateur actuel
BASE_DIR="/home/$USER/fmdx"
XDRD_DIR="$BASE_DIR/xdrd"
FMDX_WEBSERVER_DIR="$BASE_DIR/fm-dx-webserver"
XDRD_REPO="https://github.com/kkonradpl/xdrd.git"
FMDX_WEBSERVER_REPO="https://github.com/NoobishSVK/fm-dx-webserver.git"
SERVICE_DIR="/etc/systemd/system"

# Définir le mot de passe pour xdrd
PASSWORD="password"  # Modifier avec le mot de passe voulu pour xdrd

# Fonction pour installer un package si non installé
install_if_not_installed() {
    dpkg -l | grep -qw $1 || sudo apt install -y $1
}

# Pré-requis
echo "==> Mise à jour du système et installation des dépendances..."
sudo apt update
install_if_not_installed "git"
install_if_not_installed "libssl-dev"
install_if_not_installed "pkgconf"
install_if_not_installed "ffmpeg"
install_if_not_installed "nodejs"
install_if_not_installed "npm"

# Créer le dossier base (fmdx) si nécessaire
echo "==> Création du répertoire de base $BASE_DIR si nécessaire..."
mkdir -p $BASE_DIR

# Installation de xdrd
echo "==> Installation de xdrd..."
if [ ! -d "$XDRD_DIR" ]; then
    git clone $XDRD_REPO $XDRD_DIR
fi
cd $XDRD_DIR
make
sudo make install

# Ajouter l'utilisateur actuel au groupe dialout pour l'accès aux ports série
echo "==> Ajout de l'utilisateur $USER au groupe dialout..."
sudo adduser $USER dialout

# Création du service systemd pour xdrd avec le mot de passe spécifié
echo "==> Création du service systemd pour xdrd..."
sudo bash -c "cat > $SERVICE_DIR/xdrd.service" <<EOL
[Unit]
Description=xdrd
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/xdrd -p $PASSWORD
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=xdrd

[Install]
WantedBy=multi-user.target
EOL

# Activer et démarrer le service xdrd
sudo chmod 644 $SERVICE_DIR/xdrd.service
sudo systemctl daemon-reload
sudo systemctl start xdrd
sudo systemctl enable xdrd

# Installation du FM-DX Webserver
echo "==> Installation du FM-DX Webserver..."
if [ ! -d "$FMDX_WEBSERVER_DIR" ]; then
    git clone $FMDX_WEBSERVER_REPO $FMDX_WEBSERVER_DIR
fi
cd $FMDX_WEBSERVER_DIR
npm install

# Ajouter l'utilisateur actuel au groupe audio pour l'accès aux périphériques audio
echo "==> Ajout de l'utilisateur $USER au groupe audio..."
sudo adduser $USER audio

# Création du service systemd pour FM-DX Webserver
echo "==> Création du service systemd pour FM-DX Webserver..."
sudo bash -c "cat > $SERVICE_DIR/fm-dx-webserver.service" <<EOL
[Unit]
Description=FM-DX Webserver
After=network-online.target

[Service]
ExecStart=node /home/$USER/fmdx/fm-dx-webserver/index.js
WorkingDirectory=/home/$USER/fmdx/fm-dx-webserver
Restart=always
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=fm-dx-webserver

[Install]
WantedBy=multi-user.target
EOL

# Activer et démarrer le service FM-DX Webserver
sudo chmod 644 $SERVICE_DIR/fm-dx-webserver.service
sudo systemctl daemon-reload
sudo systemctl start fm-dx-webserver
sudo systemctl enable fm-dx-webserver

echo "==> Installation terminée !"
echo "Le mot de passe xdrd actuel est défini sur : $PASSWORD. Vous pouvez le modifier dans le script si nécessaire."
