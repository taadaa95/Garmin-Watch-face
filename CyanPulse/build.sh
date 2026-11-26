#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
if [[ -z "${CIQ_SDK:-}" ]]; then
  config="$HOME/.Garmin/ConnectIQ/current-sdk.cfg"
  if [[ -f "$config" ]]; then CIQ_SDK="$(tr -d '\r\n' < "$config")"; fi
fi
compiler=monkeyc
if [[ -n "${CIQ_SDK:-}" ]]; then compiler="${CIQ_SDK%/}/bin/monkeyc"; fi
if ! command -v "$compiler" >/dev/null 2>&1; then
  echo 'Monkey C compiler not found. Install the Garmin SDK and set CIQ_SDK to its directory.' >&2
  exit 1
fi
key="${DEVELOPER_KEY:-$HOME/.config/minimal-hr/developer_key.der}"
if [[ ! -f "$key" ]]; then
  mkdir -p -- "$(dirname -- "$key")"
  (umask 077; openssl genrsa -out "$key.pem" 4096; openssl pkcs8 -topk8 -inform PEM -outform DER -in "$key.pem" -out "$key" -nocrypt; rm -f -- "$key.pem")
  echo "Generated private developer key at $key. Retain it for future updates; do not share it."
fi
mkdir -p bin
"$compiler" -f monkey.jungle -d fr265s -o bin/CyanPulse.prg -y "$key" -l 0
echo "Built $(pwd)/bin/CyanPulse.prg"
