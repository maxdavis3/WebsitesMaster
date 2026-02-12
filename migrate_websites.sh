#!/bin/bash

# Script to migrate each website directory to its own GitHub repository
# Usage: ./migrate_websites.sh

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for progress
total=0
success=0
failed=0
skipped=0

# Log file
log_file="migration_log_$(date +%Y%m%d_%H%M%S).txt"

echo "Starting migration process..." | tee -a "$log_file"
echo "Log file: $log_file" | tee -a "$log_file"
echo "" | tee -a "$log_file"

# Get all directories (excluding .git)
for dir in */; do
    # Remove trailing slash
    dir_name="${dir%/}"

    # Skip .git directory
    if [ "$dir_name" == ".git" ]; then
        continue
    fi

    total=$((total + 1))

    echo -e "${YELLOW}[$total] Processing: $dir_name${NC}" | tee -a "$log_file"

    # Check if directory contains files
    if [ -z "$(ls -A "$dir_name")" ]; then
        echo -e "${RED}  ✗ Directory is empty, skipping${NC}" | tee -a "$log_file"
        skipped=$((skipped + 1))
        continue
    fi

    # Create GitHub repository
    echo "  Creating GitHub repository..." | tee -a "$log_file"
    if gh repo create "maxdavis3/$dir_name" --public 2>&1 | grep -v "Unable to add remote" | tee -a "$log_file"; then
        echo -e "${GREEN}  ✓ Repository created${NC}" | tee -a "$log_file"
    else
        echo -e "${YELLOW}  ! Repository might already exist, continuing...${NC}" | tee -a "$log_file"
        # Continue anyway in case repo exists
    fi

    # Navigate into directory
    cd "$dir_name" || {
        echo -e "${RED}  ✗ Cannot access directory${NC}" | tee -a "../$log_file"
        failed=$((failed + 1))
        continue
    }

    # Initialize git if not already initialized
    if [ ! -d ".git" ]; then
        echo "  Initializing git repository..." | tee -a "../$log_file"
        git init >> "../$log_file" 2>&1
    fi

    # Add all files
    echo "  Adding files..." | tee -a "../$log_file"
    git add . >> "../$log_file" 2>&1

    # Create initial commit
    echo "  Creating initial commit..." | tee -a "../$log_file"
    git commit -m "Initial commit: migrated from WebsitesMaster repository

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>" >> "../$log_file" 2>&1

    # Add remote (if not exists)
    if ! git remote get-url origin > /dev/null 2>&1; then
        echo "  Adding remote..." | tee -a "../$log_file"
        git remote add origin "https://github.com/maxdavis3/$dir_name.git" >> "../$log_file" 2>&1
    fi

    # Set default branch to main
    git branch -M main >> "../$log_file" 2>&1

    # Push to GitHub
    echo "  Pushing to GitHub..." | tee -a "../$log_file"
    if git push -u origin main >> "../$log_file" 2>&1; then
        echo -e "${GREEN}  ✓ Successfully migrated $dir_name${NC}" | tee -a "../$log_file"
        success=$((success + 1))
    else
        echo -e "${RED}  ✗ Failed to push $dir_name${NC}" | tee -a "../$log_file"
        failed=$((failed + 1))
    fi

    # Return to parent directory
    cd ..

    echo "" | tee -a "$log_file"
done

# Summary
echo "=====================================" | tee -a "$log_file"
echo "Migration Summary:" | tee -a "$log_file"
echo "=====================================" | tee -a "$log_file"
echo "Total directories: $total" | tee -a "$log_file"
echo -e "${GREEN}Successfully migrated: $success${NC}" | tee -a "$log_file"
echo -e "${RED}Failed: $failed${NC}" | tee -a "$log_file"
echo -e "${YELLOW}Skipped: $skipped${NC}" | tee -a "$log_file"
echo "=====================================" | tee -a "$log_file"
echo "Log saved to: $log_file" | tee -a "$log_file"
