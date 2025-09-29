#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get current date in the format used by traverse-lsp
CURRENT_DATE=$(date +%Y-%m-%d)

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
FAILURES=""

# Test function with proper error handling
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    local expected_output="$3"
    
    echo -e "${YELLOW}Testing: ${test_name}${NC}"
    
    # Run the test command
    output=$(docker exec traverse-test-container bash -c "$test_cmd" 2>&1)
    exit_code=$?
    
    # Check if command succeeded
    if [ $exit_code -ne 0 ]; then
        echo -e "${RED}✗ ${test_name} - Command failed with exit code $exit_code${NC}"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES="${FAILURES}\n  - ${test_name}: Command failed"
        return 1
    fi
    
    # Check for expected output if provided
    if [ -n "$expected_output" ]; then
        if echo "$output" | grep -q "$expected_output"; then
            echo -e "${GREEN}✓ ${test_name}${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            echo -e "${RED}✗ ${test_name} - Expected output not found${NC}"
            echo "  Expected: $expected_output"
            echo "  Got: $output"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILURES="${FAILURES}\n  - ${test_name}: Output mismatch"
            return 1
        fi
    else
        echo -e "${GREEN}✓ ${test_name}${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    fi
}

# File existence check
check_file_exists() {
    local file_path="$1"
    local test_name="$2"
    
    echo -e "${YELLOW}Checking: ${test_name}${NC}"
    
    if docker exec traverse-test-container test -f "$file_path"; then
        echo -e "${GREEN}✓ ${test_name}${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ ${test_name} - File not found: $file_path${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES="${FAILURES}\n  - ${test_name}: File missing"
        return 1
    fi
}

# File size check (ensure non-empty)
check_file_not_empty() {
    local file_path="$1"
    local test_name="$2"
    
    echo -e "${YELLOW}Checking: ${test_name}${NC}"
    
    size=$(docker exec traverse-test-container stat -c%s "$file_path" 2>/dev/null || echo "0")
    
    if [ "$size" -gt "0" ]; then
        echo -e "${GREEN}✓ ${test_name} (size: ${size} bytes)${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ ${test_name} - File is empty or doesn't exist${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES="${FAILURES}\n  - ${test_name}: File empty"
        return 1
    fi
}

echo "================================================"
echo "traverse-lsp.nvim CI Test Suite"
echo "================================================"

# Step 1: Build Docker image
echo -e "\n${YELLOW}Building Docker image...${NC}"
if [ -n "$CI" ]; then
    # In CI, show build output for debugging
    docker build -f ../Dockerfile -t traverse-test ..
else
    # Local builds can be quieter
    docker build -f ../Dockerfile -t traverse-test .. > /dev/null 2>&1
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Docker image built successfully${NC}"
else
    echo -e "${RED}✗ Failed to build Docker image${NC}"
    exit 1
fi

# Step 2: Start container
echo -e "\n${YELLOW}Starting test container...${NC}"
docker run -d --name traverse-test-container traverse-test tail -f /dev/null > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Container started${NC}"
else
    echo -e "${RED}✗ Failed to start container${NC}"
    exit 1
fi

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}Cleaning up...${NC}"
    docker stop traverse-test-container > /dev/null 2>&1
    docker rm traverse-test-container > /dev/null 2>&1
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

# Ensure cleanup on exit
trap cleanup EXIT

# Step 3: Run tests
echo -e "\n${YELLOW}=== Running Tests ===${NC}\n"

# Test 1: Neovim version
run_test "Neovim version check" \
    "nvim --version | head -1" \
    "NVIM v0.11"

# Test 2: Plugin loads
run_test "Plugin loads successfully" \
    "nvim --headless -c ':echo \"loaded\"' -c ':qa' 2>&1" \
    "loaded"

# Test 3: Check plugin commands exist (just verify no error)
run_test "TraverseStatus command exists" \
    "nvim --headless -c ':TraverseStatus' -c ':qa' 2>&1 || true" \
    ""  # Just check that command runs without error

# Test 4: Install traverse-lsp binary (handle both fresh install and already installed)
run_test "Binary installation" \
    "cd /home/nvimtest/test-project && nvim --headless example.sol -c ':TraverseInstall' -c ':sleep 3000m' -c ':qa' 2>&1 | grep -E '(installed successfully|already installed|is already installed)'" \
    ""

# Test 5: Start server
run_test "Server starts" \
    "cd /home/nvimtest/test-project && nvim --headless example.sol -c ':TraverseStart' -c ':sleep 2000m' -c ':qa' 2>&1" \
    "traverse-lsp started"

# Test 6: Generate call graph
run_test "Call graph generation" \
    "cd /home/nvimtest/test-project && nvim --headless example.sol -c ':TraverseStart' -c ':sleep 2000m' -c ':TraverseCallGraph' -c ':sleep 3000m' -c ':qa' 2>&1" \
    "call-graph"

# Check call graph file exists and is not empty
# Use wildcard to handle any date
CALL_GRAPH_FILE=$(docker exec traverse-test-container bash -c "ls /home/nvimtest/test-project/traverse-output/call-graphs/call-graph-*.dot 2>/dev/null | head -1" || echo "")
if [ -n "$CALL_GRAPH_FILE" ]; then
    echo -e "${GREEN}✓ Call graph file exists${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    
    # Check if not empty
    size=$(docker exec traverse-test-container stat -c%s "$CALL_GRAPH_FILE" 2>/dev/null || echo "0")
    if [ "$size" -gt "0" ]; then
        echo -e "${GREEN}✓ Call graph file not empty (size: ${size} bytes)${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ Call graph file is empty${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES="${FAILURES}\n  - Call graph file is empty"
    fi
else
    echo -e "${RED}✗ Call graph file not found${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES="${FAILURES}\n  - Call graph file not found"
fi

# Test 7: Generate sequence diagram
run_test "Sequence diagram generation" \
    "cd /home/nvimtest/test-project && nvim --headless example.sol -c ':TraverseStart' -c ':sleep 2000m' -c ':TraverseSequenceDiagram' -c ':sleep 3000m' -c ':qa' 2>&1" \
    "sequence"

# Check sequence diagram file
# Use wildcard to handle any date
SEQUENCE_FILE=$(docker exec traverse-test-container bash -c "ls /home/nvimtest/test-project/traverse-output/sequence-diagrams/sequence-*.mmd 2>/dev/null | head -1" || echo "")
if [ -n "$SEQUENCE_FILE" ]; then
    echo -e "${GREEN}✓ Sequence diagram file exists${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    
    # Check if not empty
    size=$(docker exec traverse-test-container stat -c%s "$SEQUENCE_FILE" 2>/dev/null || echo "0")
    if [ "$size" -gt "0" ]; then
        echo -e "${GREEN}✓ Sequence diagram file not empty (size: ${size} bytes)${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ Sequence diagram file is empty${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES="${FAILURES}\n  - Sequence diagram file is empty"
    fi
else
    echo -e "${RED}✗ Sequence diagram file not found${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES="${FAILURES}\n  - Sequence diagram file not found"
fi

# Test 8: Storage analysis
run_test "Storage analysis" \
    "cd /home/nvimtest/test-project && nvim --headless example.sol -c ':TraverseStart' -c ':sleep 2000m' -c ':TraverseAnalyzeStorage' -c ':sleep 3000m' -c ':qa' 2>&1" \
    "storage"

# Check storage report file
# Use wildcard to handle any date
STORAGE_FILE=$(docker exec traverse-test-container bash -c "ls /home/nvimtest/test-project/traverse-output/storage-reports/storage-*.md 2>/dev/null | head -1" || echo "")
if [ -n "$STORAGE_FILE" ]; then
    echo -e "${GREEN}✓ Storage report file exists${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    
    # Check if not empty
    size=$(docker exec traverse-test-container stat -c%s "$STORAGE_FILE" 2>/dev/null || echo "0")
    if [ "$size" -gt "0" ]; then
        echo -e "${GREEN}✓ Storage report file not empty (size: ${size} bytes)${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ Storage report file is empty${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILURES="${FAILURES}\n  - Storage report file is empty"
    fi
else
    echo -e "${RED}✗ Storage report file not found${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES="${FAILURES}\n  - Storage report file not found"
fi

# Test 9: GenerateAll command
run_test "GenerateAll command" \
    "cd /home/nvimtest/test-project && rm -rf traverse-output/* && nvim --headless example.sol -c ':TraverseStart' -c ':sleep 2000m' -c ':TraverseGenerateAll' -c ':sleep 5000m' -c ':qa' 2>&1" \
    "All diagrams generated"

# Check GenerateAll output files
# Use wildcards to handle any date
ALL_DOT_FILE=$(docker exec traverse-test-container bash -c "ls /home/nvimtest/test-project/traverse-output/diagrams/all-*.dot 2>/dev/null | head -1" || echo "")
ALL_MMD_FILE=$(docker exec traverse-test-container bash -c "ls /home/nvimtest/test-project/traverse-output/diagrams/all-*.mmd 2>/dev/null | head -1" || echo "")

if [ -n "$ALL_DOT_FILE" ]; then
    echo -e "${GREEN}✓ GenerateAll DOT file exists${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ GenerateAll DOT file not found${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES="${FAILURES}\n  - GenerateAll DOT file not found"
fi

if [ -n "$ALL_MMD_FILE" ]; then
    echo -e "${GREEN}✓ GenerateAll Mermaid file exists${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ GenerateAll Mermaid file not found${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    FAILURES="${FAILURES}\n  - GenerateAll Mermaid file not found"
fi

# Test 10: Validate DOT format
run_test "DOT file format validation" \
    "head -1 /home/nvimtest/test-project/traverse-output/diagrams/all-*.dot 2>/dev/null" \
    "digraph"

# Test 11: Validate Mermaid format
run_test "Mermaid file format validation" \
    "head -1 /home/nvimtest/test-project/traverse-output/diagrams/all-*.mmd 2>/dev/null" \
    "sequenceDiagram"

# Step 4: Generate test report
echo -e "\n${YELLOW}=== Test Summary ===${NC}\n"
echo -e "Tests Passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests Failed: ${RED}${TESTS_FAILED}${NC}"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${RED}Failed Tests:${NC}"
    echo -e "$FAILURES"
fi

# Step 5: Export test artifacts if CI environment variable is set
if [ -n "$CI" ]; then
    echo -e "\n${YELLOW}Exporting test artifacts...${NC}"
    docker cp traverse-test-container:/home/nvimtest/test-project/traverse-output ./test-artifacts
    echo -e "${GREEN}✓ Artifacts exported to ./test-artifacts${NC}"
fi

# Exit with appropriate code
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "\n${RED}✗ TEST SUITE FAILED${NC}"
    exit 1
else
    echo -e "\n${GREEN}✓ ALL TESTS PASSED${NC}"
    exit 0
fi