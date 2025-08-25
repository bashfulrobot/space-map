{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "confluence-sitemap-generator";
  
  buildInputs = with pkgs; [
    # Core dependencies for the script
    curl
    jq
    
    # Development and debugging tools
    bash
    coreutils
    
    # Optional: useful for development
    shellcheck    # Shell script linting
    git          # Version control
    gnumake      # If you add a Makefile later
  ];

  shellHook = ''
    echo "🚀 Confluence Space Sitemap Generator Development Environment"
    echo "Dependencies loaded:"
    echo "  ✓ curl $(curl --version | head -n1 | cut -d' ' -f2)"
    echo "  ✓ jq $(jq --version)"
    echo ""
    echo "Usage:"
    echo "  ./confluence-sitemap.sh --help"
    echo ""
    echo "Example setup:"
    echo "  export CONFLUENCE_BASE_URL=\"https://your-domain.atlassian.net/wiki\""
    echo "  export CONFLUENCE_TOKEN=\"your-token\""
    echo "  export SPACE_KEY=\"MYSPACE\""
    echo "  ./confluence-sitemap.sh"
    echo ""
    
    # Make the script executable if it exists
    if [ -f "./confluence-sitemap.sh" ]; then
      chmod +x ./confluence-sitemap.sh
      echo "✓ Made confluence-sitemap.sh executable"
    fi
  '';

  # Environment variables for development
  CONFLUENCE_SCRIPT_DEV = "1";
}