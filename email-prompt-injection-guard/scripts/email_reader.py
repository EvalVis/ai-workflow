import os
import base64
import re
from bs4 import BeautifulSoup
from datetime import datetime
from email.utils import parsedate_to_datetime
import json

from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

from llm_guard.input_scanners import PromptInjection
from llm_guard import scan_prompt

# -------------------------
# CONFIG
# -------------------------
SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly"
]

TOKEN_PATH = "token.json"
CREDENTIALS_PATH = "credentials.json"
BLOCKED_SENDERS_FILE = "blocked_senders.json"

prompt_injection_scanner = PromptInjection(threshold=0.7)

# -------------------------
# LOAD BLOCKED SENDERS
# -------------------------
if os.path.exists(BLOCKED_SENDERS_FILE):
    with open(BLOCKED_SENDERS_FILE, "r") as f:
        blocked_senders = set(json.load(f))
else:
    blocked_senders = set()

# -------------------------
# AUTHENTICATE WITH GMAIL
# -------------------------
creds = None
if os.path.exists(TOKEN_PATH):
    creds = Credentials.from_authorized_user_file(TOKEN_PATH, SCOPES)

if not creds or not creds.valid:
    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())
    else:
        flow = InstalledAppFlow.from_client_secrets_file(
            CREDENTIALS_PATH, SCOPES
        )
        creds = flow.run_local_server(port=0)
    with open(TOKEN_PATH, "w") as token_file:
        token_file.write(creds.to_json())

service = build("gmail", "v1", credentials=creds)

# -------------------------
# HELPER FUNCTIONS
# -------------------------
def get_unread_messages(service):
    """Return unread messages from Primary inbox only."""
    query = "is:unread category:primary"
    results = service.users().messages().list(userId="me", q=query).execute()
    return results.get("messages", [])

def get_email_data(service, msg_id):
    msg = service.users().messages().get(userId="me", id=msg_id, format="full").execute()
    headers = msg["payload"]["headers"]

    sender = next((h["value"] for h in headers if h["name"].lower() == "from"), "")
    subject = next((h["value"] for h in headers if h["name"].lower() == "subject"), "")

    # parse email date safely
    date_raw = next((h["value"] for h in headers if h["name"].lower() == "date"), None)
    timestamp = None
    if date_raw:
        try:
            timestamp = parsedate_to_datetime(date_raw)
        except Exception:
            timestamp = None
    if timestamp is None:
        timestamp = datetime.utcnow()  # fallback

    body = extract_body(msg["payload"])
    return {"sender": sender, "subject": subject, "body": body, "timestamp": timestamp}

def extract_body(payload):
    """
    Extract email body.
    - Use text/plain if available
    - If only text/html exists, convert it to text by stripping HTML tags and keeping text between tags
    """
    def html_to_text(html):
        soup = BeautifulSoup(html, "html.parser")
        # Get all text, strip leading/trailing whitespace
        return soup.get_text(separator="\n").strip()

    # If the message has parts
    if "parts" in payload:
        plain_text = None
        html_text = None

        for part in payload["parts"]:
            mime = part.get("mimeType")
            data = part.get("body", {}).get("data")
            if not data:
                continue
            decoded = base64.urlsafe_b64decode(data).decode("utf-8", errors="ignore")

            if mime == "text/plain" and not plain_text:
                plain_text = decoded
            elif mime == "text/html" and not html_text:
                html_text = html_to_text(decoded)

        return plain_text or html_text or ""

    # If no parts, try top-level body
    data = payload.get("body", {}).get("data")
    if data:
        decoded = base64.urlsafe_b64decode(data).decode("utf-8", errors="ignore")
        return html_to_text(decoded)

    return ""

def has_prompt_injection(email_text):
    """Scan text for prompt injections and return sanitized content."""
    sanitized, results, verdict = scan_prompt([prompt_injection_scanner], email_text)
    return verdict["PromptInjection"] > 0, results, sanitized

# -------------------------
# MAIN PROCESS
# -------------------------
def process_emails():
    messages = get_unread_messages(service)
    results = []

    for msg in messages:
        email_data = get_email_data(service, msg["id"])
        sender = email_data["sender"]
        received_time = email_data["timestamp"]

        # Skip senders already blocked, ensure filter exists
        if sender in blocked_senders:
            results.append(
                f"Email received on {received_time} has a prompt injection. "
                "Do not ask AI to get its author name or contents as it puts you at risk."
            )
            continue

        full_text = f"From: {email_data['sender']}\nSubject: {email_data['subject']}\nBody: {email_data['body']}"
        is_injection, details, sanitized_text = has_prompt_injection(full_text)
        if is_injection:
            blocked_senders.add(sender)
            results.append(
                f"Email received on {received_time} has a prompt injection. "
                "Do not ask AI to get its author name or contents as it puts you at risk.\n"
                f"Sanitized content:\n{sanitized_text}"
            )
        else:
            results.append(sanitized_text)

    # Save updated blocked_senders list
    with open(BLOCKED_SENDERS_FILE, "w") as f:
        json.dump(list(blocked_senders), f)

    return results

# -------------------------
# RUN SCRIPT
# -------------------------
if __name__ == "__main__":
    output = process_emails()
    for item in output:
        print("\n--- ITEM START ---")
        print(item)
        print("\n--- ITEM END ---")
