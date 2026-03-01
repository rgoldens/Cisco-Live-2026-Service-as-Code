#!/usr/bin/env python3
"""
YANG Validator for Service as Code L3VPN Definitions

This script validates YAML service definitions against the SAC L3VPN YANG model.
It ensures required fields are present and conform to the schema constraints.

Usage:
    python3 scripts/validate-yang.py <service_file>

Exit codes:
    0 - Validation passed
    1 - Validation failed (missing or invalid fields)
    2 - File not found or YANG model error
"""

import sys
import yaml
import re
import os
from pathlib import Path

# YANG constraints (derived from sac-l3vpn-service.yang)
# Maps to the existing YAML service definition format in services/l3vpn/vars/*.yml
YANG_CONSTRAINTS = {
    "customer": {
        "required": True,
        "type": "string",
        "pattern": r"^[A-Za-z][A-Za-z0-9_-]*$",
        "description": "Customer name (alphanumeric, underscore, hyphen; starts with letter)"
    },
    "vrf": {
        "required": True,
        "type": "string",
        "pattern": r"^[A-Z0-9_]{1,32}$",
        "description": "VRF name (uppercase alphanumeric, underscore; 1-32 chars)"
    },
    "rd": {
        "required": True,
        "type": "string",
        "pattern": r"^[0-9]+:[0-9]+$",
        "description": "Route Distinguisher (format: ASN:value, e.g., 65000:100)"
    },
    "rt_import": {
        "required": True,
        "type": "string",
        "pattern": r"^[0-9]+:[0-9]+$",
        "description": "Route Target import (format: ASN:value)"
    },
    "rt_export": {
        "required": True,
        "type": "string",
        "pattern": r"^[0-9]+:[0-9]+$",
        "description": "Route Target export (format: ASN:value)"
    },
    "pe_interfaces": {
        "required": True,
        "type": "list",
        "min_elements": 1,
        "description": "PE interface bindings (must have at least 1)"
    }
}

# Maps to existing YAML pe_interfaces array structure
PE_INTERFACE_CONSTRAINTS = {
    "node": {
        "required": True,
        "type": "string",
        "pattern": r"^csr-pe[0-9]{2}$",
        "description": "PE router name (e.g., csr-pe01)"
    },
    "interface": {
        "required": True,
        "type": "string",
        "pattern": r"^(GigabitEthernet|Ethernet)[0-9]+(/[0-9]+)?(\.[0-9]+)?$",
        "description": "Interface name (e.g., GigabitEthernet2, Ethernet0/0/1)"
    },
    "vrf_ip": {
        "required": True,
        "type": "string",
        "pattern": r"^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$",
        "description": "PE IP address with CIDR prefix (e.g., 192.168.100.1/24)"
    },
    "ce_neighbor": {
        "required": True,
        "type": "dict",
        "description": "CE neighbor info (must have 'ip' and 'remote_as')"
    }
}


def validate_pattern(value, pattern):
    """Validate value against regex pattern."""
    return re.match(pattern, str(value)) is not None


def validate_service(service_data, filename):
    """
    Validate a single service definition against YANG constraints.

    Returns tuple: (is_valid: bool, errors: list[str])
    """
    errors = []

    # Check top-level required fields
    for field, constraint in YANG_CONSTRAINTS.items():
        if constraint["required"] and field not in service_data:
            errors.append(f"Missing required field: '{field}'")
            continue

        if field in service_data:
            value = service_data[field]

            # Type validation
            if field != "pe_interfaces":
                if not isinstance(value, str):
                    errors.append(
                        f"Field '{field}' must be string, got {type(value).__name__}: {value}"
                    )
                    continue

                # Pattern validation
                if "pattern" in constraint:
                    if not validate_pattern(value, constraint["pattern"]):
                        errors.append(
                            f"Field '{field}' value '{value}' does not match pattern "
                            f"{constraint['pattern']}. {constraint['description']}"
                        )

            # PE interfaces special validation
            if field == "pe_interfaces":
                if not isinstance(value, list):
                    errors.append(
                        f"Field 'pe_interfaces' must be a list, got {type(value).__name__}"
                    )
                    continue

                if len(value) < constraint["min_elements"]:
                    errors.append(
                        f"Field 'pe_interfaces' must have at least {constraint['min_elements']} element(s), "
                        f"got {len(value)}"
                    )
                    continue

                # Validate each PE interface
                for idx, iface in enumerate(value):
                    if not isinstance(iface, dict):
                        errors.append(
                            f"pe_interfaces[{idx}] must be a dict, got {type(iface).__name__}"
                        )
                        continue

                    for pe_field, pe_constraint in PE_INTERFACE_CONSTRAINTS.items():
                        if pe_constraint["required"] and pe_field not in iface:
                            errors.append(
                                f"Missing required field in pe_interfaces[{idx}]: '{pe_field}'"
                            )
                            continue

                        if pe_field in iface:
                            pe_value = iface[pe_field]

                            # Special validation for ce_neighbor (dict type)
                            if pe_field == "ce_neighbor":
                                if not isinstance(pe_value, dict):
                                    errors.append(
                                        f"pe_interfaces[{idx}].{pe_field} must be a dict, "
                                        f"got {type(pe_value).__name__}"
                                    )
                                    continue

                                # Check required subfields in ce_neighbor
                                if "ip" not in pe_value:
                                    errors.append(
                                        f"pe_interfaces[{idx}].ce_neighbor missing 'ip' field"
                                    )
                                elif not validate_pattern(pe_value["ip"], r"^([0-9]{1,3}\.){3}[0-9]{1,3}$"):
                                    errors.append(
                                        f"pe_interfaces[{idx}].ce_neighbor.ip '{pe_value['ip']}' "
                                        f"is not a valid IP address"
                                    )

                                if "remote_as" not in pe_value:
                                    errors.append(
                                        f"pe_interfaces[{idx}].ce_neighbor missing 'remote_as' field"
                                    )
                                else:
                                    try:
                                        asn = int(pe_value["remote_as"])
                                        if not (1 <= asn <= 4200000000):
                                            errors.append(
                                                f"pe_interfaces[{idx}].ce_neighbor.remote_as {asn} "
                                                f"out of valid range [1, 4200000000]"
                                            )
                                    except (ValueError, TypeError):
                                        errors.append(
                                            f"pe_interfaces[{idx}].ce_neighbor.remote_as must be integer, "
                                            f"got {type(pe_value['remote_as']).__name__}"
                                        )
                            else:
                                # String validation for other PE interface fields
                                if not isinstance(pe_value, str):
                                    errors.append(
                                        f"pe_interfaces[{idx}].{pe_field} must be string, "
                                        f"got {type(pe_value).__name__}: {pe_value}"
                                    )
                                    continue

                                # Pattern validation
                                if "pattern" in pe_constraint:
                                    if not validate_pattern(pe_value, pe_constraint["pattern"]):
                                        errors.append(
                                            f"pe_interfaces[{idx}].{pe_field} value '{pe_value}' "
                                            f"does not match pattern {pe_constraint['pattern']}. "
                                            f"{pe_constraint['description']}"
                                        )

    return len(errors) == 0, errors


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python3 validate-yang.py <service_file>", file=sys.stderr)
        sys.exit(2)

    service_file = sys.argv[1]

    # Check file exists
    if not os.path.exists(service_file):
        print(f"ERROR: Service file not found: {service_file}", file=sys.stderr)
        sys.exit(2)

    # Load YAML
    try:
        with open(service_file, "r") as f:
            service_data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"ERROR: Failed to parse YAML: {e}", file=sys.stderr)
        sys.exit(2)
    except Exception as e:
        print(f"ERROR: Failed to read file: {e}", file=sys.stderr)
        sys.exit(2)

    if not isinstance(service_data, dict):
        print(
            f"ERROR: YAML must contain a dict at root level, got {type(service_data).__name__}",
            file=sys.stderr
        )
        sys.exit(2)

    # Validate against YANG constraints
    is_valid, errors = validate_service(service_data, service_file)

    # Output results
    if is_valid:
        print(f"✓ YANG validation passed: {service_file}")
        sys.exit(0)
    else:
        print(f"✗ YANG validation failed: {service_file}", file=sys.stderr)
        print(f"\nValidation errors:\n", file=sys.stderr)
        for error in errors:
            print(f"  • {error}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
