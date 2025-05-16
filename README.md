# Voicemail Transkriptions-Skript mit Faster Whisper

---

## Übersicht

Dieses Python-Skript transkribiert automatisch neue Voicemail-Dateien einer Asterisk/FreePBX-Nebenstelle mittels Faster Whisper (Speech-to-Text). Anschließend wird das Transkript zusammen mit der Original-Voicemail per E-Mail versendet.

---

## Voraussetzungen

- Linux-Server mit Asterisk/FreePBX  
- Python 3 (empfohlen: virtuelles Environment)  
- Faster Whisper (`faster_whisper` Python-Paket)  
- `ffmpeg` installiert und im PATH verfügbar  
- SMTP-Zugang zum Versenden von E-Mails  

---

## Installation & Vorbereitung

1. **Virtuelle Nebenstelle in FreePBX einrichten**

   - Lege in FreePBX eine virtuelle Nebenstelle als Voicemail-Box an, z.B. Nebenstelle `140`.
   - In den Voicemail-Einstellungen dieser Nebenstelle kannst du das Skript als „Voicemail-Benachrichtigungs-Befehl“ oder „Post-Processing-Skript“ hinterlegen.
   - Das Skript wird automatisch bei Eingang einer neuen Voicemail ausgeführt.

2. **Skript & Konfiguration anpassen**

   - Kopiere das Skript auf deinen Server, z.B. `/opt/voicemail_transcriber.py`
   - Lege im gleichen Verzeichnis eine `config.ini` mit folgendem Beispielinhalt an:

     ```ini
     [voicemail]
     extension = 140
     voicemail_dir = /var/spool/asterisk/voicemail/default/{extension}/INBOX/
     transcript_dir = /var/spool/asterisk/voicemail_transcripts/
     log_file = /var/log/voicemail_transcription.log

     [email]
     email_to = deine.email@example.com
     email_from = voicemail@deinedomain.de
     smtp_server = smtp.deinedomain.de
     smtp_port = 465
     smtp_user = smtp-benutzer
     smtp_pass = smtp-passwort
     ```

   - Passe folgende Punkte an:
     - `extension`: Die Nebenstelle, die Voicemail empfängt (z.B. `140` für deine virtuelle Nebenstelle).
     - `voicemail_dir`: Pfad zum Voicemail-Verzeichnis, `{extension}` wird durch die Nebenstelle ersetzt.
     - `transcript_dir`: Speicherort für die erzeugten Transkripte (Verzeichnis muss beschreibbar sein).
     - `log_file`: Pfad für das Logfile.
     - Unter `[email]`: SMTP-Server und Zugangsdaten für den Mailversand.
     - `email_to`: E-Mail-Adresse, an die Transkripte + Voicemail gesendet werden.

3. **Virtuelle Umgebung und Abhängigkeiten**

   - Erstelle und aktiviere ein Python-virtuelles Environment:

     ```bash
     python3 -m venv /opt/whisper-venv
     source /opt/whisper-venv/bin/activate
     ```

   - Installiere Abhängigkeiten:

     ```bash
     pip install faster-whisper
     ```

   - Stelle sicher, dass `ffmpeg` installiert ist:

     ```bash
     ffmpeg -version
     ```

4. **Rechte**

   - Stelle sicher, dass der Benutzer, der das Skript ausführt (z.B. `asterisk`), Lese- und Schreibrechte auf die Verzeichnisse `voicemail_dir`, `transcript_dir` und das `log_file` hat.

---

## Nutzung

- Das Skript wird entweder manuell mit dem Pfad zur Voicemail-Datei als Parameter ausgeführt:

  ```bash
  /opt/whisper-venv/bin/python /opt/voicemail_transcriber.py /var/spool/asterisk/voicemail/default/140/INBOX/msg0000.wav
