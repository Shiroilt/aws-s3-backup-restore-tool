#!/usr/bin/env bash
# =============================================================================
#  RESTORE FROM S3  —  restore_from_s3.sh
#  Run this AFTER formatting / fresh-installing the PC.
#  The user just runs the script. Nothing else is needed.
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
#  ★  CONFIGURATION  —  must match the values in backup_to_s3.sh  ★
# ─────────────────────────────────────────────────────────────────────────────
AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
AWS_DEFAULT_REGION="us-east-1"
S3_BUCKET="your-backup-bucket-name"
S3_PREFIX="pc-backup"

# Optional: pin a specific backup timestamp (leave empty = use the latest one)
# Example:  RESTORE_TIMESTAMP="20240101_120000"
RESTORE_TIMESTAMP=""
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${GREEN}[✔]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $*"; }
error()  { echo -e "${RED}[✘]${RESET} $*"; }
header() { echo -e "\n${BOLD}${CYAN}$*${RESET}\n"; }

# ── Export AWS credentials ────────────────────────────────────────────────────
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

# ── 1. Install AWS CLI if missing ─────────────────────────────────────────────
header "Step 1 / 4 — Checking AWS CLI"

header "Step 1 / 4 — Checking AWS CLI"

if ! command -v aws >/dev/null 2>&1; then
    warn "AWS CLI not found. Installing..."

    # Install unzip if needed
    sudo apt-get update -qq
    sudo apt-get install -y -qq unzip curl

    # Download AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

    # Extract and install
    unzip -q awscliv2.zip
    sudo ./aws/install

    log "AWS CLI installed successfully."
else
    log "AWS CLI already installed ($(aws --version 2>&1 | head -1))."
fi

# ── 2. Verify AWS connectivity ────────────────────────────────────────────────
header "Step 2 / 4 — Verifying AWS connection"

if ! aws sts get-caller-identity &>/dev/null; then
    error "AWS credentials are invalid or the network is unreachable."
    error "Update AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY in this script."
    exit 1
fi
log "AWS credentials verified."

# ── 3. Resolve which backup timestamp to restore ──────────────────────────────
header "Step 3 / 4 — Finding backup in S3"

if [[ -z "$RESTORE_TIMESTAMP" ]]; then
    warn "No timestamp pinned — finding the latest backup automatically…"

    # List all top-level 'folders' under the prefix and pick the last one
    RESTORE_TIMESTAMP=$(
        aws s3 ls "s3://${S3_BUCKET}/${S3_PREFIX}/" \
            | awk '{print $NF}' \
            | tr -d '/' \
            | grep -E '^[0-9]{8}_[0-9]{6}$' \
            | sort \
            | tail -1
    )

    if [[ -z "$RESTORE_TIMESTAMP" ]]; then
        error "No backups found in s3://${S3_BUCKET}/${S3_PREFIX}/"
        exit 1
    fi
fi

S3_BASE="s3://${S3_BUCKET}/${S3_PREFIX}/${RESTORE_TIMESTAMP}/"
log "Restoring backup: ${RESTORE_TIMESTAMP}"
echo -e "  Source: ${BOLD}${S3_BASE}${RESET}"

# ── 4. Restore every folder back to its original absolute path ────────────────
header "Step 4 / 4 — Downloading and restoring files"

# List all top-level paths stored under this timestamp
# Each entry looks like "home/alice/Documents/" or "etc/hosts" etc.
PATHS=$(
    aws s3 ls "${S3_BASE}" --recursive \
        | awk '{print $NF}' \
        | sed "s|^${S3_PREFIX}/${RESTORE_TIMESTAMP}/||" \
        | awk -F'/' '{print $1"/"$2"/"$3}' \
        | sort -u \
        | head -200   # safety cap; raise if you have many deep paths
)

# Re-derive the original top-level folders that were backed up.
# The S3 key structure is:  <prefix>/<timestamp>/<original_absolute_path_without_leading_slash>/
# Example key: pc-backup/20240101_120000/home/alice/Documents/file.txt
# Original path: /home/alice/Documents

FOLDERS_IN_S3=$(
    aws s3 ls "${S3_BASE}" \
        | awk '{print $NF}' \
        | tr -d '/'
)

if [[ -z "$FOLDERS_IN_S3" ]]; then
    error "Backup appears empty at ${S3_BASE}"
    exit 1
fi

FAILED=0

while IFS= read -r TOP_KEY; do
    [[ -z "$TOP_KEY" ]] && continue

    # The key stored is the path WITHOUT the leading slash.
    # We turn it back into an absolute path.
    # e.g.  home/alice/Documents  →  /home/alice/Documents
    LOCAL_PATH="/${TOP_KEY}"
    S3_SOURCE="${S3_BASE}${TOP_KEY}/"

    echo -e "\n  ${BOLD}↓ Restoring:${RESET} $LOCAL_PATH"
    echo -e "      ${BOLD}← From:${RESET}    $S3_SOURCE"

    # Create parent directory if it doesn't exist
    sudo mkdir -p "$LOCAL_PATH"

    if aws s3 sync "$S3_SOURCE" "$LOCAL_PATH" \
            --no-progress \
            2>&1 | sed 's/^/    /'; then

        # Fix ownership: give files back to the current (non-root) user
        CURRENT_USER="${SUDO_USER:-$USER}"
        sudo chown -R "${CURRENT_USER}:${CURRENT_USER}" "$LOCAL_PATH" 2>/dev/null || true
        log "Restored: $LOCAL_PATH"
    else
        error "Failed to restore: $LOCAL_PATH"
        FAILED=$((FAILED + 1))
    fi

done <<< "$FOLDERS_IN_S3"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
header "Restore summary"
echo -e "  Backup used : ${BOLD}${RESTORE_TIMESTAMP}${RESET}"
echo -e "  S3 source   : ${BOLD}${S3_BASE}${RESET}"
echo -e "  Failures    : ${BOLD}${FAILED}${RESET}"
echo ""

if [[ $FAILED -gt 0 ]]; then
    warn "Some folders could not be restored. Check errors above."
    exit 1
fi

log "All data restored successfully to original paths."
echo ""
