#!/bin/bash
# Test script for LLMBridge-PC system

set -e

echo "=========================================="
echo "LLMBridge-PC Test Suite"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0

test_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAILED++))
}

# Test 1: Check Windows agent binary exists
echo "Test 1: Check Windows agent binary..."
if [ -f "windows-agent/bin/windows-agent.exe" ]; then
    test_pass "Windows agent binary exists"
else
    test_fail "Windows agent binary not found"
fi

# Test 2: Check config file exists
echo "Test 2: Check Windows agent config..."
if [ -f "windows-agent/config.yaml" ]; then
    test_pass "Windows agent config exists"
else
    test_fail "Windows agent config not found"
fi

# Test 3: Check skill directory structure
echo "Test 3: Check skill directory structure..."
if [ -d "$HOME/.claude/skills/pc-control" ]; then
    test_pass "Skill directory exists"
else
    test_fail "Skill directory not found"
fi

# Test 4: Check skill scripts are executable
echo "Test 4: Check skill scripts are executable..."
if [ -x "$HOME/.claude/skills/pc-control/skill.sh" ]; then
    test_pass "Skill script is executable"
else
    test_fail "Skill script is not executable"
fi

# Test 5: Check skill config exists
echo "Test 5: Check skill config..."
if [ -f "$HOME/.claude/skills/pc-control/config/pcs.md" ]; then
    test_pass "Skill config exists"
else
    test_fail "Skill config not found"
fi

# Test 6: Check dependencies
echo "Test 6: Check dependencies..."
DEPS_OK=true
for cmd in nc curl jq; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "  Missing: $cmd"
        DEPS_OK=false
    fi
done

if [ "$DEPS_OK" = true ]; then
    test_pass "All dependencies installed"
else
    test_fail "Some dependencies missing (nc, curl, jq)"
fi

# Test 7: Test skill help command
echo "Test 7: Test skill help command..."
if $HOME/.claude/skills/pc-control/skill.sh help >/dev/null 2>&1; then
    test_pass "Skill help command works"
else
    test_fail "Skill help command failed"
fi

# Test 8: Check Go dependencies
echo "Test 8: Check Go dependencies..."
cd windows-agent
if go list -m all >/dev/null 2>&1; then
    test_pass "Go dependencies OK"
else
    test_fail "Go dependencies check failed"
fi
cd ..

# Test 9: Test Go build
echo "Test 9: Test Go build..."
cd windows-agent
if go build -o /tmp/test-agent main.go 2>/dev/null; then
    test_pass "Go build successful"
    rm -f /tmp/test-agent
else
    test_fail "Go build failed"
fi
cd ..

# Test 10: Check install script exists
echo "Test 10: Check install script..."
if [ -f "windows-agent/install/install.bat" ]; then
    test_pass "Install script exists"
else
    test_fail "Install script not found"
fi

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
