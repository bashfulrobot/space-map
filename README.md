# Confluence Space Sitemap Generator

A powerful shell script that generates comprehensive sitemaps for Confluence spaces using the REST API. Perfect for maintaining navigation pages, documentation indexes, or space overviews.

## Features

- 🔐 **Flexible Authentication**: Support for Personal Access Tokens and username/password
- 📄 **Multiple Output Formats**: Markdown, HTML, JSON, and CSV
- ⚙️ **Highly Configurable**: Environment variables and command-line options
- 🔍 **API Version Detection**: Automatically detects and works with different Confluence versions
- 📊 **Rich Metadata**: Include last modified dates, authors, and version numbers
- 🚀 **Efficient**: Handles large spaces with automatic pagination
- 🛡️ **Error Handling**: Comprehensive validation and error reporting
- 📝 **Direct Page Updates**: Create or update Confluence pages automatically with sitemap content
- 🔄 **Auto-Creation**: Creates new pages if they don't exist (configurable)
- 🎯 **Custom Content**: Add custom headers and footers around sitemap content

## What the Script Retrieves

### ✅ Included in Sitemaps:
- **All published pages** in the specified space
- **Pages at any hierarchy level** (nested pages included)
- **Page metadata**: titles, URLs, last modified dates, authors, version numbers
- **Recently created pages** (as soon as they're published)
- **All page types** (regular content pages)

### ❌ Not Included in Sitemaps:
- **Blog posts** (different content type - use `type=blogpost` parameter if needed)
- **Attachments** (unless `INCLUDE_ATTACHMENTS=true`)
- **Draft/unpublished pages** (only published content is accessible via API)
- **Archived or trashed pages** (only active content)
- **Pages without read permissions** (respects your user permissions)
- **Comments and page history** (only current page content)
- **Personal spaces** (only team/company spaces accessible)
- **Restricted pages** (if you lack permission to view them)

### 🔍 Permission-Based Access:
The script can only retrieve pages you have permission to read. If you don't see certain pages in the sitemap, check your Confluence permissions for those pages.

## Prerequisites

The following tools must be installed on your system:

- `curl` - For making HTTP requests
- `jq` - For JSON processing

### Installing Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install curl jq
```

**macOS:**
```bash
brew install curl jq
```

**CentOS/RHEL:**
```bash
sudo yum install curl jq
```

**NixOS:**
```bash
# Use the provided shell.nix for automatic dependency management
nix-shell

# Or install globally
nix-env -iA nixpkgs.curl nixpkgs.jq
```

## Installation

### Standard Installation

1. Clone or download the script:
```bash
git clone <repository-url>
cd confluence-space-map
```

2. Make the script executable:
```bash
chmod +x confluence-sitemap.sh
```

### NixOS Installation

For NixOS users, use the provided `shell.nix` for automatic dependency management:

1. Clone the repository:
```bash
git clone <repository-url>
cd confluence-space-map
```

2. Enter the Nix shell environment:
```bash
nix-shell
```

The `shell.nix` will automatically:
- Install all required dependencies (`curl`, `jq`)
- Make the script executable
- Display usage instructions
- Set up a clean development environment

**Benefits of using `shell.nix`:**
- Reproducible environment across different systems
- No need to install dependencies globally
- Automatic script permissions setup
- Development tools included (shellcheck, git)

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd confluence-space-map
   ```

2. **Set up configuration:**
   ```bash
   cp .env.example .env
   # Edit .env with your Confluence URL, token, and space key
   ```

3. **Run the script:**
   ```bash
   ./confluence-sitemap.sh
   ```

**Or use the included justfile for common tasks:**
```bash
just init      # Setup from scratch
just generate  # Generate sitemap file
just help      # Show all available commands
```

That's it! The script will generate a sitemap file or update a Confluence page based on your configuration.

## Authentication Setup

### Option 1: Personal Access Token (Recommended)

Personal Access Tokens are more secure and don't require storing passwords.

**For Atlassian Cloud:**
1. Go to https://id.atlassian.com/manage-profile/security/api-tokens
2. Create a new API token
3. Use your email as username and the token as password

**For Confluence Server/Data Center:**
1. Go to your Confluence instance → User Profile → Personal Access Tokens
2. Create a new token
3. Use the token directly (no username required)

### Option 2: Username/Password

Less secure but works for all Confluence versions.

## Configuration

### Method 1: .env File (Recommended)

The easiest way to configure the script is using a `.env` file:

```bash
# Copy the example file
cp .env.example .env

# Edit the file with your settings
nano .env
```

Example `.env` file:
```bash
# Basic configuration
CONFLUENCE_BASE_URL=https://your-domain.atlassian.net/wiki
CONFLUENCE_TOKEN=your-personal-access-token
SPACE_KEY=MYSPACE

# Optional settings
OUTPUT_FORMAT=markdown
OUTPUT_FILE=sitemap.md
SHOW_LAST_MODIFIED=true
SHOW_AUTHOR=true
UPDATE_PAGE=false
```

### Method 2: Environment Variables

Export variables directly in your shell:

```bash
# Required settings
export CONFLUENCE_BASE_URL="https://your-domain.atlassian.net/wiki"
export CONFLUENCE_TOKEN="your-personal-access-token"
export SPACE_KEY="MYSPACE"

# Optional settings
export OUTPUT_FORMAT="markdown"
export OUTPUT_FILE="sitemap.md"
export SHOW_LAST_MODIFIED="true"
export SHOW_AUTHOR="true"
export API_LIMIT="50"
```

### Method 3: Command Line Arguments

All settings can be provided via command line (overrides .env and environment variables):

```bash
./confluence-sitemap.sh -s MYSPACE -u https://confluence.company.com -t your-token
```

**Priority Order:** Command line arguments > Environment variables > .env file > defaults

## Usage

### Basic Usage

**Using .env file (recommended):**
```bash
# First time setup
cp .env.example .env
# Edit .env with your Confluence settings

# Run with .env configuration
./confluence-sitemap.sh
```

**With command line arguments:**
```bash
./confluence-sitemap.sh --space MYSPACE --url https://confluence.company.com --token your-token
```

**NixOS usage:**
```bash
# Enter the Nix shell environment first
nix-shell

# Copy and configure .env file
cp .env.example .env
# Edit .env file with your settings

# Run the script
./confluence-sitemap.sh
```

### Advanced Examples

**Generate HTML sitemap:**
```bash
./confluence-sitemap.sh -s MYSPACE -f html -o space-overview.html
```

**Generate CSV for spreadsheet analysis:**
```bash
./confluence-sitemap.sh -s MYSPACE -f csv -o pages.csv
```

**Minimal markdown output:**
```bash
./confluence-sitemap.sh -s MYSPACE --no-modified --no-author -o simple-sitemap.md
```

**JSON output for programmatic use:**
```bash
./confluence-sitemap.sh -s MYSPACE -f json -o pages.json
```

**Large space with higher API limit:**
```bash
./confluence-sitemap.sh -s MYSPACE --limit 100
```

**Update a Confluence page directly:**
```bash
./confluence-sitemap.sh -s MYSPACE --update-page --page-title "Space Navigation"
```

**Create new page with sitemap:**
```bash
./confluence-sitemap.sh -s MYSPACE --update-page --page-title "Site Map" --parent-id 123456
```

**Update existing page by ID:**
```bash
./confluence-sitemap.sh -s MYSPACE --update-page --page-id 789012
```

**Update page with custom content:**
```bash
./confluence-sitemap.sh -s MYSPACE --update-page --page-title "Navigation" \
  --content-prefix "# Team Navigation

This page is automatically generated from our Confluence space.

" \
  --content-suffix "

---
*Last updated: $(date)*"
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-h, --help` | Show help message | - |
| `-s, --space SPACE_KEY` | Confluence space key (required) | - |
| `-u, --url URL` | Confluence base URL | - |
| `-U, --username USER` | Username for authentication | - |
| `-p, --password PASS` | Password for authentication | - |
| `-t, --token TOKEN` | Personal Access Token | - |
| `-o, --output FILE` | Output file name | `sitemap.md` |
| `-f, --format FORMAT` | Output format | `markdown` |
| `--limit LIMIT` | API results per call | `50` |
| `--no-modified` | Don't show last modified date | - |
| `--no-author` | Don't show author information | - |
| `--show-version` | Show page version numbers | - |
| `--update-page` | Update a Confluence page directly | - |
| `--page-title TITLE` | Page title for updates | `Space Sitemap` |
| `--page-id ID` | ID of existing page to update | - |
| `--parent-id ID` | Parent page ID for new pages | - |
| `--no-create` | Don't create page if it doesn't exist | - |
| `--content-prefix TEXT` | Content before sitemap | - |
| `--content-suffix TEXT` | Content after sitemap | - |

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CONFLUENCE_BASE_URL` | Confluence server URL | - |
| `CONFLUENCE_USERNAME` | Username for authentication | - |
| `CONFLUENCE_PASSWORD` | Password for authentication | - |
| `CONFLUENCE_TOKEN` | Personal Access Token | - |
| `SPACE_KEY` | Space key to process | - |
| `OUTPUT_FORMAT` | Output format (markdown/html/json/csv) | `markdown` |
| `OUTPUT_FILE` | Output file name | `sitemap.md` |
| `API_LIMIT` | Results per API call | `50` |
| `SHOW_LAST_MODIFIED` | Include last modified dates | `true` |
| `SHOW_AUTHOR` | Include author information | `true` |
| `SHOW_VERSION` | Include version numbers | `false` |
| `UPDATE_PAGE` | Update Confluence page directly | `false` |
| `PAGE_TITLE` | Page title for updates | `Space Sitemap` |
| `PAGE_ID` | Existing page ID to update | - |
| `PARENT_PAGE_ID` | Parent page ID for new pages | - |
| `CREATE_IF_NOT_EXISTS` | Create page if it doesn't exist | `true` |
| `PAGE_CONTENT_PREFIX` | Content before sitemap | - |
| `PAGE_CONTENT_SUFFIX` | Content after sitemap | - |

## Output Formats

### Markdown
Creates a clean, readable sitemap with clickable links:
```markdown
# Confluence Space Sitemap: MYSPACE

- [Page Title](https://confluence.com/display/SPACE/Page+Title) _(modified: 2023-12-01)_ _(by: John Doe)_
  - [Child Page](https://confluence.com/display/SPACE/Child+Page)
```

### HTML
Generates a styled web page:
```html
<h1>Confluence Space Sitemap: MYSPACE</h1>
<ul>
  <li><a href="...">Page Title</a> <span class="meta">(modified: 2023-12-01, by: John Doe)</span></li>
</ul>
```

### JSON
Structured data for programmatic processing:
```json
{
  "space": "MYSPACE",
  "generated": "2023-12-01T10:00:00Z",
  "pages": [
    {
      "title": "Page Title",
      "url": "https://confluence.com/display/SPACE/Page+Title",
      "lastModified": "2023-12-01",
      "author": "John Doe",
      "level": 0
    }
  ]
}
```

### CSV
Spreadsheet-compatible format:
```csv
Title,URL,Last Modified,Author,Version,Level
"Page Title","https://confluence.com/...","2023-12-01","John Doe","1","0"
```

## Common Use Cases

### 1. Live Documentation Index (Recommended)
Automatically update a Confluence page with the current space sitemap using .env:

**.env file:**
```bash
CONFLUENCE_BASE_URL=https://company.atlassian.net/wiki
CONFLUENCE_TOKEN=your-token-here
SPACE_KEY=DOCS
UPDATE_PAGE=true
PAGE_TITLE=Documentation Index
SHOW_AUTHOR=false
```

**Run command:**
```bash
./confluence-sitemap.sh
```

### 2. Manual Documentation Index
Generate a markdown sitemap and paste it into a Confluence page:
```bash
./confluence-sitemap.sh -s DOCS --no-author -o docs-index.md
```

### 3. Automated Navigation Page
Create and maintain a navigation page that updates automatically:
```bash
# First time: creates the page
./confluence-sitemap.sh -s MYSPACE --update-page --page-title "Space Navigation" \
  --parent-id 123456 --content-prefix "# Team Space Navigation

Welcome to our team space. Below you'll find all our documentation organized by topic.

"

# Subsequent runs: updates the existing page
./confluence-sitemap.sh -s MYSPACE --update-page --page-title "Space Navigation"
```

### 4. Content Audit
Generate CSV for analysis in spreadsheets:
```bash
./confluence-sitemap.sh -s MYSPACE -f csv --show-version -o audit.csv
```

### 5. Navigation Website
Create an HTML overview page:
```bash
./confluence-sitemap.sh -s MYSPACE -f html -o navigation.html
```

### 6. Automated Reports
JSON output for integration with other tools:
```bash
./confluence-sitemap.sh -s MYSPACE -f json | jq '.pages | length'
```

### 7. Scheduled Updates
Set up automated sitemap updates using cron:
```bash
# Add to crontab to update every hour
0 * * * * /path/to/confluence-sitemap.sh -s MYSPACE --update-page --page-title "Space Map"
```

## Troubleshooting

### Common Issues

**Authentication Errors:**
```
ERROR: Failed to connect to Confluence API. Check your URL and credentials.
```
- Verify your URL format (include `/wiki` for Cloud)
- Check your token/credentials
- Ensure the user has space access

**Missing Dependencies:**
```
ERROR: jq is required but not installed.
```
- Install `jq` and `curl` using your package manager

**Permission Issues:**
```
ERROR: Failed to fetch pages from API
```
- Verify the user has permission to view the space
- Check if the space key exists and is correct

**Large Spaces:**
- Increase the `--limit` parameter for better performance
- The script automatically handles pagination

### Debug Mode

Enable verbose logging by modifying the script:
```bash
# Add this line after the configuration section
set -x  # Enable debug mode
```

### API Version Compatibility

The script works with:
- Confluence Server 6.0+
- Confluence Data Center 6.0+
- Confluence Cloud

Different versions may have slight API variations, but the script handles these automatically.

## Security Best Practices

1. **Use Personal Access Tokens** instead of passwords
2. **Store credentials in environment variables**, not in scripts
3. **Limit token permissions** to only required spaces
4. **Regularly rotate tokens** per your security policy
5. **Don't commit credentials** to version control

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with different Confluence versions
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- Check the troubleshooting section above
- Review Confluence REST API documentation
- Open an issue with detailed error messages and configuration (without credentials)