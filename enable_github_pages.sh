#!/bin/bash

# Script to enable GitHub Pages for all successfully migrated repositories
# Usage: ./enable_github_pages.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for progress
total=0
success=0
failed=0
already_enabled=0

# Log file
log_file="github_pages_enable_log_$(date +%Y%m%d_%H%M%S).txt"

echo "Enabling GitHub Pages for all migrated repositories..." | tee -a "$log_file"
echo "Log file: $log_file" | tee -a "$log_file"
echo "" | tee -a "$log_file"

# Check if completed_websites.txt exists
if [ ! -f "completed_websites.txt" ]; then
    echo -e "${RED}Error: completed_websites.txt not found!${NC}" | tee -a "$log_file"
    echo "Please run this script from the WebsitesMaster directory." | tee -a "$log_file"
    exit 1
fi

# Count total websites to process
total_count=$(wc -l < completed_websites.txt)
echo "Found $total_count repositories to enable GitHub Pages" | tee -a "$log_file"
echo "" | tee -a "$log_file"

# Read from completed_websites.txt and enable GitHub Pages for each
while IFS= read -r repo_name; do
    # Skip empty lines
    if [ -z "$repo_name" ]; then
        continue
    fi

    total=$((total + 1))

    echo -e "${YELLOW}[$total/$total_count] Enabling GitHub Pages: $repo_name${NC}" | tee -a "$log_file"

    # Enable GitHub Pages using gh API
    # This will deploy from the main branch, root directory
    response=$(gh api \
        --method POST \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/maxdavis3/$repo_name/pages" \
        -f "source[branch]=main" \
        -f "source[path]=/" \
        2>&1)

    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}  ✓ GitHub Pages enabled successfully${NC}" | tee -a "$log_file"
        echo "$response" >> "$log_file"
        success=$((success + 1))
    else
        # Check if already enabled
        if echo "$response" | grep -q "already exists"; then
            echo -e "${YELLOW}  ! GitHub Pages already enabled${NC}" | tee -a "$log_file"
            already_enabled=$((already_enabled + 1))
        else
            echo -e "${RED}  ✗ Failed to enable GitHub Pages${NC}" | tee -a "$log_file"
            echo "  Error: $response" | tee -a "$log_file"
            failed=$((failed + 1))
        fi
    fi

    echo "" | tee -a "$log_file"

    # Small delay to avoid rate limiting
    sleep 1
done < completed_websites.txt

# Summary
echo "=====================================" | tee -a "$log_file"
echo "GitHub Pages Enablement Summary:" | tee -a "$log_file"
echo "=====================================" | tee -a "$log_file"
echo "Total repositories: $total" | tee -a "$log_file"
echo -e "${GREEN}Successfully enabled: $success${NC}" | tee -a "$log_file"
echo -e "${YELLOW}Already enabled: $already_enabled${NC}" | tee -a "$log_file"
echo -e "${RED}Failed: $failed${NC}" | tee -a "$log_file"
echo "=====================================" | tee -a "$log_file"
echo "Log saved to: $log_file" | tee -a "$log_file"
echo "" | tee -a "$log_file"
echo "Your sites will be available at:" | tee -a "$log_file"
echo "https://maxdavis3.github.io/[repository-name]/" | tee -a "$log_file"
