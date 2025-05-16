#!/bin/bash

# Installation für Faster Whisper STT Skript mit FreePBX Asterisk

# Variablen
VENV_DIR="/opt/whisper-venv"
SCRIPT_SRC="voicemail_transcriber.py"  # dein Python-Skript im aktuellen Verzeichnis
SCRIPT_DST="/opt/voicemail_transcriber.py"
STT_WRAPPER_SRC="stt.sh"  # dein Wrapper-Shell-Skript im aktuellen Verzeichnis
STT_WRAPPER_DST="/usr/local/bin/stt.sh"

CONFIG_FILE="config.ini"

# Nebenstelle aus config auslesen (optional, wenn config vorhanden)
if [ -f "$CONFIG_FILE" ]; then
    EXTENSION=$(grep -oP '(?<=^extension = )\d+' "$CONFIG_FILE")
else
    EXTENSION="140"
fi

VOICEMAIL_DIR="/var/spool/asterisk/voicemail/default/${EXTENSION}/INBOX"
TRANSCRIPT_DIR="/var/spool/asterisk/voicemail_transcripts"
LOG_FILE="/var/log/voicemail_transcription.log"

ASTERISK_USER="asterisk"
ASTERISK_GROUP="asterisk"

echo "Starte Installation..."

# 1. Python Virtualenv anlegen
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    echo "Virtuelle Umgebung in $VENV_DIR erstellt."
else
    echo "Virtuelle Umgebung existiert bereits."
fi

# 2. Abhängigkeiten installieren
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install faster-whisper
deactivate

# 3. Skript kopieren
cp "$SCRIPT_SRC" "$SCRIPT_DST"
chmod 750 "$SCRIPT_DST"
chown root:"$ASTERISK_GROUP" "$SCRIPT_DST"

# 4. Wrapper-Skript kopieren und ausführbar machen
cp "$STT_WRAPPER_SRC" "$STT_WRAPPER_DST"
chmod 750 "$STT_WRAPPER_DST"
chown root:"$ASTERISK_GROUP" "$STT_WRAPPER_DST"

# 5. Verzeichnisse und Logdatei anlegen und Rechte setzen

mkdir -p "$VOICEMAIL_DIR" "$TRANSCRIPT_DIR"
touch "$LOG_FILE"

chown -R "$ASTERISK_USER":"$ASTERISK_GROUP" "$VOICEMAIL_DIR"
chown -R "$ASTERISK_USER":"$ASTERISK_GROUP" "$TRANSCRIPT_DIR"
chown "$ASTERISK_USER":"$ASTERISK_GROUP" "$LOG_FILE"

chmod -R 770 "$VOICEMAIL_DIR"
chmod -R 770 "$TRANSCRIPT_DIR"
chmod 660 "$LOG_FILE"

echo "Rechte für Asterisk gesetzt."

echo "Installation abgeschlossen."
echo "Bitte in FreePBX in der Voicemail-Einstellung der Nebenstelle $EXTENSION als Benachrichtigungsbefehl folgenden Befehl angeben:"
echo "$STT_WRAPPER_DST \$1"
echo "Das Skript wird bei neuen Voicemails aufgerufen und transkribiert diese automatisch."

