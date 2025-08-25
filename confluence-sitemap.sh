#!/bin/bash

# Confluence Space Sitemap Generator
# This script generates a sitemap for a specific Confluence space using the REST API

# =============================================================================
# CONFIGURATION VARIABLES
# =============================================================================

# Confluence server settings
CONFLUENCE_BASE_URL="${CONFLUENCE_BASE_URL:-http://localhost:8080/confluence}"
CONFLUENCE_USERNAME="${CONFLUENCE_USERNAME:-}"
CONFLUENCE_PASSWORD="${CONFLUENCE_PASSWORD:-}"
CONFLUENCE_TOKEN="${CONFLUENCE_TOKEN:-}"  # Personal Access Token (preferred over password)

# Space settings
SPACE_KEY="${SPACE_KEY:-}"
OUTPUT_FORMAT="${OUTPUT_FORMAT:-markdown}"  # Options: markdown, html, json, csv
OUTPUT_FILE="${OUTPUT_FILE:-sitemap.md}"

# API settings
API_LIMIT="${API_LIMIT:-50}"  # Number of results per API call
EXPAND_FIELDS="${EXPAND_FIELDS:-space,body.view,version,container,ancestors}"
INCLUDE_ATTACHMENTS="${INCLUDE_ATTACHMENTS:-false}"

# Display settings
SHOW_LAST_MODIFIED="${SHOW_LAST_MODIFIED:-true}"
SHOW_AUTHOR="${SHOW_AUTHOR:-true}"
SHOW_VERSION="${SHOW_VERSION:-false}"
INDENT_CHAR="${INDENT_CHAR:-  }"  # Two spaces for indentation

# Page update settings
UPDATE_PAGE="${UPDATE_PAGE:-false}"  # Whether to update a Confluence page directly
PAGE_TITLE="${PAGE_TITLE:-Space Sitemap}"  # Title for the page to create/update
PAGE_ID="${PAGE_ID:-}"  # ID of existing page to update (optional)
PARENT_PAGE_ID="${PARENT_PAGE_ID:-}"  # Parent page ID for new pages
CREATE_IF_NOT_EXISTS="${CREATE_IF_NOT_EXISTS:-true}"  # Create page if it doesn't exist
PAGE_CONTENT_PREFIX="${PAGE_CONTENT_PREFIX:-}"  # Content to add before sitemap
PAGE_CONTENT_SUFFIX="${PAGE_CONTENT_SUFFIX:-}"  # Content to add after sitemap

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

# Load .env file if it exists
load_env_file() {
    local env_file="${1:-.env}"
    
    if [[ -f "$env_file" ]]; then
        log "Loading environment variables from: $env_file"
        
        # Read .env file line by line
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            
            # Skip lines that don't contain '='
            if [[ ! "$line" =~ = ]]; then
                continue
            fi
            
            # Extract key and value
            local key="${line%%=*}"
            local value="${line#*=}"
            
            # Remove leading/trailing whitespace from key
            key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Remove quotes from value if present
            value=$(echo "$value" | sed 's/^["'\'']*//;s/["'\'']*$//')
            
            # Only set if the environment variable is not already set
            if [[ -z "${!key}" ]]; then
                export "$key"="$value"
            fi
            
        done < "$env_file"
    fi
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Generate a sitemap for a Confluence space using the REST API.
Can output to file or directly update a Confluence page.

OPTIONS:
    -h, --help              Show this help message
    -s, --space SPACE_KEY   Confluence space key (required)
    -u, --url URL          Confluence base URL
    -U, --username USER    Username for authentication
    -p, --password PASS    Password for authentication
    -t, --token TOKEN      Personal Access Token (preferred)
    -o, --output FILE      Output file name
    -f, --format FORMAT    Output format (markdown, html, json, csv)
    --limit LIMIT          API results per call (default: $API_LIMIT)
    --no-modified          Don't show last modified date
    --no-author            Don't show author information
    --show-version         Show page version numbers

PAGE UPDATE OPTIONS:
    --update-page          Update a Confluence page directly with sitemap
    --page-title TITLE     Title for the page to create/update
    --page-id ID           ID of existing page to update
    --parent-id ID         Parent page ID for new pages
    --no-create            Don't create page if it doesn't exist
    --content-prefix TEXT  Content to add before sitemap
    --content-suffix TEXT  Content to add after sitemap

ENVIRONMENT VARIABLES:
    CONFLUENCE_BASE_URL    Confluence server URL
    CONFLUENCE_USERNAME    Username for authentication  
    CONFLUENCE_PASSWORD    Password for authentication
    CONFLUENCE_TOKEN       Personal Access Token
    SPACE_KEY             Space key to generate sitemap for
    OUTPUT_FORMAT         Output format
    OUTPUT_FILE           Output file name
    UPDATE_PAGE           Update Confluence page directly (true/false)
    PAGE_TITLE            Page title for updates
    PAGE_ID               Existing page ID to update
    PARENT_PAGE_ID        Parent page ID for new pages
    CREATE_IF_NOT_EXISTS  Create page if it doesn't exist (true/false)
    PAGE_CONTENT_PREFIX   Content before sitemap
    PAGE_CONTENT_SUFFIX   Content after sitemap

EXAMPLES:
    # Using .env file (recommended)
    cp .env.example .env
    # Edit .env with your settings
    $0

    # Using environment variables
    export CONFLUENCE_BASE_URL="https://company.atlassian.net/wiki"
    export CONFLUENCE_TOKEN="your-token-here"
    export SPACE_KEY="MYSPACE"
    $0

    # Update Confluence page directly
    $0 -s MYSPACE -u https://confluence.company.com -t your-token \\
       --update-page --page-title "Space Navigation"

    # Create new page with sitemap
    $0 -s MYSPACE --update-page --page-title "Site Map" \\
       --parent-id 123456 --content-prefix "# Navigation\\n\\n"

    # Update existing page by ID
    $0 -s MYSPACE --update-page --page-id 789012
EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -s|--space)
                SPACE_KEY="$2"
                shift 2
                ;;
            -u|--url)
                CONFLUENCE_BASE_URL="$2"
                shift 2
                ;;
            -U|--username)
                CONFLUENCE_USERNAME="$2"
                shift 2
                ;;
            -p|--password)
                CONFLUENCE_PASSWORD="$2"
                shift 2
                ;;
            -t|--token)
                CONFLUENCE_TOKEN="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_FILE="$2"
                shift 2
                ;;
            -f|--format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            --limit)
                API_LIMIT="$2"
                shift 2
                ;;
            --no-modified)
                SHOW_LAST_MODIFIED="false"
                shift
                ;;
            --no-author)
                SHOW_AUTHOR="false"
                shift
                ;;
            --show-version)
                SHOW_VERSION="true"
                shift
                ;;
            --update-page)
                UPDATE_PAGE="true"
                shift
                ;;
            --page-title)
                PAGE_TITLE="$2"
                shift 2
                ;;
            --page-id)
                PAGE_ID="$2"
                shift 2
                ;;
            --parent-id)
                PARENT_PAGE_ID="$2"
                shift 2
                ;;
            --no-create)
                CREATE_IF_NOT_EXISTS="false"
                shift
                ;;
            --content-prefix)
                PAGE_CONTENT_PREFIX="$2"
                shift 2
                ;;
            --content-suffix)
                PAGE_CONTENT_SUFFIX="$2"
                shift 2
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
}

# Validate configuration
validate_config() {
    if [[ -z "$SPACE_KEY" ]]; then
        error "Space key is required. Use -s option or set SPACE_KEY environment variable."
    fi

    if [[ -z "$CONFLUENCE_BASE_URL" ]]; then
        error "Confluence base URL is required. Use -u option or set CONFLUENCE_BASE_URL environment variable."
    fi

    if [[ -z "$CONFLUENCE_TOKEN" && (-z "$CONFLUENCE_USERNAME" || -z "$CONFLUENCE_PASSWORD") ]]; then
        error "Authentication is required. Provide either a token (-t) or username/password (-U/-p)."
    fi

    if [[ ! "$OUTPUT_FORMAT" =~ ^(markdown|html|json|csv)$ ]]; then
        error "Invalid output format: $OUTPUT_FORMAT. Must be one of: markdown, html, json, csv"
    fi
}

# Build curl authentication options
get_auth_opts() {
    if [[ -n "$CONFLUENCE_TOKEN" ]]; then
        echo "-H 'Authorization: Bearer $CONFLUENCE_TOKEN'"
    else
        echo "-u '$CONFLUENCE_USERNAME:$CONFLUENCE_PASSWORD'"
    fi
}

# Make API request
api_request() {
    local endpoint="$1"
    local auth_opts
    auth_opts=$(get_auth_opts)
    
    eval curl -s -f \
        -H "'Accept: application/json'" \
        -H "'Content-Type: application/json'" \
        "$auth_opts" \
        "'${CONFLUENCE_BASE_URL}${endpoint}'"
}

# Make API request with POST/PUT data
api_request_with_data() {
    local method="$1"
    local endpoint="$2"
    local data="$3"
    local auth_opts
    auth_opts=$(get_auth_opts)
    
    eval curl -s -f \
        -X "'$method'" \
        -H "'Accept: application/json'" \
        -H "'Content-Type: application/json'" \
        "$auth_opts" \
        -d "'$data'" \
        "'${CONFLUENCE_BASE_URL}${endpoint}'"
}

# Convert markdown content to Confluence storage format
convert_to_confluence_storage() {
    local markdown_content="$1"
    
    # Basic markdown to Confluence storage format conversion
    # This handles the most common markdown elements used in sitemaps
    local storage_content="$markdown_content"
    
    # Convert markdown headers to Confluence headers
    storage_content=$(echo "$storage_content" | sed 's/^# \(.*\)/<h1>\1<\/h1>/g')
    storage_content=$(echo "$storage_content" | sed 's/^## \(.*\)/<h2>\1<\/h2>/g')
    storage_content=$(echo "$storage_content" | sed 's/^### \(.*\)/<h3>\1<\/h3>/g')
    
    # Convert markdown links to Confluence links
    storage_content=$(echo "$storage_content" | sed 's/\[\([^]]*\)\](\([^)]*\))/<a href="\2">\1<\/a>/g')
    
    # Convert markdown lists to HTML lists
    storage_content=$(echo "$storage_content" | sed 's/^- \(.*\)/<li>\1<\/li>/g')
    storage_content=$(echo "$storage_content" | sed 's/^  - \(.*\)/<li style="margin-left: 20px;">\1<\/li>/g')
    
    # Convert markdown emphasis
    storage_content=$(echo "$storage_content" | sed 's/_\([^_]*\)_/<em>\1<\/em>/g')
    storage_content=$(echo "$storage_content" | sed 's/\*\*\([^*]*\)\*\*/<strong>\1<\/strong>/g')
    
    # Convert line breaks to paragraph tags
    storage_content=$(echo "$storage_content" | sed 's/^$/<\/p><p>/g' | sed 's/^[^<].*/<p>&<\/p>/g')
    
    # Wrap content in a proper structure
    storage_content="<p>$storage_content</p>"
    
    echo "$storage_content"
}

# Find page by title in space
find_page_by_title() {
    local space_key="$1"
    local page_title="$2"
    
    log "Searching for page: '$page_title' in space: $space_key"
    
    # URL encode the title for the search
    local encoded_title
    encoded_title=$(echo "$page_title" | sed 's/ /%20/g')
    
    local endpoint="/rest/api/content?spaceKey=${space_key}&title=${encoded_title}&expand=version"
    local response
    response=$(api_request "$endpoint")
    
    if [[ $? -eq 0 ]]; then
        local page_id
        page_id=$(echo "$response" | jq -r '.results[0].id // empty')
        
        if [[ -n "$page_id" ]]; then
            log "Found existing page with ID: $page_id"
            echo "$page_id"
            return 0
        fi
    fi
    
    log "Page not found: '$page_title'"
    return 1
}

# Get page version number
get_page_version() {
    local page_id="$1"
    
    local endpoint="/rest/api/content/${page_id}?expand=version"
    local response
    response=$(api_request "$endpoint")
    
    if [[ $? -eq 0 ]]; then
        local version
        version=$(echo "$response" | jq -r '.version.number')
        echo "$version"
        return 0
    fi
    
    return 1
}

# Create new Confluence page
create_confluence_page() {
    local space_key="$1"
    local page_title="$2"
    local content="$3"
    local parent_id="$4"
    
    log "Creating new page: '$page_title' in space: $space_key"
    
    # Convert content to Confluence storage format
    local storage_content
    storage_content=$(convert_to_confluence_storage "$content")
    
    # Build the JSON payload
    local json_payload
    if [[ -n "$parent_id" ]]; then
        json_payload=$(jq -n \
            --arg type "page" \
            --arg title "$page_title" \
            --arg space "$space_key" \
            --arg content "$storage_content" \
            --arg parent "$parent_id" \
            '{
                type: $type,
                title: $title,
                space: {key: $space},
                body: {
                    storage: {
                        value: $content,
                        representation: "storage"
                    }
                },
                ancestors: [
                    {id: $parent}
                ]
            }')
    else
        json_payload=$(jq -n \
            --arg type "page" \
            --arg title "$page_title" \
            --arg space "$space_key" \
            --arg content "$storage_content" \
            '{
                type: $type,
                title: $title,
                space: {key: $space},
                body: {
                    storage: {
                        value: $content,
                        representation: "storage"
                    }
                }
            }')
    fi
    
    local response
    response=$(api_request_with_data "POST" "/rest/api/content" "$json_payload")
    
    if [[ $? -eq 0 ]]; then
        local page_id
        page_id=$(echo "$response" | jq -r '.id')
        log "Successfully created page with ID: $page_id"
        echo "$page_id"
        return 0
    else
        error "Failed to create page: $response"
    fi
}

# Update existing Confluence page
update_confluence_page() {
    local page_id="$1"
    local page_title="$2"
    local content="$3"
    
    log "Updating existing page ID: $page_id"
    
    # Get current version number
    local current_version
    current_version=$(get_page_version "$page_id")
    
    if [[ $? -ne 0 ]]; then
        error "Failed to get current page version for ID: $page_id"
    fi
    
    local new_version=$((current_version + 1))
    log "Updating page from version $current_version to $new_version"
    
    # Convert content to Confluence storage format
    local storage_content
    storage_content=$(convert_to_confluence_storage "$content")
    
    # Build the JSON payload
    local json_payload
    json_payload=$(jq -n \
        --arg title "$page_title" \
        --arg content "$storage_content" \
        --argjson version "$new_version" \
        '{
            version: {number: $version},
            title: $title,
            body: {
                storage: {
                    value: $content,
                    representation: "storage"
                }
            }
        }')
    
    local response
    response=$(api_request_with_data "PUT" "/rest/api/content/${page_id}" "$json_payload")
    
    if [[ $? -eq 0 ]]; then
        log "Successfully updated page ID: $page_id"
        return 0
    else
        error "Failed to update page: $response"
    fi
}

# Update or create Confluence page with sitemap
update_confluence_sitemap_page() {
    local sitemap_content="$1"
    
    if [[ "$UPDATE_PAGE" != "true" ]]; then
        return 0
    fi
    
    log "Updating Confluence page with sitemap content..."
    
    # Build full page content
    local full_content="$PAGE_CONTENT_PREFIX"
    full_content+="$sitemap_content"
    full_content+="$PAGE_CONTENT_SUFFIX"
    
    local page_id="$PAGE_ID"
    
    # If no page ID provided, try to find page by title
    if [[ -z "$page_id" ]]; then
        page_id=$(find_page_by_title "$SPACE_KEY" "$PAGE_TITLE")
        
        if [[ $? -ne 0 && "$CREATE_IF_NOT_EXISTS" == "true" ]]; then
            # Create new page
            page_id=$(create_confluence_page "$SPACE_KEY" "$PAGE_TITLE" "$full_content" "$PARENT_PAGE_ID")
            
            if [[ $? -eq 0 ]]; then
                log "Successfully created new sitemap page with ID: $page_id"
                log "Page URL: ${CONFLUENCE_BASE_URL}/pages/viewpage.action?pageId=$page_id"
            fi
            return $?
        elif [[ $? -ne 0 ]]; then
            error "Page not found and CREATE_IF_NOT_EXISTS is false"
        fi
    fi
    
    # Update existing page
    if [[ -n "$page_id" ]]; then
        update_confluence_page "$page_id" "$PAGE_TITLE" "$full_content"
        
        if [[ $? -eq 0 ]]; then
            log "Successfully updated sitemap page with ID: $page_id"
            log "Page URL: ${CONFLUENCE_BASE_URL}/pages/viewpage.action?pageId=$page_id"
        fi
    fi
}

# Detect Confluence API version
detect_api_version() {
    log "Detecting Confluence API version..."
    
    local version_info
    version_info=$(api_request "/rest/api/space")
    
    if [[ $? -eq 0 ]]; then
        log "Successfully connected to Confluence REST API"
        return 0
    else
        error "Failed to connect to Confluence API. Check your URL and credentials."
    fi
}

# Get all pages in the space
get_space_pages() {
    log "Fetching pages for space: $SPACE_KEY"
    
    local all_pages=()
    local start=0
    local has_more=true
    
    while [[ "$has_more" == "true" ]]; do
        local endpoint="/rest/api/content?spaceKey=${SPACE_KEY}&type=page&limit=${API_LIMIT}&start=${start}&expand=${EXPAND_FIELDS}"
        local response
        response=$(api_request "$endpoint")
        
        if [[ $? -ne 0 ]]; then
            error "Failed to fetch pages from API"
        fi
        
        # Check if we have more results
        local size
        size=$(echo "$response" | jq -r '.size // 0')
        local limit
        limit=$(echo "$response" | jq -r '.limit // 0')
        
        if [[ "$size" -lt "$limit" ]]; then
            has_more=false
        else
            start=$((start + limit))
        fi
        
        # Extract pages from response
        local pages
        pages=$(echo "$response" | jq -r '.results[]')
        all_pages+=("$pages")
        
        log "Fetched $size pages (total so far: ${#all_pages[@]})"
    done
    
    # Combine all pages into a single JSON array
    printf '%s\n' "${all_pages[@]}" | jq -s '.'
}

# Build page hierarchy
build_hierarchy() {
    local pages="$1"
    
    # Create a map of page ID to page data
    local page_map="{}"
    local root_pages=()
    
    # First pass: create page map and identify root pages
    while IFS= read -r page; do
        local id title
        id=$(echo "$page" | jq -r '.id')
        title=$(echo "$page" | jq -r '.title')
        
        page_map=$(echo "$page_map" | jq --argjson page "$page" '. + {($page.id): $page}')
        
        # Check if page has ancestors (not a root page)
        local has_ancestors
        has_ancestors=$(echo "$page" | jq -r '.ancestors | length > 0')
        
        if [[ "$has_ancestors" == "false" ]]; then
            root_pages+=("$id")
        fi
        
    done < <(echo "$pages" | jq -c '.[]')
    
    echo "$page_map"
}

# Format page information
format_page_info() {
    local page="$1"
    local indent_level="$2"
    local format="$3"
    
    local id title url last_modified author version
    id=$(echo "$page" | jq -r '.id')
    title=$(echo "$page" | jq -r '.title')
    url="${CONFLUENCE_BASE_URL}$(echo "$page" | jq -r '._links.webui')"
    last_modified=$(echo "$page" | jq -r '.version.when // ""')
    author=$(echo "$page" | jq -r '.version.by.displayName // ""')
    version=$(echo "$page" | jq -r '.version.number // ""')
    
    # Create indentation
    local indent=""
    for ((i=0; i<indent_level; i++)); do
        indent+="$INDENT_CHAR"
    done
    
    case "$format" in
        markdown)
            local line="$indent- [$title]($url)"
            
            if [[ "$SHOW_LAST_MODIFIED" == "true" && -n "$last_modified" ]]; then
                line+=" _(modified: $last_modified)_"
            fi
            
            if [[ "$SHOW_AUTHOR" == "true" && -n "$author" ]]; then
                line+=" _(by: $author)_"
            fi
            
            if [[ "$SHOW_VERSION" == "true" && -n "$version" ]]; then
                line+=" _(v$version)_"
            fi
            
            echo "$line"
            ;;
            
        html)
            local line="$indent<li><a href=\"$url\">$title</a>"
            
            if [[ "$SHOW_LAST_MODIFIED" == "true" && -n "$last_modified" ]] || \
               [[ "$SHOW_AUTHOR" == "true" && -n "$author" ]] || \
               [[ "$SHOW_VERSION" == "true" && -n "$version" ]]; then
                line+=" <span class=\"meta\">("
                
                local meta_parts=()
                [[ "$SHOW_LAST_MODIFIED" == "true" && -n "$last_modified" ]] && meta_parts+=("modified: $last_modified")
                [[ "$SHOW_AUTHOR" == "true" && -n "$author" ]] && meta_parts+=("by: $author")
                [[ "$SHOW_VERSION" == "true" && -n "$version" ]] && meta_parts+=("v$version")
                
                line+=$(IFS=', '; echo "${meta_parts[*]}")
                line+=")</span>"
            fi
            
            line+="</li>"
            echo "$line"
            ;;
            
        csv)
            echo "\"$title\",\"$url\",\"$last_modified\",\"$author\",\"$version\",\"$indent_level\""
            ;;
            
        json)
            jq -n --arg title "$title" \
                  --arg url "$url" \
                  --arg modified "$last_modified" \
                  --arg author "$author" \
                  --arg version "$version" \
                  --argjson level "$indent_level" \
                  '{title: $title, url: $url, lastModified: $modified, author: $author, version: $version, level: $level}'
            ;;
    esac
}

# Generate sitemap content (returns as string)
generate_sitemap_content() {
    local pages="$1"
    local format="$2"
    
    local content=""
    
    # Initialize content based on format
    case "$format" in
        markdown)
            content="# Confluence Space Sitemap: $SPACE_KEY"$'\n'
            content+=""$'\n'
            content+="Generated on: $(date)"$'\n'
            content+="Space: [$SPACE_KEY]($CONFLUENCE_BASE_URL/display/$SPACE_KEY)"$'\n'
            content+=""$'\n'
            ;;
    esac
    
    # Process pages and build sitemap content
    while IFS= read -r page; do
        local formatted_page
        formatted_page=$(format_page_info "$page" 0 "$format")
        content+="$formatted_page"$'\n'
    done < <(echo "$pages" | jq -c '.[] | select(.type == "page")')
    
    echo "$content"
}

# Generate sitemap output
generate_sitemap() {
    local pages="$1"
    local output_file="$2"
    local format="$3"
    
    log "Generating sitemap in $format format..."
    
    # Initialize output file
    case "$format" in
        markdown)
            {
                echo "# Confluence Space Sitemap: $SPACE_KEY"
                echo ""
                echo "Generated on: $(date)"
                echo "Space: [$SPACE_KEY]($CONFLUENCE_BASE_URL/display/$SPACE_KEY)"
                echo ""
            } > "$output_file"
            ;;
            
        html)
            {
                echo "<!DOCTYPE html>"
                echo "<html><head><title>Confluence Space Sitemap: $SPACE_KEY</title>"
                echo "<style>"
                echo "  body { font-family: Arial, sans-serif; margin: 40px; }"
                echo "  .meta { color: #666; font-size: 0.9em; }"
                echo "  ul { list-style-type: none; padding-left: 20px; }"
                echo "  li { margin: 5px 0; }"
                echo "</style>"
                echo "</head><body>"
                echo "<h1>Confluence Space Sitemap: $SPACE_KEY</h1>"
                echo "<p>Generated on: $(date)</p>"
                echo "<p>Space: <a href=\"$CONFLUENCE_BASE_URL/display/$SPACE_KEY\">$SPACE_KEY</a></p>"
                echo "<ul>"
            } > "$output_file"
            ;;
            
        csv)
            echo "Title,URL,Last Modified,Author,Version,Level" > "$output_file"
            ;;
            
        json)
            {
                echo "{"
                echo "  \"space\": \"$SPACE_KEY\","
                echo "  \"generated\": \"$(date -Iseconds)\","
                echo "  \"baseUrl\": \"$CONFLUENCE_BASE_URL\","
                echo "  \"pages\": ["
            } > "$output_file"
            ;;
    esac
    
    # Process pages and build sitemap
    local page_array=()
    local first_json_item=true
    
    while IFS= read -r page; do
        local formatted_page
        formatted_page=$(format_page_info "$page" 0 "$format")
        
        case "$format" in
            json)
                if [[ "$first_json_item" == "true" ]]; then
                    first_json_item=false
                else
                    echo "," >> "$output_file"
                fi
                echo -n "    $formatted_page" >> "$output_file"
                ;;
            *)
                echo "$formatted_page" >> "$output_file"
                ;;
        esac
        
    done < <(echo "$pages" | jq -c '.[] | select(.type == "page")')
    
    # Finalize output file
    case "$format" in
        html)
            {
                echo "</ul>"
                echo "</body></html>"
            } >> "$output_file"
            ;;
            
        json)
            {
                echo ""
                echo "  ]"
                echo "}"
            } >> "$output_file"
            ;;
    esac
    
    log "Sitemap generated successfully: $output_file"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "Starting Confluence Space Sitemap Generator"
    
    # Load environment variables from .env file if it exists
    load_env_file
    
    # Parse command line arguments
    parse_args "$@"
    
    # Validate configuration
    validate_config
    
    # Detect API version and connectivity
    detect_api_version
    
    # Get all pages in the space
    local pages
    pages=$(get_space_pages)
    
    # Generate the sitemap
    if [[ "$UPDATE_PAGE" == "true" ]]; then
        # Generate sitemap content for page update
        local sitemap_content
        if [[ "$OUTPUT_FORMAT" == "markdown" ]]; then
            # Generate sitemap content in memory for markdown format
            sitemap_content=$(generate_sitemap_content "$pages" "$OUTPUT_FORMAT")
            update_confluence_sitemap_page "$sitemap_content"
        else
            log "Warning: Page update mode only supports markdown format. Converting to markdown for page update."
            sitemap_content=$(generate_sitemap_content "$pages" "markdown")
            update_confluence_sitemap_page "$sitemap_content"
        fi
        
        # Still generate file output if requested
        if [[ "$OUTPUT_FILE" != "/dev/null" && "$OUTPUT_FILE" != "" ]]; then
            generate_sitemap "$pages" "$OUTPUT_FILE" "$OUTPUT_FORMAT"
            log "File output also saved to: $OUTPUT_FILE"
        fi
    else
        # Standard file output mode
        generate_sitemap "$pages" "$OUTPUT_FILE" "$OUTPUT_FORMAT"
        log "Output saved to: $OUTPUT_FILE"
    fi
    
    log "Sitemap generation completed successfully!"
    
    # Show basic stats
    local page_count
    page_count=$(echo "$pages" | jq 'length')
    log "Total pages processed: $page_count"
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    error "jq is required but not installed. Please install jq to continue."
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    error "curl is required but not installed. Please install curl to continue."
fi

# Run main function with all arguments
main "$@"