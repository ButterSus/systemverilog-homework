#!/bin/bash

# Usage: ./list_fork_commits.sh owner repo filepath
# Example: ./list_fork_commits.sh original-owner repo-name path/to/file.sv

# WARN: Put your GITHUB_TOKEN in separate file, DO NOT PUT YOUR PRIVATE TOKEN HERE
OWNER=$1
REPO=$2
FILE=$3

# GitHub API base
API="https://api.github.com"

if [ -z "$OWNER" ] || [ -z "$REPO" ] || [ -z "$FILE" ]; then
  echo "Usage: $0 owner repo filepath"
  exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: Please set GITHUB_TOKEN in the script"
  exit 1
fi

echo "Analyzing file: $FILE"
echo "Original repo: $OWNER/$REPO"
echo ""

# Get commit count for the original repo
echo "Getting original repo commit count..."
original_commits=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "$API/repos/$OWNER/$REPO/commits?path=$FILE&per_page=1" | jq '. | length')

if [ "$original_commits" -eq 0 ]; then
  echo "Warning: File '$FILE' not found in original repo or has no commits"
fi

echo "Original repo has $original_commits commits for this file"
echo ""

# Fetch forks (paginated)
page=1
forks=()
echo "Fetching forks..."

while : ; do
  response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "$API/repos/$OWNER/$REPO/forks?per_page=100&page=$page")
  
  # Check if response is valid JSON and not empty
  fork_names=$(echo "$response" | jq -r 'if type == "array" then .[].full_name else empty end' 2>/dev/null)
  
  if [ -z "$fork_names" ]; then
    break
  fi
  
  while IFS= read -r fork; do
    [ -n "$fork" ] && forks+=("$fork")
  done <<< "$fork_names"
  
  ((page++))
done

total_forks=${#forks[@]}
echo "Found $total_forks forks"
echo ""

# Arrays to track results
repos_with_modifications=()
repos_without_modifications=()

# For each fork, check if it has more commits modifying the file than original
echo "Checking each fork for modifications..."
for fork in "${forks[@]}"; do
  fork_owner=$(echo $fork | cut -d'/' -f1)
  fork_repo=$(echo $fork | cut -d'/' -f2)
  
  echo -n "Checking $fork... "
  
  # Query commits modifying the file in the fork
  commits_response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "$API/repos/$fork_owner/$fork_repo/commits?path=$FILE&per_page=100")
  
  # Check if the response is valid and count commits
  fork_commit_count=$(echo "$commits_response" | jq 'if type == "array" then length else 0 end' 2>/dev/null)
  
  # Handle case where jq fails (invalid JSON)
  if [ -z "$fork_commit_count" ] || [ "$fork_commit_count" = "null" ]; then
    fork_commit_count=0
  fi
  
  if [ "$fork_commit_count" -gt "$original_commits" ]; then
    echo "HAS MODIFICATIONS ($fork_commit_count commits vs $original_commits original)"
    repos_with_modifications+=("$fork")
  else
    echo "no modifications ($fork_commit_count commits)"
    repos_without_modifications+=("$fork")
  fi
done

# Calculate statistics
modified_count=${#repos_with_modifications[@]}
percentage=$(( (modified_count * 100) / total_forks ))

echo ""
echo "========== RESULTS =========="
echo ""
echo "REPOS THAT MODIFIED THE FILE:"
if [ $modified_count -eq 0 ]; then
  echo "  None"
else
  for repo in "${repos_with_modifications[@]}"; do
    echo "  $repo"
  done
fi

echo ""
echo "STATISTICS:"
echo "  Modified repos: $modified_count"
echo "  Total repos: $total_forks"
echo "  Percentage: ${percentage}%"
echo "  Ratio: ${modified_count}:${total_forks}"
echo ""
