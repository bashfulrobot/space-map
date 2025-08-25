# Confluence Space Sitemap Generator - Common Commands
# Usage: just <command>

# Default recipe - show available commands
default:
    @echo "Confluence Space Sitemap Generator"
    @echo "Available commands:"
    @just --list

# Setup: Copy example env file and make script executable
setup:
    cp .env.example .env
    chmod +x confluence-sitemap.sh
    @echo "✅ Setup complete! Edit .env with your Confluence settings."

# Generate sitemap file only (no page update)
generate:
    ./confluence-sitemap.sh

# Update the KCX Space Navigation page (Dustin's specific use case)
update-kcx-nav:
    ./confluence-sitemap.sh --update-page --page-title "KCX Space Navigation"

# Generate sitemap and update page (both file and page)
generate-and-update:
    ./confluence-sitemap.sh --update-page --page-title "KCX Space Navigation"

# Generate different output formats
generate-html:
    ./confluence-sitemap.sh -f html -o kcx-sitemap.html

generate-csv:
    ./confluence-sitemap.sh -f csv -o kcx-sitemap.csv

generate-json:
    ./confluence-sitemap.sh -f json -o kcx-sitemap.json

# Generate minimal output (no author/dates)
generate-minimal:
    ./confluence-sitemap.sh --no-author --no-modified

# Test connection to Confluence API
test-connection:
    @echo "Testing connection to Confluence..."
    @if [ -z "$CONFLUENCE_USERNAME" ] || [ -z "$CONFLUENCE_PASSWORD" ]; then \
        echo "❌ CONFLUENCE_USERNAME or CONFLUENCE_PASSWORD not set in .env"; \
        exit 1; \
    fi
    @curl -s -u "$CONFLUENCE_USERNAME:$CONFLUENCE_PASSWORD" \
        "https://konghq.atlassian.net/wiki/rest/api/space/KCX" \
        -H "Accept: application/json" | jq -r '.name // "❌ Connection failed"'

# Show current configuration
show-config:
    @echo "Current Configuration:"
    @echo "====================="
    @echo "Confluence URL: ${CONFLUENCE_BASE_URL:-Not set}"
    @echo "Username: ${CONFLUENCE_USERNAME:-Not set}"
    @echo "Space Key: ${SPACE_KEY:-Not set}"
    @echo "Output Format: ${OUTPUT_FORMAT:-markdown}"
    @echo "Output File: ${OUTPUT_FILE:-sitemap.md}"
    @echo "Update Page: ${UPDATE_PAGE:-false}"
    @echo "Page Title: ${PAGE_TITLE:-Space Sitemap}"

# Content audit - CSV with all metadata
audit:
    ./confluence-sitemap.sh -f csv --show-version -o kcx-content-audit.csv
    @echo "✅ Content audit saved to kcx-content-audit.csv"

# Quick setup for new environments
init:
    @echo "Setting up Confluence Sitemap Generator..."
    cp .env.example .env
    chmod +x confluence-sitemap.sh
    @echo ""
    @echo "✅ Initial setup complete!"
    @echo ""
    @echo "Next steps:"
    @echo "1. Edit .env with your Confluence settings:"
    @echo "   - CONFLUENCE_USERNAME (your email)"
    @echo "   - CONFLUENCE_PASSWORD (your API token)"
    @echo "   - SPACE_KEY (the space to map)"
    @echo ""
    @echo "2. Generate your first sitemap:"
    @echo "   just generate"
    @echo ""
    @echo "3. Or update a Confluence page directly:"
    @echo "   just update-kcx-nav"

# Development helpers
lint:
    shellcheck confluence-sitemap.sh

# Clean generated files
clean:
    rm -f *.md *.html *.json *.csv
    @echo "✅ Cleaned generated files"

# Show script help
help:
    ./confluence-sitemap.sh --help

# Backup current .env file
backup-env:
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    @echo "✅ Environment file backed up"

# Git-crypt management
unlock:
    @echo "🔐 Unlocking repository with git-crypt..."
    git-crypt unlock ~/.ssh/gck
    @echo "✅ Repository unlocked! .env file is now readable."

# Lock repository (encrypt sensitive files)
lock:
    git-crypt lock
    @echo "🔒 Repository locked. .env file is now encrypted."

# Show git-crypt status
crypt-status:
    @echo "🔐 Git-crypt status:"
    git-crypt status

# Setup git-crypt for fresh clone (after git clone)
setup-crypt:
    @echo "🔐 Setting up git-crypt for fresh clone..."
    @if [ ! -f ~/.ssh/gck ]; then \
        echo "❌ Git-crypt key not found at ~/.ssh/gck"; \
        echo "Please ensure your git-crypt key is available at ~/.ssh/gck"; \
        exit 1; \
    fi
    git-crypt unlock ~/.ssh/gck
    @echo "✅ Git-crypt setup complete! Repository is now unlocked."

# First-time setup after cloning
clone-setup:
    @echo "🚀 Setting up cloned repository..."
    chmod +x confluence-sitemap.sh
    just setup-crypt
    @echo "✅ Clone setup complete! Ready to use."