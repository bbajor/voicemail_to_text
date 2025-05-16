#!/bin/bash

set -e

# === Benutzerdefinierte Variablen ===
EXTENSION="82"   # Hier Nebenstelle anpassen

VENV_DIR="/opt/whisper-venv"
REQUIREMENTS_FILE="requirements.txt"
VOICEMAIL_DIR="/var/spool/asterisk/voicemail/default/${EXTENSION}/INBOX/"
TRANSCRIPT_DIR="/var/spool/asterisk/voicemail_transcripts/"

echo "Starte Installation für Faster-Whisper Speech-to-Text für Nebenstelle $EXTENSION..."

# Prüfe root-Rechte
if [ "$EUID" -ne 0 ]; then
  echo "Bitte als root oder mit sudo ausführen."
  exit 1
fi

# Prüfe Python3
if ! command -v python3 &> /dev/null; then
  echo "Python3 nicht gefunden. Installiere..."
  apt update && apt install -y python3 python3-venv python3-pip
fi

# Prüfe python3-venv
if ! python3 -m venv --help &> /dev/null; then
  echo "Python3 venv Modul nicht gefunden. Installiere python3-venv..."
  apt update && apt install -y python3-venv
fi

# Prüfe ffmpeg
if ! command -v ffmpeg &> /dev/null; then
  echo "ffmpeg nicht gefunden. Installiere ffmpeg..."
  apt update && apt install -y ffmpeg
fi

# Virtuelle Umgebung erstellen, falls nicht vorhanden
if [ ! -d "$VENV_DIR" ]; then
  echo "Erstelle virtuelle Python-Umgebung in $VENV_DIR"
  python3 -m venv "$VENV_DIR"
else
  echo "Virtuelle Umgebung $VENV_DIR existiert bereits."
fi

# requirements.txt anlegen
cat > "$REQUIREMENTS_FILE" << EOF
faster-whisper
ffmpeg-python
email-validator
EOF

# Pakete in der virtuellen Umgebung installieren
echo "Aktiviere virtuelle Umgebung und installiere Abhängigkeiten..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r "$REQUIREMENTS_FILE"
deactivate

# Verzeichnisse anlegen (falls noch nicht vorhanden)
mkdir -p "$TRANSCRIPT_DIR"
mkdir -p "$VOICEMAIL_DIR"

# Besitzer und Gruppe setzen (hier 'asterisk', ggf. anpassen)
chown -R asterisk:asterisk "$TRANSCRIPT_DIR"
chown -R asterisk:asterisk "$VOICEMAIL_DIR"

# Rechte setzen (Besitzer volle Rechte, Gruppe Lesen+Ausführen)
chmod 750 "$TRANSCRIPT_DIR"
chmod 750 "$VOICEMAIL_DIR"

echo "Besitzer und Rechte für Asterisk-Verzeichnisse gesetzt."

echo "Installation abgeschlossen!"
echo "Virtuelle Umgebung ist unter $VENV_DIR."
echo "Bitte das Skript mit folgendem Python-Interpreter ausführen:"
echo "  $VENV_DIR/bin/python"

exit 0
