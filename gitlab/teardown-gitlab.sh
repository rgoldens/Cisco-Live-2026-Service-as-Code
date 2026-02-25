#!/usr/bin/env bash
# =============================================================================
# teardown-gitlab.sh — Clean up GitLab for post-session
# Service as Code Lab — Cisco Live 2026
#
# Stops and removes GitLab CE and Runner containers, and optionally removes
# all persistent volumes (data, config, logs).
#
# Usage:
#   cd gitlab/
#   ./teardown-gitlab.sh          # Stop containers, keep data
#   ./teardown-gitlab.sh --purge  # Stop containers AND delete all data
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PURGE=false

if [[ "${1:-}" == "--purge" ]]; then
    PURGE=true
fi

echo ""
echo "=========================================="
echo " GitLab Teardown — Service as Code Lab"
echo "=========================================="
echo ""

# ---------------------------------------------------------------------------
# Stop and remove containers
# ---------------------------------------------------------------------------
log_info "Stopping GitLab containers..."

cd "$SCRIPT_DIR"

if docker compose down 2>/dev/null; then
    log_ok "Containers stopped and removed"
else
    log_warn "docker compose down failed — trying manual removal..."
    docker stop gitlab gitlab-runner 2>/dev/null || true
    docker rm gitlab gitlab-runner 2>/dev/null || true
    log_ok "Containers removed manually"
fi

# ---------------------------------------------------------------------------
# Remove volumes (if --purge)
# ---------------------------------------------------------------------------
if [[ "$PURGE" == true ]]; then
    log_info "Purging GitLab data volumes..."

    docker volume rm gitlab_gitlab-config 2>/dev/null || true
    docker volume rm gitlab_gitlab-logs 2>/dev/null || true
    docker volume rm gitlab_gitlab-data 2>/dev/null || true
    docker volume rm gitlab_gitlab-runner-config 2>/dev/null || true

    log_ok "All GitLab volumes removed"
else
    log_info "Data volumes preserved (use --purge to remove)"
fi

# ---------------------------------------------------------------------------
# Clean up host-side git credentials
# ---------------------------------------------------------------------------
log_info "Cleaning up git credentials..."

rm -f ~/.git-credentials 2>/dev/null || true
git config --global --unset credential.helper 2>/dev/null || true

log_ok "Git credentials cleaned"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
if [[ "$PURGE" == true ]]; then
    log_ok "GitLab fully purged — containers and all data removed"
else
    log_ok "GitLab stopped — data preserved in Docker volumes"
    echo "  To fully remove all data:  $0 --purge"
fi
echo ""
