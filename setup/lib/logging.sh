#!/bin/bash

# ==================== LOGGING ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_ok()  { echo "[OK] $1"; }
log_msg() { echo "[MSG] $1"; }
log_err() { echo "[ERR] $1" >&2; }
