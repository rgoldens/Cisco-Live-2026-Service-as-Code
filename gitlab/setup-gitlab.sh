#!/usr/bin/env bash
# =============================================================================
# setup-gitlab.sh — Bootstrap GitLab for the Service as Code Lab
# Cisco Live 2026
#
# Run this AFTER 'docker compose up -d' and GitLab is healthy.
# It creates the student user, project, pushes the lab repo, registers the
# runner, and protects the main branch to require Merge Requests.
#
# Usage:
#   cd gitlab/
#   ./setup-gitlab.sh
#
# Options:
#   -u <url>       GitLab URL (default: http://localhost:8080)
#   -p <password>  Root password (default: SaCLab2026!)
#   -d <dir>       Lab repo directory (default: parent of this script's dir)
#   -h             Show help
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
GITLAB_URL="http://localhost:8080"
ROOT_PASSWORD="SaCLab2026!"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"
STUDENT_USER="student"
STUDENT_PASSWORD="CiscoLive2026!"
STUDENT_EMAIL="student@sac-lab.local"
PROJECT_NAME="sac-lab"
RUNNER_TAGS="shell,sac-lab"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_fail()  { echo -e "${RED}[FAIL]${NC}  $*"; }

# ---------------------------------------------------------------------------
# Parse options
# ---------------------------------------------------------------------------
while getopts "u:p:d:h" opt; do
    case $opt in
        u) GITLAB_URL="$OPTARG" ;;
        p) ROOT_PASSWORD="$OPTARG" ;;
        d) LAB_DIR="$OPTARG" ;;
        h)
            head -15 "$0" | tail -13
            exit 0
            ;;
        *) exit 1 ;;
    esac
done

echo ""
echo "=========================================="
echo " GitLab Setup — Service as Code Lab"
echo "=========================================="
echo ""
echo "  GitLab URL:   $GITLAB_URL"
echo "  Lab repo dir: $LAB_DIR"
echo ""

# ---------------------------------------------------------------------------
# Wait for GitLab to be ready
# ---------------------------------------------------------------------------
log_info "Waiting for GitLab to be ready..."
MAX_WAIT=300
WAITED=0
while true; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$GITLAB_URL/-/health" 2>/dev/null || echo "000")
    if [[ "$HTTP_CODE" == "200" ]]; then
        log_ok "GitLab is ready"
        break
    fi
    if [[ $WAITED -ge $MAX_WAIT ]]; then
        log_fail "GitLab not ready after ${MAX_WAIT}s — is 'docker compose up -d' running?"
        exit 1
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo -ne "  Waiting... ${WAITED}s / ${MAX_WAIT}s\r"
done

# ---------------------------------------------------------------------------
# Step 1: Get root personal access token
# ---------------------------------------------------------------------------
log_info "Creating root personal access token..."

# Use the Rails runner to create a PAT non-interactively
ROOT_TOKEN=$(docker exec gitlab gitlab-rails runner "
  user = User.find_by_username('root')
  token = user.personal_access_tokens.create!(
    name: 'setup-script',
    scopes: [:api, :read_user, :read_repository, :write_repository, :sudo],
    expires_at: 1.day.from_now
  )
  puts token.token
" 2>/dev/null)

if [[ -z "$ROOT_TOKEN" ]]; then
    log_fail "Failed to create root PAT"
    exit 1
fi
log_ok "Root token created"

# ---------------------------------------------------------------------------
# Helper: API call
# ---------------------------------------------------------------------------
api() {
    local method="$1"
    local endpoint="$2"
    shift 2
    curl -s --request "$method" \
        --header "PRIVATE-TOKEN: $ROOT_TOKEN" \
        --header "Content-Type: application/json" \
        "$GITLAB_URL/api/v4$endpoint" \
        "$@"
}

# ---------------------------------------------------------------------------
# Step 2: Create student user
# ---------------------------------------------------------------------------
log_info "Creating student user: $STUDENT_USER"

EXISTING_USER=$(api GET "/users?username=$STUDENT_USER" | python3 -c "
import sys, json
users = json.load(sys.stdin)
print(users[0]['id'] if users else '')
" 2>/dev/null)

if [[ -n "$EXISTING_USER" ]]; then
    log_warn "User '$STUDENT_USER' already exists (ID: $EXISTING_USER)"
    STUDENT_ID="$EXISTING_USER"
else
    STUDENT_ID=$(api POST "/users" \
        --data "{
            \"name\": \"Lab Student\",
            \"username\": \"$STUDENT_USER\",
            \"email\": \"$STUDENT_EMAIL\",
            \"password\": \"$STUDENT_PASSWORD\",
            \"skip_confirmation\": true,
            \"can_create_group\": false,
            \"projects_limit\": 0
        }" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

    if [[ -z "$STUDENT_ID" ]]; then
        log_fail "Failed to create student user"
        exit 1
    fi
    log_ok "Student user created (ID: $STUDENT_ID)"
fi

# ---------------------------------------------------------------------------
# Step 3: Create the sac-lab project under root namespace
# ---------------------------------------------------------------------------
log_info "Creating project: $PROJECT_NAME"

EXISTING_PROJECT=$(api GET "/projects?search=$PROJECT_NAME&owned=true" | python3 -c "
import sys, json
projects = json.load(sys.stdin)
for p in projects:
    if p['path'] == '$PROJECT_NAME':
        print(p['id'])
        break
" 2>/dev/null)

if [[ -n "$EXISTING_PROJECT" ]]; then
    log_warn "Project '$PROJECT_NAME' already exists (ID: $EXISTING_PROJECT)"
    PROJECT_ID="$EXISTING_PROJECT"
else
    PROJECT_ID=$(api POST "/projects" \
        --data "{
            \"name\": \"$PROJECT_NAME\",
            \"path\": \"$PROJECT_NAME\",
            \"visibility\": \"private\",
            \"initialize_with_readme\": false,
            \"default_branch\": \"main\"
        }" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)

    if [[ -z "$PROJECT_ID" ]]; then
        log_fail "Failed to create project"
        exit 1
    fi
    log_ok "Project created (ID: $PROJECT_ID)"
fi

# ---------------------------------------------------------------------------
# Step 4: Add student as Developer on the project
# ---------------------------------------------------------------------------
log_info "Adding student to project as Developer..."

api POST "/projects/$PROJECT_ID/members" \
    --data "{\"user_id\": $STUDENT_ID, \"access_level\": 30}" > /dev/null 2>&1

log_ok "Student added to project"

# ---------------------------------------------------------------------------
# Step 5: Push the lab repo into the GitLab project
# ---------------------------------------------------------------------------
log_info "Pushing lab repo to GitLab..."

# Get the internal Git URL (via SSH or HTTP)
GIT_REMOTE="http://root:${ROOT_PASSWORD}@localhost:8080/root/${PROJECT_NAME}.git"

# Create a temporary clone to push (avoids messing with the student's working dir)
TMPDIR=$(mktemp -d)
cd "$TMPDIR"

# Initialize a fresh repo with the lab content
git init -b main
git config user.name "Lab Setup"
git config user.email "setup@sac-lab.local"

# Copy all lab files (excluding .git and gitlab/ docker volumes)
rsync -a --exclude='.git' --exclude='gitlab/' "$LAB_DIR/" .

git add -A
git commit -m "Initial lab setup: Service as Code — Cisco Live 2026" > /dev/null

# Push to GitLab
git remote add origin "$GIT_REMOTE"

if git push -u origin main --force 2>/dev/null; then
    log_ok "Lab repo pushed to GitLab"
else
    log_fail "Failed to push repo — GitLab may still be initializing. Try again in 1-2 minutes."
    cd "$LAB_DIR"
    rm -rf "$TMPDIR"
    exit 1
fi

cd "$LAB_DIR"
rm -rf "$TMPDIR"

# ---------------------------------------------------------------------------
# Step 6: Protect main branch (require Merge Requests)
# ---------------------------------------------------------------------------
log_info "Protecting main branch (require MR to merge)..."

# Delete default branch protection first, then re-create with our settings
api DELETE "/projects/$PROJECT_ID/protected_branches/main" > /dev/null 2>&1

api POST "/projects/$PROJECT_ID/protected_branches" \
    --data "{
        \"name\": \"main\",
        \"push_access_level\": 0,
        \"merge_access_level\": 30,
        \"allow_force_push\": false
    }" > /dev/null 2>&1

log_ok "Main branch protected — pushes blocked, merges require MR"

# ---------------------------------------------------------------------------
# Step 7: Create and register the GitLab Runner
# ---------------------------------------------------------------------------
log_info "Registering GitLab Runner..."

# Create a project runner via the API (GitLab 16.0+)
RUNNER_RESPONSE=$(api POST "/user/runners" \
    --data "{
        \"runner_type\": \"project_type\",
        \"project_id\": $PROJECT_ID,
        \"description\": \"sac-lab-shell-runner\",
        \"tag_list\": [\"shell\", \"sac-lab\"],
        \"run_untagged\": true,
        \"locked\": true
    }")

RUNNER_TOKEN=$(echo "$RUNNER_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

if [[ -z "$RUNNER_TOKEN" ]]; then
    log_warn "API runner creation failed — trying legacy registration token method..."

    # Fallback: get the project's registration token
    REG_TOKEN=$(api GET "/projects/$PROJECT_ID" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('runners_token', ''))
" 2>/dev/null)

    if [[ -n "$REG_TOKEN" ]]; then
        docker exec gitlab-runner gitlab-runner register \
            --non-interactive \
            --url "$GITLAB_URL" \
            --registration-token "$REG_TOKEN" \
            --executor "shell" \
            --description "sac-lab-shell-runner" \
            --tag-list "shell,sac-lab" \
            --run-untagged="true" \
            --locked="true" 2>/dev/null

        log_ok "Runner registered (legacy method)"
    else
        log_fail "Could not register runner — no token available"
        log_warn "You can register manually later with: docker exec gitlab-runner gitlab-runner register"
    fi
else
    # Register using the authentication token
    docker exec gitlab-runner gitlab-runner register \
        --non-interactive \
        --url "$GITLAB_URL" \
        --token "$RUNNER_TOKEN" \
        --executor "shell" \
        --description "sac-lab-shell-runner" 2>/dev/null

    log_ok "Runner registered"
fi

# ---------------------------------------------------------------------------
# Step 8: Configure runner environment
# ---------------------------------------------------------------------------
log_info "Configuring runner environment..."

# The shell runner needs access to make, ansible-playbook, terraform, etc.
# Add the lab directory to the runner's environment
docker exec gitlab-runner bash -c "
cat >> /etc/gitlab-runner/config.toml << 'TOML'

[[runners]]
  environment = [\"SAC_LAB_DIR=/opt/sac-lab\", \"PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin\"]
  builds_dir = \"/tmp/gitlab-builds\"
  cache_dir = \"/tmp/gitlab-cache\"

TOML
" 2>/dev/null || true

# Restart runner to pick up config
docker restart gitlab-runner > /dev/null 2>&1

log_ok "Runner environment configured"

# ---------------------------------------------------------------------------
# Step 9: Create student's personal access token for git CLI
# ---------------------------------------------------------------------------
log_info "Creating student personal access token for git CLI..."

STUDENT_TOKEN=$(docker exec gitlab gitlab-rails runner "
  user = User.find_by_username('$STUDENT_USER')
  token = user.personal_access_tokens.create!(
    name: 'git-cli',
    scopes: [:api, :read_repository, :write_repository],
    expires_at: 7.days.from_now
  )
  puts token.token
" 2>/dev/null)

if [[ -n "$STUDENT_TOKEN" ]]; then
    log_ok "Student token created"
else
    log_warn "Could not create student token — student can use password auth"
    STUDENT_TOKEN="(use password: $STUDENT_PASSWORD)"
fi

# ---------------------------------------------------------------------------
# Step 10: Configure git credential helper on the host
# ---------------------------------------------------------------------------
log_info "Configuring git credentials on host..."

# Store credentials so the student doesn't have to type them repeatedly
git config --global credential.helper store 2>/dev/null || true
echo "http://${STUDENT_USER}:${STUDENT_PASSWORD}@localhost:8080" > ~/.git-credentials 2>/dev/null || true

log_ok "Git credentials configured"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "=========================================="
echo " GitLab Setup Complete"
echo "=========================================="
echo ""
echo "  GitLab Web UI:    $GITLAB_URL"
echo "  Project URL:      $GITLAB_URL/root/$PROJECT_NAME"
echo ""
echo "  Root credentials:"
echo "    Username: root"
echo "    Password: $ROOT_PASSWORD"
echo ""
echo "  Student credentials:"
echo "    Username: $STUDENT_USER"
echo "    Password: $STUDENT_PASSWORD"
echo "    Token:    $STUDENT_TOKEN"
echo ""
echo "  Git clone (student):"
echo "    git clone http://$STUDENT_USER@localhost:8080/root/$PROJECT_NAME.git"
echo ""
echo "  Runner status:"
docker exec gitlab-runner gitlab-runner list 2>&1 | head -5
echo ""
echo "  Main branch is protected — students must use Merge Requests."
echo ""
