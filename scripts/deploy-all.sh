#!/usr/bin/env bash
# =============================================================================
# deploy-all.sh — Batch Deployment Script
# Service as Code Lab — Cisco Live 2026
#
# Manages deployment, verification, and teardown of all 30 lab instances.
#
# Prerequisites:
#   - SSH access to all lab hosts (key-based auth recommended)
#   - hosts.txt file with one IP/hostname per line
#   - Lab repo cloned to ~/sac-lab/ on every host
#   - Docker images loaded on every host
#
# Usage:
#   ./scripts/deploy-all.sh deploy        Deploy labs on all hosts
#   ./scripts/deploy-all.sh verify        Verify all lab instances
#   ./scripts/deploy-all.sh destroy       Destroy all lab instances
#   ./scripts/deploy-all.sh status        Quick status check (containers running?)
#   ./scripts/deploy-all.sh setup         Install deps on all hosts
#   ./scripts/deploy-all.sh update-inventory  Update Ansible inventory on all hosts
#
# Options:
#   -f <file>     Hosts file (default: hosts.txt)
#   -u <user>     SSH user (default: ubuntu)
#   -k <keyfile>  SSH key file (default: ~/.ssh/id_rsa)
#   -s <seconds>  Stagger delay between deploys in seconds (default: 120)
#   -p <N>        Max parallel operations (default: 5)
#   -d <dir>      Remote lab directory (default: ~/sac-lab)
#   -h            Show this help
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
HOSTS_FILE="hosts.txt"
SSH_USER="ubuntu"
SSH_KEY="$HOME/.ssh/id_rsa"
STAGGER_DELAY=120
MAX_PARALLEL=5
REMOTE_DIR="~/sac-lab"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

usage() {
    head -28 "$0" | tail -26
    exit 0
}

log_info()  { echo -e "${BLUE}[INFO]${NC}  $(date '+%H:%M:%S')  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $(date '+%H:%M:%S')  $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $(date '+%H:%M:%S')  $*"; }
log_fail()  { echo -e "${RED}[FAIL]${NC}  $(date '+%H:%M:%S')  $*"; }

ssh_cmd() {
    local host="$1"
    shift
    ssh -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 \
        -o BatchMode=yes \
        -i "$SSH_KEY" \
        "${SSH_USER}@${host}" "$@" 2>/dev/null
}

load_hosts() {
    if [[ ! -f "$HOSTS_FILE" ]]; then
        log_fail "Hosts file not found: $HOSTS_FILE"
        echo "Create a file with one host IP/hostname per line."
        exit 1
    fi
    mapfile -t HOSTS < <(grep -v '^\s*#' "$HOSTS_FILE" | grep -v '^\s*$')
    if [[ ${#HOSTS[@]} -eq 0 ]]; then
        log_fail "No hosts found in $HOSTS_FILE"
        exit 1
    fi
    log_info "Loaded ${#HOSTS[@]} hosts from $HOSTS_FILE"
}

# ---------------------------------------------------------------------------
# Commands
# ---------------------------------------------------------------------------

cmd_deploy() {
    log_info "Deploying labs on ${#HOSTS[@]} hosts (stagger: ${STAGGER_DELAY}s)"
    local count=0
    local failed=0

    for host in "${HOSTS[@]}"; do
        count=$((count + 1))
        log_info "[$count/${#HOSTS[@]}] Deploying on $host ..."

        if ssh_cmd "$host" "cd $REMOTE_DIR && sudo containerlab deploy -t topology/sac-lab.yml" &>/dev/null; then
            log_ok "[$count/${#HOSTS[@]}] $host — deploy initiated"
        else
            log_fail "[$count/${#HOSTS[@]}] $host — deploy FAILED"
            failed=$((failed + 1))
        fi

        # Stagger unless this is the last host
        if [[ $count -lt ${#HOSTS[@]} ]]; then
            log_info "Waiting ${STAGGER_DELAY}s before next deploy..."
            sleep "$STAGGER_DELAY"
        fi
    done

    echo ""
    log_info "Deployment complete. Success: $((count - failed))/${count}  Failed: ${failed}"
    if [[ $failed -gt 0 ]]; then
        log_warn "Re-run with 'verify' to check failed hosts after boot."
    fi
    echo ""
    log_info "Wait at least 10 minutes for all nodes to boot, then run:"
    log_info "  $0 verify"
}

cmd_deploy_parallel() {
    log_info "Deploying labs on ${#HOSTS[@]} hosts in parallel (max $MAX_PARALLEL concurrent)"
    local pids=()
    local results_dir
    results_dir=$(mktemp -d)
    local count=0

    for host in "${HOSTS[@]}"; do
        count=$((count + 1))

        (
            if ssh_cmd "$host" "cd $REMOTE_DIR && sudo containerlab deploy -t topology/sac-lab.yml" &>/dev/null; then
                echo "OK" > "$results_dir/$host"
            else
                echo "FAIL" > "$results_dir/$host"
            fi
        ) &
        pids+=($!)

        # Throttle parallel jobs
        if [[ ${#pids[@]} -ge $MAX_PARALLEL ]]; then
            wait "${pids[0]}"
            pids=("${pids[@]:1}")
        fi
    done

    # Wait for remaining
    for pid in "${pids[@]}"; do
        wait "$pid"
    done

    # Report
    local ok=0 fail=0
    for host in "${HOSTS[@]}"; do
        if [[ -f "$results_dir/$host" ]] && [[ "$(cat "$results_dir/$host")" == "OK" ]]; then
            log_ok "$host — deployed"
            ok=$((ok + 1))
        else
            log_fail "$host — deploy FAILED"
            fail=$((fail + 1))
        fi
    done

    rm -rf "$results_dir"
    echo ""
    log_info "Parallel deploy complete. OK: $ok  FAIL: $fail"
}

cmd_verify() {
    log_info "Verifying ${#HOSTS[@]} lab instances..."
    echo ""
    printf "%-20s  %-12s  %-15s  %-15s\n" "HOST" "CONTAINERS" "XRD01 IS-IS" "CSR-PE01 SSH"
    printf "%-20s  %-12s  %-15s  %-15s\n" "----" "----------" "-----------" "------------"

    local total_ok=0
    local total_fail=0

    for host in "${HOSTS[@]}"; do
        local containers="?"
        local isis="?"
        local csr_ssh="?"

        # Check container count
        containers=$(ssh_cmd "$host" "docker ps --filter label=lab=sac-lab -q 2>/dev/null | wc -l" || echo "ERR")
        containers=$(echo "$containers" | tr -d '[:space:]')

        if [[ "$containers" == "7" ]]; then
            containers="${GREEN}7/7${NC}"
        elif [[ "$containers" == "ERR" ]]; then
            containers="${RED}ERR${NC}"
        else
            containers="${YELLOW}${containers}/7${NC}"
        fi

        # Check xrd01 IS-IS
        local isis_count
        isis_count=$(ssh_cmd "$host" "docker exec clab-sac-lab-xrd01 /pkg/bin/xr_cli.sh 'show isis neighbors' 2>/dev/null | grep -c UP" || echo "0")
        isis_count=$(echo "$isis_count" | tr -d '[:space:]')

        if [[ "$isis_count" -ge 1 ]] 2>/dev/null; then
            isis="${GREEN}UP ($isis_count)${NC}"
            total_ok=$((total_ok + 1))
        else
            isis="${RED}DOWN${NC}"
            total_fail=$((total_fail + 1))
        fi

        # Check CSR-PE01 SSH
        local csr_ip
        csr_ip=$(ssh_cmd "$host" "docker inspect clab-sac-lab-csr-pe01 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'" 2>/dev/null || echo "")
        if [[ -n "$csr_ip" ]]; then
            if ssh_cmd "$host" "timeout 5 bash -c 'echo | nc -w3 $csr_ip 22'" &>/dev/null; then
                csr_ssh="${GREEN}OK${NC}"
            else
                csr_ssh="${YELLOW}WAIT${NC}"
            fi
        else
            csr_ssh="${RED}NO IP${NC}"
        fi

        printf "%-20s  %-25b  %-25b  %-25b\n" "$host" "$containers" "$isis" "$csr_ssh"
    done

    echo ""
    log_info "Verification complete. ISIS UP: $total_ok  DOWN: $total_fail"
}

cmd_status() {
    log_info "Quick status check on ${#HOSTS[@]} hosts..."
    echo ""
    printf "%-20s  %-12s  %-10s\n" "HOST" "CONTAINERS" "STATUS"
    printf "%-20s  %-12s  %-10s\n" "----" "----------" "------"

    for host in "${HOSTS[@]}"; do
        local count
        count=$(ssh_cmd "$host" "docker ps --filter label=lab=sac-lab -q 2>/dev/null | wc -l" || echo "ERR")
        count=$(echo "$count" | tr -d '[:space:]')

        if [[ "$count" == "7" ]]; then
            printf "%-20s  %-12s  ${GREEN}%-10s${NC}\n" "$host" "$count/7" "OK"
        elif [[ "$count" == "ERR" ]]; then
            printf "%-20s  %-12s  ${RED}%-10s${NC}\n" "$host" "ERR" "UNREACHABLE"
        elif [[ "$count" == "0" ]]; then
            printf "%-20s  %-12s  ${YELLOW}%-10s${NC}\n" "$host" "0/7" "NOT DEPLOYED"
        else
            printf "%-20s  %-12s  ${YELLOW}%-10s${NC}\n" "$host" "$count/7" "PARTIAL"
        fi
    done
}

cmd_destroy() {
    log_info "Destroying labs on ${#HOSTS[@]} hosts..."
    local count=0
    local failed=0

    for host in "${HOSTS[@]}"; do
        count=$((count + 1))
        log_info "[$count/${#HOSTS[@]}] Destroying on $host ..."

        if ssh_cmd "$host" "cd $REMOTE_DIR && sudo containerlab destroy -t topology/sac-lab.yml --cleanup" &>/dev/null; then
            log_ok "$host — destroyed"
        else
            log_fail "$host — destroy FAILED"
            failed=$((failed + 1))
        fi
    done

    echo ""
    log_info "Destroy complete. Success: $((count - failed))/${count}  Failed: ${failed}"
}

cmd_setup() {
    log_info "Installing dependencies on ${#HOSTS[@]} hosts..."

    for host in "${HOSTS[@]}"; do
        log_info "Setting up $host ..."

        # Kernel tuning for XRd
        ssh_cmd "$host" "sudo sysctl -w fs.inotify.max_user_instances=64000 && \
                         sudo sysctl -w fs.inotify.max_user_watches=64000 && \
                         echo 'fs.inotify.max_user_instances=64000' | sudo tee -a /etc/sysctl.conf && \
                         echo 'fs.inotify.max_user_watches=64000' | sudo tee -a /etc/sysctl.conf" \
            && log_ok "$host — kernel tuned" \
            || log_warn "$host — kernel tuning failed (may already be set)"

        # Python deps
        ssh_cmd "$host" "cd $REMOTE_DIR && pip install -r requirements.txt" \
            && log_ok "$host — pip deps installed" \
            || log_fail "$host — pip install failed"

        # Ansible collections
        ssh_cmd "$host" "cd $REMOTE_DIR && make ansible-install" \
            && log_ok "$host — Ansible collections installed" \
            || log_fail "$host — Ansible collections failed"

        # Terraform init
        ssh_cmd "$host" "cd $REMOTE_DIR && make tf-init" \
            && log_ok "$host — Terraform initialized" \
            || log_fail "$host — Terraform init failed"

        echo ""
    done

    log_info "Setup complete on all hosts."
}

cmd_update_inventory() {
    log_info "Updating Ansible inventory on ${#HOSTS[@]} hosts..."

    for host in "${HOSTS[@]}"; do
        log_info "Updating inventory on $host ..."

        # Get container IPs and update hosts.yml
        local update_script='
import json, subprocess, re

result = subprocess.run(
    ["sudo", "containerlab", "inspect", "-t", "topology/sac-lab.yml", "--format", "json"],
    capture_output=True, text=True
)
data = json.loads(result.stdout)

# Read current inventory
with open("ansible/inventory/hosts.yml", "r") as f:
    content = f.read()

# Update each host IP
for container in data.get("containers", []):
    name = container["name"]
    ip = container.get("ipv4_address", "").split("/")[0]
    if name and ip:
        # Match "ansible_host: <any-ip>" after the hostname line
        # This is a simple regex replacement
        content = re.sub(
            rf"({name}:\s*\n\s*ansible_host:\s*)[\d.]+",
            rf"\g<1>{ip}",
            content
        )

with open("ansible/inventory/hosts.yml", "w") as f:
    f.write(content)

print(f"Updated inventory with container IPs")
'

        ssh_cmd "$host" "cd $REMOTE_DIR && python3 -c '$update_script'" \
            && log_ok "$host — inventory updated" \
            || log_fail "$host — inventory update failed"
    done

    log_info "Inventory update complete."
}

# ---------------------------------------------------------------------------
# Parse options
# ---------------------------------------------------------------------------
while getopts "f:u:k:s:p:d:h" opt; do
    case $opt in
        f) HOSTS_FILE="$OPTARG" ;;
        u) SSH_USER="$OPTARG" ;;
        k) SSH_KEY="$OPTARG" ;;
        s) STAGGER_DELAY="$OPTARG" ;;
        p) MAX_PARALLEL="$OPTARG" ;;
        d) REMOTE_DIR="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

COMMAND="${1:-help}"

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

echo ""
echo "=========================================="
echo " Service as Code Lab — Batch Operations"
echo " Cisco Live 2026"
echo "=========================================="
echo ""

case "$COMMAND" in
    deploy)
        load_hosts
        cmd_deploy
        ;;
    deploy-parallel)
        load_hosts
        cmd_deploy_parallel
        ;;
    verify)
        load_hosts
        cmd_verify
        ;;
    status)
        load_hosts
        cmd_status
        ;;
    destroy)
        load_hosts
        echo -n "This will destroy labs on ALL ${#HOSTS[@]} hosts. Continue? [y/N] "
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            cmd_destroy
        else
            log_info "Aborted."
        fi
        ;;
    setup)
        load_hosts
        cmd_setup
        ;;
    update-inventory)
        load_hosts
        cmd_update_inventory
        ;;
    help)
        usage
        ;;
    *)
        log_fail "Unknown command: $COMMAND"
        echo ""
        echo "Available commands: deploy, deploy-parallel, verify, status, destroy, setup, update-inventory"
        exit 1
        ;;
esac
