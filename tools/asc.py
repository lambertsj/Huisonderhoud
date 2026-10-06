#!/usr/bin/env python3
"""Kleine helper voor de App Store Connect API (JWT met ES256 via openssl, geen extra pakketten).

Leest sleutel-id en issuer uit de omgeving: ASC_KEY_ID, ASC_ISSUER_ID. De .p8 staat in
~/.appstoreconnect/private_keys/. Er wordt niets naar schijf geschreven behalve een tijdelijk bestand.
"""
import base64, json, os, subprocess, tempfile, time, urllib.request, urllib.error

KEY_ID = os.environ["ASC_KEY_ID"]
ISSUER = os.environ["ASC_ISSUER_ID"]
KEY = os.path.expanduser(f"~/.appstoreconnect/private_keys/AuthKey_{KEY_ID}.p8")
BASE = "https://api.appstoreconnect.apple.com"

def b64(b): return base64.urlsafe_b64encode(b).rstrip(b"=").decode()

def token():
    kop = b64(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
    nu = int(time.time())
    inhoud = b64(json.dumps({"iss": ISSUER, "iat": nu, "exp": nu + 900, "aud": "appstoreconnect-v1"}).encode())
    data = f"{kop}.{inhoud}".encode()
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", KEY], input=data, capture_output=True, check=True).stdout
    # DER (SEQUENCE { INTEGER r, INTEGER s }) naar r||s van 32 bytes elk
    assert der[0] == 0x30
    i = 2 if der[1] < 0x80 else 2 + (der[1] & 0x7F)
    def lees(i):
        assert der[i] == 0x02
        n = der[i + 1]; v = der[i + 2:i + 2 + n]
        return int.from_bytes(v, "big"), i + 2 + n
    r, i = lees(i); s, _ = lees(i)
    return f"{kop}.{inhoud}.{b64(r.to_bytes(32, 'big') + s.to_bytes(32, 'big'))}"

_t = None
def aanroep(methode, pad, body=None, ruw=None, kop=None):
    global _t
    _t = _t or token()
    url = pad if pad.startswith("http") else BASE + pad
    data = ruw if ruw is not None else (json.dumps(body).encode() if body is not None else None)
    headers = {"Authorization": f"Bearer {_t}"}
    if body is not None: headers["Content-Type"] = "application/json"
    headers.update(kop or {})
    req = urllib.request.Request(url, data=data, method=methode, headers=headers)
    try:
        with urllib.request.urlopen(req) as r:
            tekst = r.read()
            return json.loads(tekst) if tekst else {}
    except urllib.error.HTTPError as e:
        tekst = e.read().decode()
        raise SystemExit(f"{methode} {pad} -> {e.code}\n{tekst[:1500]}")

def get(pad): return aanroep("GET", pad)
def post(pad, body): return aanroep("POST", pad, body)
def patch(pad, body): return aanroep("PATCH", pad, body)
def delete(pad): return aanroep("DELETE", pad)
