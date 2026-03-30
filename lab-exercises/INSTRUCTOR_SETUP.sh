#!/bin/bash
# INSTRUCTOR SETUP SCRIPT
# Run this ONCE before students arrive to verify all infrastructure is ready
# Students should need to do NOTHING except run the playbooks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Lab Infrastructure Pre-Flight Check"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# Test function
test_ssh() {
    local name=$1
    local ip=$2
    local user=$3
    local cmd=$4
    
    echo -n "Testing $name ($user@$ip)... "
    
    if ssh -o ConnectTimeout=5 \
           -o StrictHostKeyChecking=no \
           -o HostKeyAlgorithms=ssh-rsa \
           -o PubkeyAcceptedKeyTypes=ssh-rsa \
           -o KexAlgorithms=diffie-hellman-group14-sha1,diffie-hellman-group-exchange-sha1 \
           "$user@$ip" "$cmd" &>/dev/null; then
        echo -e "${GREEN}✓ OK${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((FAIL_COUNT++))
        return 1
    fi
}

echo "Step 1: Verifying SSH connectivity to all devices"
echo "-------------------------------------------------"

# Test CSR devices
test_ssh "CSR-PE01" "172.20.20.20" "admin" "show version | include Cisco"
test_ssh "CSR-PE02" "172.20.20.21" "admin" "show version | include Cisco"

# Test N9K devices
test_ssh "N9K-CE01" "172.20.20.30" "admin" "show version | grep NX-OS"
test_ssh "N9K-CE02" "172.20.20.31" "admin" "show version | grep NX-OS"

# Test XRd devices
test_ssh "XRd-P01" "172.20.20.10" "clab" "show version | grep IOS"
test_ssh "XRd-P02" "172.20.20.11" "clab" "show version | grep IOS"

echo ""
echo "Step 2: Verifying Ansible configuration"
echo "----------------------------------------"

if [ -f "ansible.cfg" ]; then
    echo -n "ansible.cfg exists... "
    echo -e "${GREEN}✓${NC}"
    ((PASS_COUNT++))
else
    echo -n "ansible.cfg exists... "
    echo -e "${RED}✗${NC}"
    ((FAIL_COUNT++))
fi

if grep -q "KexAlgorithms=diffie-hellman-group14-sha1" ansible.cfg; then
    echo -n "SSH KEX options configured... "
    echo -e "${GREEN}✓${NC}"
    ((PASS_COUNT++))
else
    echo -n "SSH KEX options configured... "
    echo -e "${RED}✗${NC}"
    ((FAIL_COUNT++))
fi

echo ""
echo "Step 3: Testing Ansible connectivity"
echo "------------------------------------"

if ansible all -i inventory/hosts.yml -m ping &>/dev/null; then
    echo -n "Ansible can reach all devices... "
    echo -e "${GREEN}✓${NC}"
    ((PASS_COUNT++))
else
    echo -n "Ansible can reach all devices... "
    echo -e "${RED}✗${NC}"
    ((FAIL_COUNT++))
fi

echo ""
echo "Step 4: Verifying playbook syntax"
echo "---------------------------------"

if ansible-playbook --syntax-check Task1/playbooks/01_task1_vlans.yml &>/dev/null; then
    echo -n "Task 1 playbook syntax... "
    echo -e "${GREEN}✓${NC}"
    ((PASS_COUNT++))
else
    echo -n "Task 1 playbook syntax... "
    echo -e "${RED}✗${NC}"
    ((FAIL_COUNT++))
fi

if ansible-playbook --syntax-check Task2/playbooks/01_deploy_isis_csr.yml &>/dev/null; then
    echo -n "Task 2 CSR playbook syntax... "
    echo -e "${GREEN}✓${NC}"
    ((PASS_COUNT++))
else
    echo -n "Task 2 CSR playbook syntax... "
    echo -e "${RED}✗${NC}"
    ((FAIL_COUNT++))
fi

if ansible-playbook --syntax-check Task2/playbooks/02_deploy_isis_nxos.yml &>/dev/null; then
    echo -n "Task 2 N9K playbook syntax... "
    echo -e "${GREEN}✓${NC}"
    ((PASS_COUNT++))
else
    echo -n "Task 2 N9K playbook syntax... "
    echo -e "${RED}✗${NC}"
    ((FAIL_COUNT++))
fi

echo ""
echo "=========================================="
echo "Pre-Flight Summary"
echo "=========================================="
echo -e "Passed: ${GREEN}$PASS_COUNT${NC}"
echo -e "Failed: ${RED}$FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED${NC}"
    echo ""
    echo "Lab infrastructure is ready for students!"
    echo "Students can now run playbooks without any setup."
    echo ""
    echo "Student instructions:"
    echo "  1. cd /tmp/Cisco-Live-2026-Service-as-Code/lab-exercises"
    echo "  2. ansible-playbook -i inventory/hosts.yml Task1/playbooks/01_task1_vlans.yml"
    echo "  3. ansible-playbook -i inventory/hosts.yml Task2/playbooks/01_deploy_isis_csr.yml"
    echo "  4. ansible-playbook -i inventory/hosts.yml Task2/playbooks/02_deploy_isis_nxos.yml"
    exit 0
else
    echo -e "${RED}✗ SOME CHECKS FAILED${NC}"
    echo ""
    echo "Please fix the issues above before students begin."
    exit 1
fi
