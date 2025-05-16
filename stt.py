#!/opt/whisper-venv/bin/python

import sys
import os
import glob
import subprocess
import configparser
from faster_whisper import WhisperModel
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

# === CONFIG EINLESEN ===
config = configparser.ConfigParser()
config.read('config.ini')  # config.ini im selben Verzeichnis

# Voicemail Parameter
EXTENSION = config.get('voicemail', 'extension', fallback='82')
VOICEMAIL_DIR_TEMPLATE = config.get('voicemail', 'voicemail_dir', fallback=f"/var/spool/asterisk/voicemail/default/{EXTENSION}/INBOX/")
VOICEMAIL_DIR = VOICEMAIL_DIR_TEMPLATE.replace("{extension}", EXTENSION)
TRANSCRIPT_DIR = config.get('voicemail', 'transcript_dir', fallback="/var/spool/asterisk/voicemail_transcripts/")
LOG_FILE = config.get('voicemail', 'log_file', fallback="/var/log/voicemail_transcription.log")

# E-Mail Parameter
EMAIL_TO = config.get('email', 'email_to', fallback="test@example.com")
EMAIL_FROM = config.get('email', 'email_from', fallback="test@technik.de")
SMTP_SERVER = config.get('email', 'smtp_server', fallback="smtp.your.company")
SMTP_PORT = config.getint('email', 'smtp_port', fallback=465)
SMTP_USER = config.get('email', 'smtp_user', fallback="test@technik.de")
SMTP_PASS = config.get('email', 'smtp_pass', fallback="your-secret-password")

def log_message(message):
    with open(LOG_FILE, "a") as log_file:
        log_file.write(message + "\n")
    print(message)

os.makedirs(TRANSCRIPT_DIR, exist_ok=True)

# Datei auswählen
if len(sys.argv) > 1:
    voicemail_file = sys.argv[1]
else:
    list_of_files = glob.glob(VOICEMAIL_DIR + "msg*.wav")
    if not list_of_files:
        print("Keine Voicemail gefunden.")
        sys.exit(1)
    voicemail_file = max(list_of_files, key=os.path.getctime)

log_message("Neue Audiodatei gefunden: " + voicemail_file)

converted_file = voicemail_file.replace(".wav", "_converted.wav")

cmd = [
    "ffmpeg",
    "-i", voicemail_file,
    "-ar", "16000",
    "-ac", "1",
    "-c:a", "pcm_s16le",
    "-y",
    converted_file
]
subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

transcript_text = ""
model = WhisperModel("small", device="cpu", compute_type="int8")
segments, info = model.transcribe(converted_file, beam_size=5, language="de")

log_message(f"Detected language '{info.language}' with probability {info.language_probability}")

for segment in segments:
    transcript_text += segment.text

transcript_file = os.path.join(TRANSCRIPT_DIR, os.path.basename(voicemail_file) + ".txt")
with open(transcript_file, "w") as f:
    f.write(transcript_text)

email_subject = "Neue Rezeptanfrage (Voicemail & Transkript)"
email_body = f"Neue Voicemail transkribiert:\n\n{transcript_text}\n\n(Achtung: Automatische Transkription, evtl. Fehler überprüfen)\n\nDie originale Voicemail ist als Anhang beigefügt."

msg = MIMEMultipart()
msg["From"] = EMAIL_FROM
msg["To"] = EMAIL_TO
msg["Subject"] = email_subject
msg.attach(MIMEText(email_body, "plain"))

with open(voicemail_file, "rb") as attachment:
    part = MIMEBase("audio", "wav")
    part.set_payload(attachment.read())
    encoders.encode_base64(part)
    part.add_header("Content-Disposition", f'attachment; filename="{os.path.basename(voicemail_file)}"')
    msg.attach(part)

try:
    with smtplib.SMTP_SSL(SMTP_SERVER, SMTP_PORT) as server:
        server.login(SMTP_USER, SMTP_PASS)
        server.sendmail(EMAIL_FROM, EMAIL_TO, msg.as_string())
        print("E-Mail erfolgreich versendet.")
        os.remove(transcript_file)
        # os.remove(converted_file)
except Exception as e:
    print(f"Fehler beim E-Mail-Versand: {e}")
