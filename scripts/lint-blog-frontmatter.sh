#!/bin/bash
# Blog Frontmatter Linter
# Checks for deprecated fields and validates frontmatter in blog/ folder
# Run from vault root: ./scripts/lint-blog-frontmatter.sh

BLOG_DIR="blog"
ROBOTS_DIR="blog/robots"
ERRORS=0
WARNINGS=0

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔍 Linting blog frontmatter..."
echo ""

# Deprecated fields that should not exist
declare -a DEPRECATED_FIELDS=(
    "draft:"
    "published:"
    "status:"
    "inprogress:"
    "hidetimestamp:"
    "hidden:"
    "type:"
    "bgcolorclass:"
    "textcolorclass:"
)

# Check for deprecated fields
echo -e "${BLUE}Checking for deprecated fields...${NC}"
for field in "${DEPRECATED_FIELDS[@]}"; do
    while IFS= read -r file; do
        if [ -n "$file" ]; then
            echo -e "${RED}ERROR: Deprecated field '$field' found in: $file${NC}"
            ERRORS=$((ERRORS + 1))
        fi
    done < <(grep -rl "^$field" "$BLOG_DIR" --include="*.md" 2>/dev/null)
done

echo ""

# Check for missing required fields in blog posts
echo -e "${BLUE}Checking required fields (date)...${NC}"
while IFS= read -r file; do
    # Check if file has date: anywhere in frontmatter (first 30 lines should cover it)
    if ! head -30 "$file" | grep -q "^date:"; then
        echo -e "${YELLOW}WARNING: Missing 'date' field: $file${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
done < <(find "$BLOG_DIR" -name "*.md" -type f 2>/dev/null)

echo ""

# Check for valid visibility fields
echo -e "${BLUE}Checking visibility fields...${NC}"
while IFS= read -r file; do
    if [ -n "$file" ]; then
        if grep -q "^unlisted: false" "$file" 2>/dev/null; then
            echo -e "${YELLOW}WARNING: 'unlisted: false' is redundant (remove it): $file${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done < <(grep -rl "^unlisted:" "$BLOG_DIR" --include="*.md" 2>/dev/null)

echo ""

# Check robot notes for required fields
if [ -d "$ROBOTS_DIR" ]; then
    echo -e "${BLUE}Checking robot notes (blog/robots/)...${NC}"
    while IFS= read -r file; do
        # Check for share: true
        if ! head -30 "$file" | grep -q "^share: true"; then
            echo -e "${YELLOW}WARNING: Robot note missing 'share: true': $file${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
        # Check for model field
        if ! head -30 "$file" | grep -q "^model:"; then
            echo -e "${YELLOW}WARNING: Robot note missing 'model' field: $file${NC}"
            WARNINGS=$((WARNINGS + 1))
        fi
    done < <(find "$ROBOTS_DIR" -name "*.md" -type f 2>/dev/null)
    echo ""
fi

# Summary
echo "================================"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All blog frontmatter looks good!${NC}"
else
    [ $ERRORS -gt 0 ] && echo -e "${RED}❌ Errors: $ERRORS${NC}"
    [ $WARNINGS -gt 0 ] && echo -e "${YELLOW}⚠️  Warnings: $WARNINGS${NC}"
fi
echo "================================"

# Exit with error code if there were errors
[ $ERRORS -gt 0 ] && exit 1
exit 0
