#!/usr/bin/env bash
# =============================================================================
#  BACKUP TO S3  —  backup_to_s3.sh
#  Run this BEFORE formatting the PC.
#  The user only needs to enter folder paths. Everything else is automatic.
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
#  ★  CONFIGURATION  —  fill these in before distributing the script  ★
# ─────────────────────────────────────────────────────────────────────────────
AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_ID"
AWS_SECRET_ACCESS_KEY="YOUR_SECRET_ACCESS_KEY"
AWS_DEFAULT_REGION="us-east-1"          # e.g. us-east-1 / eu-west-1
S3_BUCKET="your-backup-bucket-name"     # bucket must already exist
S3_PREFIX="pc-backup"                   # folder prefix inside the bucket
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()    { echo -e "${GREEN}[✔]${RESET} $*"; }
warn()   { echo -e "${YELLOW}[!]${RESET} $*"; }
error()  { echo -e "${RED}[✘]${RESET} $*"; }
header() { echo -e "\n${BOLD}${CYAN}$*${RESET}\n"; }

# ── Export AWS credentials so the CLI picks them up without ~/.aws/config ───
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION

# ── 1. Install AWS CLI if missing ─────────────────────────────────────────────
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
    error "Please update AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY in this script."
    exit 1
fi
log "AWS credentials verified."

# ── 3. Collect folders from the user ─────────────────────────────────────────
header "Step 3 / 4 — Enter folders to back up"

echo -e "Enter one folder path per line."
echo -e "Type ${BOLD}done${RESET} and press Enter when finished.\n"

FOLDERS=()
while true; do
    read -rp "  Folder path: " INPUT
    [[ "$INPUT" == "done" ]] && break
    [[ -z "$INPUT" ]] && continue

    # Expand ~ to the real home directory
    EXPANDED="${INPUT/#\~/$HOME}"

    if [[ ! -d "$EXPANDED" ]]; then
        warn "'$EXPANDED' is not a valid directory — skipping."
    else
        FOLDERS+=("$EXPANDED")
        log "Added: $EXPANDED"
    fi
done

if [[ ${#FOLDERS[@]} -eq 0 ]]; then
    error "No valid folders entered. Nothing to back up. Exiting."
    exit 1
fi

# ── 4. Upload each folder to S3 ───────────────────────────────────────────────
header "Step 4 / 4 — Uploading to S3 (bucket: ${S3_BUCKET})"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
FAILED=0

for FOLDER in "${FOLDERS[@]}"; do
    # Build an S3 key that mirrors the absolute path so restore puts it back
    # exactly where it came from.
    #   e.g. /home/alice/Documents  →  s3://bucket/pc-backup/20240101_120000/home/alice/Documents/
    RELATIVE="${FOLDER#/}"   # strip leading /
    S3_TARGET="s3://${S3_BUCKET}/${S3_PREFIX}/${TIMESTAMP}/${RELATIVE}/"

    echo -e "\n  ${BOLD}↑ Uploading:${RESET} $FOLDER"
    echo -e "      ${BOLD}→ To:${RESET}      $S3_TARGET"

    if aws s3 sync "$FOLDER" "$S3_TARGET" \
            --storage-class STANDARD_IA \
            --no-progress \
            2>&1 | sed 's/^/    /'; then
        log "Done: $FOLDER"
    else
        error "Failed to upload: $FOLDER"
        FAILED=$((FAILED + 1))
    fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
header "Backup summary"
echo -e "  Timestamp : ${BOLD}${TIMESTAMP}${RESET}"
echo -e "  S3 bucket : ${BOLD}s3://${S3_BUCKET}/${S3_PREFIX}/${TIMESTAMP}/${RESET}"
echo -e "  Folders   : ${BOLD}${#FOLDERS[@]}${RESET} submitted"
echo -e "  Failures  : ${BOLD}${FAILED}${RESET}"
echo ""

if [[ $FAILED -gt 0 ]]; then
    warn "Some folders failed. Check errors above before formatting."
    exit 1
fi

log "All folders backed up successfully."
echo ""
echo -e "${BOLD}Keep this timestamp for the restore script:${RESET}  ${TIMESTAMP}"
echo -e "(The restore script will also auto-detect the latest backup.)\n"
