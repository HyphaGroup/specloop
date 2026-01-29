#!/bin/bash
# Install script for specloop
# Supports: Factory Droid (.factory/) and OpenCode (.opencode/)
# Features: validation, backup, auto-configuration, uninstall

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRY_RUN=false
VERBOSE=false
UNINSTALL=false
SKIP_DEPS=false
TARGET=""
PLATFORM=""  # "droid", "opencode", or "both" - auto-detected or specified

# Platform-specific directory names
# Droid:    .factory/commands, .factory/skills, .factory/hooks, ~/.factory
# OpenCode: .opencode/command, .opencode/skill, (no hooks), ~/.config/opencode

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    --skip-deps)
      SKIP_DEPS=true
      shift
      ;;
    --droid)
      PLATFORM="droid"
      shift
      ;;
    --opencode)
      PLATFORM="opencode"
      shift
      ;;
    --both)
      PLATFORM="both"
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [TARGET_DIR] [OPTIONS]"
      echo ""
      echo "Install specloop augmentation for Factory Droid or OpenCode."
      echo ""
      echo "Arguments:"
      echo "  TARGET_DIR    Target project directory (default: current directory)"
      echo ""
      echo "Options:"
      echo "  --droid       Install for Factory Droid (.factory/)"
      echo "  --opencode    Install for OpenCode (.opencode/)"
      echo "  --both        Install for both platforms"
      echo "  --dry-run     Show what would be done without making changes"
      echo "  --verbose     Show detailed output"
      echo "  --uninstall   Remove installation from target"
      echo "  --skip-deps   Skip dependency checks"
      echo "  --help        Show this help message"
      echo ""
      echo "Platform Detection:"
      echo "  - If ~/.factory exists, assumes Droid"
      echo "  - If ~/.config/opencode exists, assumes OpenCode"
      echo "  - Use --droid or --opencode to override"
      echo ""
      echo "Examples:"
      echo "  $0 .                    # Install in current directory (auto-detect platform)"
      echo "  $0 . --both             # Install for both Droid and OpenCode"
      echo "  $0 . --opencode         # Install for OpenCode only"
      echo "  $0 ~/.factory --droid   # Install globally for Droid"
      echo "  $0 . --dry-run          # Preview what would be installed"
      echo "  $0 . --uninstall        # Remove installation"
      exit 0
      ;;
    -*)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Run '$0 --help' for usage information."
      exit 1
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

# Default target to current directory
TARGET="${TARGET:-.}"

# Resolve to absolute path
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
  echo -e "${RED}Error: Target directory does not exist: $TARGET${NC}"
  exit 1
}

# Auto-detect platform if not specified
detect_platform() {
  if [[ -n "$PLATFORM" ]]; then
    return  # Already specified via flag
  fi
  
  # Check if target path gives us a hint
  if [[ "$TARGET" == *".factory"* ]]; then
    PLATFORM="droid"
    return
  fi
  if [[ "$TARGET" == *".opencode"* ]] || [[ "$TARGET" == *"opencode"* ]]; then
    PLATFORM="opencode"
    return
  fi
  
  # Check if target already has a config dir
  if [[ -d "$TARGET/.factory" ]]; then
    PLATFORM="droid"
    return
  fi
  if [[ -d "$TARGET/.opencode" ]]; then
    PLATFORM="opencode"
    return
  fi
  
  # Check global directories
  if [[ -d "$HOME/.factory" ]]; then
    PLATFORM="droid"
    return
  fi
  if [[ -d "$HOME/.config/opencode" ]]; then
    PLATFORM="opencode"
    return
  fi
  
  # Default to droid
  PLATFORM="droid"
}

# Get platform-specific paths
get_config_dir() {
  if [[ "$PLATFORM" == "opencode" ]]; then
    echo ".opencode"
  else
    echo ".factory"
  fi
}

get_commands_dir() {
  if [[ "$PLATFORM" == "opencode" ]]; then
    echo "command"
  else
    echo "commands"
  fi
}

get_skills_dir() {
  if [[ "$PLATFORM" == "opencode" ]]; then
    echo "skill"
  else
    echo "skills"
  fi
}

get_global_dir() {
  if [[ "$PLATFORM" == "opencode" ]]; then
    echo "$HOME/.config/opencode"
  else
    echo "$HOME/.factory"
  fi
}

# Check if target is already a config directory (e.g., ~/.factory or ~/.config/opencode)
is_config_dir() {
  local dir="$1"
  local base="$(basename "$dir")"
  [[ "$base" == ".factory" ]] || [[ "$base" == ".opencode" ]] || [[ "$base" == "opencode" && "$(basename "$(dirname "$dir")")" == ".config" ]]
}

log() {
  if [[ "$VERBOSE" == "true" ]]; then
    echo -e "${BLUE}[INFO]${NC} $1"
  fi
}

success() {
  echo -e "${GREEN}✓${NC} $1"
}

warn() {
  echo -e "${YELLOW}⚠${NC} $1"
}

error() {
  echo -e "${RED}✗${NC} $1"
}

# Check dependencies
check_deps() {
  if [[ "$SKIP_DEPS" == "true" ]]; then
    log "Skipping dependency checks"
    return
  fi
  
  local missing=()
  local optional_missing=()
  
  if ! command -v jq >/dev/null 2>&1; then
    missing+=("jq")
  fi
  
  if ! command -v openspec >/dev/null 2>&1; then
    missing+=("openspec")
  fi
  
  # bd (Beads) is optional but needed for multi-agent coordination
  if ! command -v bd >/dev/null 2>&1; then
    optional_missing+=("bd")
  fi
  
  if [ ${#missing[@]} -gt 0 ]; then
    warn "Missing recommended dependencies: ${missing[*]}"
    echo "  The augmentation may not function correctly without these."
    echo "  Use --skip-deps to ignore this warning."
    echo ""
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  else
    log "All dependencies found"
  fi
  
  # Warn about optional dependencies
  if [ ${#optional_missing[@]} -gt 0 ]; then
    echo ""
    warn "Optional dependency missing: bd (Beads)"
    echo "  Multi-agent coordination features require Beads."
    echo "  Install with: npm install -g @beads/bd"
    echo "  Then run 'bd init' in your project to enable coordination."
    echo ""
  fi
}

# Backup existing file if it exists
backup_if_exists() {
  local file=$1
  if [[ -f "$file" ]]; then
    local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
    if [[ "$DRY_RUN" == "true" ]]; then
      log "Would backup: $file -> $backup"
    else
      cp "$file" "$backup"
      log "Backed up: $file -> $backup"
    fi
  fi
}

# Auto-configure hooks in settings.json
configure_hooks() {
  local install_base="${1:-$TARGET/.factory}"
  local settings="$install_base/settings.json"
  
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "Would configure Stop hook in $settings"
    return
  fi
  
  # Create settings file if it doesn't exist
  if [[ ! -f "$settings" ]]; then
    echo '{}' > "$settings"
    log "Created $settings"
  fi
  
  # Check if Stop hook already configured for openspec
  if jq -e '.hooks.Stop[]?.hooks[]? | select(.command | contains("openspec-stop-hook"))' "$settings" >/dev/null 2>&1; then
    warn "Stop hook already configured in settings.json"
    return
  fi
  
  # Backup before modifying
  backup_if_exists "$settings"
  
  # Add or merge Stop hook configuration
  local tmp_file="${settings}.tmp.$$"
  
  if jq -e '.hooks.Stop' "$settings" >/dev/null 2>&1; then
    # Stop hooks exist, append to array
    jq '.hooks.Stop += [{
      "hooks": [{
        "type": "command",
        "command": "\"$FACTORY_PROJECT_DIR\"/.factory/hooks/openspec-stop-hook.sh",
        "timeout": 30
      }]
    }]' "$settings" > "$tmp_file"
  else
    # No Stop hooks, create structure
    jq '.hooks = ((.hooks // {}) + {
        "Stop": [{
          "hooks": [{
            "type": "command",
            "command": "\"$FACTORY_PROJECT_DIR\"/.factory/hooks/openspec-stop-hook.sh",
            "timeout": 30
          }]
        }]
      })' "$settings" > "$tmp_file"
  fi
  
  mv "$tmp_file" "$settings"
  success "Configured Stop hook in settings.json"
}

# Remove hook configuration from settings.json
unconfigure_hooks() {
  local install_base="${1:-$TARGET/.factory}"
  local settings="$install_base/settings.json"
  
  if [[ ! -f "$settings" ]]; then
    return
  fi
  
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "Would remove Stop hook from $settings"
    return
  fi
  
  # Remove openspec stop hook entries
  local tmp_file="${settings}.tmp.$$"
  jq '.hooks.Stop = [.hooks.Stop[]? | select(.hooks[]?.command | contains("openspec-stop-hook") | not)]' "$settings" > "$tmp_file"
  mv "$tmp_file" "$settings"
  
  # Clean up empty Stop array
  if jq -e '.hooks.Stop == []' "$settings" >/dev/null 2>&1; then
    jq 'del(.hooks.Stop)' "$settings" > "$tmp_file"
    mv "$tmp_file" "$settings"
  fi
  
  # Clean up empty hooks object
  if jq -e '.hooks == {}' "$settings" >/dev/null 2>&1; then
    jq 'del(.hooks)' "$settings" > "$tmp_file"
    mv "$tmp_file" "$settings"
  fi
  
  log "Removed Stop hook from settings.json"
}

# Uninstall for a single platform, returns count of removed items
uninstall_for_platform() {
  local plat="$1"
  local removed=0
  
  local CONFIG_DIR COMMANDS_DIR SKILLS_DIR
  if [[ "$plat" == "opencode" ]]; then
    CONFIG_DIR=".opencode"
    COMMANDS_DIR="command"
    SKILLS_DIR="skill"
  else
    CONFIG_DIR=".factory"
    COMMANDS_DIR="commands"
    SKILLS_DIR="skills"
  fi
  
  # Determine install base
  local INSTALL_BASE="$TARGET/$CONFIG_DIR"
  if is_config_dir "$TARGET"; then
    INSTALL_BASE="$TARGET"
  fi
  
  # Check if config dir exists
  if [[ ! -d "$INSTALL_BASE" ]]; then
    log "No $CONFIG_DIR directory found, skipping $plat"
    echo "$removed"
    return
  fi
  
  echo -e "${BLUE}Uninstalling from:${NC} $INSTALL_BASE (platform: $plat)"
  echo ""
  
  for cmd in openspec-apply-loop.md openspec-prioritize.md openspec-cancel-loop.md openspec-status.md; do
    local file="$INSTALL_BASE/$COMMANDS_DIR/$cmd"
    if [[ -f "$file" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would remove: $cmd"
      else
        rm -f "$file"
        success "Removed: $cmd"
      fi
      ((removed++)) || true
    fi
  done
  
  local hook="$INSTALL_BASE/hooks/openspec-stop-hook.sh"
  if [[ -f "$hook" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "Would remove: openspec-stop-hook.sh"
    else
      rm -f "$hook"
      success "Removed: openspec-stop-hook.sh"
    fi
    ((removed++)) || true
  fi
  
  # Remove state files
  local state="$INSTALL_BASE/openspec-loop.json"
  if [[ -f "$state" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "Would remove: openspec-loop.json"
    else
      rm -f "$state"
      success "Removed: openspec-loop.json"
    fi
    ((removed++)) || true
  fi
  
  # Remove scripts
  for script in openspec-status openspec-import-beads; do
    local script_file="$INSTALL_BASE/scripts/$script"
    if [[ -f "$script_file" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would remove: scripts/$script"
      else
        rm -f "$script_file"
        success "Removed: scripts/$script"
      fi
      ((removed++)) || true
    fi
  done
  
  # Remove skills (directories)
  for skill in openspec-bootstrap; do
    local skill_dir="$INSTALL_BASE/$SKILLS_DIR/$skill"
    if [[ -d "$skill_dir" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would remove: skills/$skill/"
      else
        rm -rf "$skill_dir"
        success "Removed: skills/$skill/"
      fi
      ((removed++)) || true
    fi
    # Also remove old single-file format if present
    local old_file="$INSTALL_BASE/$SKILLS_DIR/${skill}.md"
    if [[ -f "$old_file" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would remove: skills/${skill}.md (legacy)"
      else
        rm -f "$old_file"
        success "Removed: skills/${skill}.md (legacy)"
      fi
      ((removed++)) || true
    fi
  done
  
  # Platform-specific cleanup
  if [[ "$plat" == "droid" ]]; then
    unconfigure_hooks "$INSTALL_BASE"
  else
    # Remove OpenCode plugin
    local plugin="$INSTALL_BASE/plugins/openspec-loop.ts"
    if [[ -f "$plugin" ]]; then
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would remove: plugins/openspec-loop.ts"
      else
        rm -f "$plugin"
        success "Removed: plugins/openspec-loop.ts"
      fi
      ((removed++)) || true
    fi
  fi
  
  echo "$removed"
}

# Main uninstall
do_uninstall() {
  detect_platform
  
  local total_removed=0
  
  if [[ "$PLATFORM" == "both" ]]; then
    local droid_removed opencode_removed
    droid_removed=$(uninstall_for_platform "droid")
    echo ""
    opencode_removed=$(uninstall_for_platform "opencode")
    total_removed=$((droid_removed + opencode_removed))
  else
    total_removed=$(uninstall_for_platform "$PLATFORM")
  fi
  
  echo ""
  if [[ $total_removed -eq 0 ]]; then
    echo "Nothing to uninstall."
  elif [[ "$DRY_RUN" == "true" ]]; then
    echo -e "${YELLOW}Dry run complete. Use without --dry-run to actually uninstall.${NC}"
  else
    echo -e "${GREEN}Uninstall complete!${NC}"
  fi
}

# Install for a single platform
install_for_platform() {
  local plat="$1"
  
  local CONFIG_DIR COMMANDS_DIR SKILLS_DIR
  if [[ "$plat" == "opencode" ]]; then
    CONFIG_DIR=".opencode"
    COMMANDS_DIR="command"
    SKILLS_DIR="skill"
  else
    CONFIG_DIR=".factory"
    COMMANDS_DIR="commands"
    SKILLS_DIR="skills"
  fi
  
  # Determine install base
  local INSTALL_BASE="$TARGET/$CONFIG_DIR"
  if is_config_dir "$TARGET"; then
    INSTALL_BASE="$TARGET"
  fi
  
  echo -e "${BLUE}Installing to:${NC} $INSTALL_BASE (platform: $plat)"
  echo ""
  
  if [[ "$DRY_RUN" == "false" ]]; then
    mkdir -p "$INSTALL_BASE/$COMMANDS_DIR" "$INSTALL_BASE/$SKILLS_DIR"
    # Only create hooks dir for Droid
    if [[ "$plat" == "droid" ]]; then
      mkdir -p "$INSTALL_BASE/hooks"
    fi
    log "Created directories"
  fi
  
  # Install commands
  for cmd in "$SCRIPT_DIR/commands"/*.md; do
    local name="$(basename "$cmd")"
    local dest="$INSTALL_BASE/$COMMANDS_DIR/$name"
    
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "Would install: commands/$name"
    else
      backup_if_exists "$dest"
      cp "$cmd" "$dest"
      success "Installed: commands/$name"
    fi
  done
  
  # Install scripts inside config directory
  mkdir -p "$INSTALL_BASE/scripts"
  
  for script in "$SCRIPT_DIR/scripts"/*; do
    [[ -f "$script" ]] || continue
    local name="$(basename "$script")"
    local dest="$INSTALL_BASE/scripts/$name"
    
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "Would install: scripts/$name"
    else
      backup_if_exists "$dest"
      cp "$script" "$dest"
      chmod +x "$dest"
      success "Installed: scripts/$name"
    fi
  done
  
  # Install hook script (Droid) or plugin (OpenCode)
  if [[ "$plat" == "droid" ]]; then
    local hook_dest="$INSTALL_BASE/hooks/openspec-stop-hook.sh"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "Would install: hooks/openspec-stop-hook.sh"
    else
      backup_if_exists "$hook_dest"
      cp "$SCRIPT_DIR/hooks/stop-hook.sh" "$hook_dest"
      chmod +x "$hook_dest"
      success "Installed: hooks/openspec-stop-hook.sh"
    fi
  else
    # OpenCode uses plugins for event handling
    mkdir -p "$INSTALL_BASE/plugins"
    local plugin_dest="$INSTALL_BASE/plugins/openspec-loop.ts"
    if [[ "$DRY_RUN" == "true" ]]; then
      echo "Would install: plugins/openspec-loop.ts"
    else
      backup_if_exists "$plugin_dest"
      cp "$SCRIPT_DIR/plugins/openspec-loop.ts" "$plugin_dest"
      success "Installed: plugins/openspec-loop.ts"
    fi
  fi
  
  # Install skills (each skill is a directory with SKILL.md)
  if [[ -d "$SCRIPT_DIR/skills" ]]; then
    for skill_dir in "$SCRIPT_DIR/skills"/*/; do
      [[ -d "$skill_dir" ]] || continue
      local name="$(basename "$skill_dir")"
      local dest="$INSTALL_BASE/$SKILLS_DIR/$name"
      
      if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would install: skills/$name/"
      else
        # Remove existing skill dir if present
        if [[ -d "$dest" ]]; then
          rm -rf "$dest"
          log "Replaced existing: skills/$name/"
        fi
        cp -r "$skill_dir" "$dest"
        success "Installed: skills/$name/"
      fi
    done
  fi
  
  # Configure hooks (Droid) or note about plugin (OpenCode)
  echo ""
  if [[ "$plat" == "droid" ]]; then
    configure_hooks "$INSTALL_BASE"
  else
    success "OpenCode plugin installed for session.idle event handling"
    echo "  The loop will auto-continue when the session becomes idle."
  fi
}

# Main install
do_install() {
  detect_platform
  check_deps
  
  if [[ "$PLATFORM" == "both" ]]; then
    install_for_platform "droid"
    echo ""
    echo "---"
    echo ""
    install_for_platform "opencode"
    
    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
      echo -e "${YELLOW}Dry run complete. Use without --dry-run to actually install.${NC}"
    else
      echo -e "${GREEN}Installation complete for both platforms!${NC}"
      echo ""
      echo "Available commands:"
      echo "  /openspec-prioritize  - Create priority queue for changes"
      echo "  /openspec-apply-loop  - Start the loop"
      echo "  /openspec-cancel-loop - Cancel the loop"
      echo ""
      echo "Available skills:"
      echo "  openspec-bootstrap    - Bootstrap new project for OpenSpec"
      echo ""
      echo "Restart droid/opencode to pick up the new configuration."
    fi
  else
    install_for_platform "$PLATFORM"
    
    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
      echo -e "${YELLOW}Dry run complete. Use without --dry-run to actually install.${NC}"
    else
      echo -e "${GREEN}Installation complete!${NC} (platform: $PLATFORM)"
      echo ""
      echo "Available commands:"
      echo "  /openspec-prioritize  - Create priority queue for changes"
      echo "  /openspec-apply-loop  - Start the loop"
      echo "  /openspec-cancel-loop - Cancel the loop"
      echo ""
      echo "Available skills:"
      echo "  openspec-bootstrap    - Bootstrap new project for OpenSpec"
      echo ""
      if [[ "$PLATFORM" == "droid" ]]; then
        echo "Restart droid to pick up the new configuration."
      else
        echo "Restart opencode to pick up the new configuration."
      fi
    fi
  fi
}

# Main
if [[ "$UNINSTALL" == "true" ]]; then
  do_uninstall
else
  do_install
fi
