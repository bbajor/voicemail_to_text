#!/bin/bash

set -e
#set -x  # Für Debugging: Einzeilig auskommentieren

echo "Starte Installation..."

# Prüfe, ob Script als root läuft, sonst sudo setzen
if [ "$(id -u)" -ne 0 ]; then
    SUDO='sudo'
else
    SUDO=''
fi

# Prüfe und installiere python3-venv falls nötig
if ! dpkg -s python3-venv >/dev/null 2>&1; then
    echo "python3-venv ist nicht installiert. Installation wird durchgeführt..."
    $SUDO apt update
    $SUDO apt install -y python3-venv
    echo "python3-venv wurde erfolgreich installiert."
fi

# Variablen anpassen:
VENV_DIR="/usr/local/voicemail/whisper-venv"
SCRIPT_SOURCE_DIR="$(pwd)"  # Verzeichnis, aus dem das Skript ausgeführt wird
STT_WRAPPER_SH="stt.sh"
CONFIG_FILE="config.ini"

# Nebenstelle (Voicemail-Ordner)
EXTENSION="140"

# Asterisk-Benutzer (für Rechte)
ASTERISK_USER="asterisk"
ASTERISK_GROUP="asterisk"

# Verzeichnisse der Voicemail (anpassbar)
VOICEMAIL_DIR="/var/spool/asterisk/voicemail/default/${EXTENSION}/INBOX"
TRANSCRIPT_DIR="/var/spool/asterisk/voicemail_transcripts"

echo "Setze Verzeichnisse und Rechte..."

# Erstelle Verzeichnisse, wenn nicht vorhanden
$SUDO mkdir -p "$VOICEMAIL_DIR"
$SUDO mkdir -p "$TRANSCRIPT_DIR"

# Setze Eigentümer auf Asterisk-Benutzer
$SUDO chown -R "$ASTERISK_USER":"$ASTERISK_GROUP" "$VOICEMAIL_DIR" "$TRANSCRIPT_DIR"

# Erstelle virtuelle Umgebung falls nicht vorhanden
if [ ! -d "$VENV_DIR" ]; then
    echo "Erstelle virtuelle Umgebung in $VENV_DIR ..."
    $SUDO python3 -m venv "$VENV_DIR"
    $SUDO chown -R "$ASTERISK_USER":"$ASTERISK_GROUP" "$VENV_DIR"
else
    echo "Virtuelle Umgebung existiert bereits in $VENV_DIR."
fi

# Aktiviere virtuelle Umgebung und installiere Abhängigkeiten
echo "Installiere Python-Abhängigkeiten..."
# Nutze sudo -u asterisk, damit Pakete für den Asterisk-User installiert werden, falls nötig
$SUDO bash -c "source $VENV_DIR/bin/activate && pip install --upgrade pip && pip install -r $SCRIPT_SOURCE_DIR/requirements.txt"

# Kopiere Transkriptionsskript und Wrapper-Skript nach /opt bzw. /usr/local/bin
echo "Kopiere Skripte..."

$SUDO cp "$SCRIPT_SOURCE_DIR/$CONFIG_FILE" /usr/local/bin/
$SUDO cp "$SCRIPT_SOURCE_DIR/$STT_WRAPPER_SH" /usr/local/bin/

# Rechte setzen
$SUDO chown "$ASTERISK_USER":"$ASTERISK_GROUP" /usr/local/bin/"$CONFIG_FILE"
$SUDO chown "$ASTERISK_USER":"$ASTERISK_GROUP" /usr/local/bin/"$STT_WRAPPER_SH"
$SUDO chmod 700 /usr/local/bin/"$CONFIG_FILE""
$SUDO chmod 700 /usr/local/bin/"$STT_WRAPPER_SH"

echo "Rechte für Asterisk gesetzt."

echo "Installation abgeschlossen."

echo ""
echo "Wichtig:"
echo "Bitte in FreePBX in der Voicemail-Einstellung der Nebenstelle 140 als Benachrichtigungsbefehl folgenden Befehl angeben:"
echo "/usr/local/bin/stt.sh \$1"
echo "Das Skript wird bei neuen Voicemails aufgerufen und transkribiert diese automatisch."
echo ""
echo "Falls du die Nebenstelle anpassen möchtest, ändere die Variable EXTENSION im Skript."
