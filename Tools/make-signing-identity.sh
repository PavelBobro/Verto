#!/bin/bash
# Creates a local code signing identity so macOS keeps recognising Verto as the same
# app across rebuilds.
#
# Why this exists: an ad-hoc signature has no identity, so macOS identifies the app by
# a hash of its contents. Change one line of code and every permission you granted —
# screen recording, login item — belongs to what the system now considers a different
# app, and it asks again.
#
# A self-signed certificate gives the app a stable identity instead. It is created and
# trusted only on this machine, has nothing to do with a paid Apple Developer account,
# and does nothing for anyone downloading the app.
#
#   ./Tools/make-signing-identity.sh
#
# You will be asked for your keychain password. Run `make app` afterwards.

set -euo pipefail

NAME="Verto Local Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if security find-identity -v -p codesigning | grep -q "$NAME"; then
    echo "✓ «$NAME» уже существует, ничего делать не нужно"
    exit 0
fi

cat > "$WORK/cert.cnf" <<CNF
[ req ]
distinguished_name = dn
x509_extensions    = ext
prompt             = no
[ dn ]
CN = $NAME
O  = Verto
C  = US
[ ext ]
basicConstraints     = critical,CA:false
keyUsage             = critical,digitalSignature
extendedKeyUsage     = critical,codeSigning
subjectKeyIdentifier = hash
CNF

echo "→ создаю сертификат"
openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$WORK/key.pem" -out "$WORK/cert.pem" \
    -days 3650 -config "$WORK/cert.cnf" 2>/dev/null

# OpenSSL 3 writes PKCS#12 with a SHA-256 MAC and AES-256 encryption, which Apple's
# Security framework cannot read: the import fails with "MAC verification failed
# (wrong password?)" even though the password is right. -legacy writes the older
# format macOS accepts.
if ! openssl pkcs12 -export -legacy -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
        -out "$WORK/verto.p12" -name "$NAME" -passout pass:verto 2>/dev/null; then
    openssl pkcs12 -export -macalg sha1 \
        -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES \
        -inkey "$WORK/key.pem" -in "$WORK/cert.pem" \
        -out "$WORK/verto.p12" -name "$NAME" -passout pass:verto 2>/dev/null
fi

echo "→ кладу в связку ключей (может спросить пароль)"
security import "$WORK/verto.p12" -k "$KEYCHAIN" -P verto \
    -T /usr/bin/codesign -T /usr/bin/security

echo "→ отмечаю как доверенный для подписи кода"
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$WORK/cert.pem"

# Without this, codesign stops to ask for permission on every single build.
security set-key-partition-list -S apple-tool:,apple:,codesign: \
    -s -k "" "$KEYCHAIN" >/dev/null 2>&1 || true

echo
if security find-identity -v -p codesigning | grep -q "$NAME"; then
    echo "✓ готово. Теперь: make app"
else
    echo "✗ удостоверение не появилось — проверьте вывод выше"
    exit 1
fi
