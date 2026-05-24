#!/usr/bin/env bash
# install.sh — Bootstrap ~/.hermes/ configuration.
#
# Installs:
#   - config.yaml   from setup/config.yaml (committed in repo)
#   - .env          from $ENV environment variable (Codespaces secret)
#   - auth.json     from $AUTH environment variable (Codespaces secret)
#
# Usage:
#   ./setup/install.sh           # Install into ~/.hermes/
#   ./setup/install.sh --dry-run # Show what would be done
#
# Idempotent: existing files are backed up as .bak before overwrite.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "[DRY RUN] No files will be written."
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Hermes Agent — Config Bootstrap"
echo " Target: $HERMES_HOME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

errors=0

# --- config.yaml (from repo file) ---
config_src="$SCRIPT_DIR/config.yaml"
config_dest="$HERMES_HOME/config.yaml"

if [[ ! -f "$config_src" ]]; then
    echo "  [ERROR] config.yaml not found at $config_src"
    errors=$((errors + 1))
else
    if [[ "$DRY_RUN" == true ]]; then
        [[ -f "$config_dest" ]] && echo "  [WOULD BACKUP] $config_dest"
        echo "  [WOULD INSTALL] config.yaml"
    else
        mkdir -p "$HERMES_HOME"
        [[ -f "$config_dest" ]] && cp "$config_dest" "${config_dest}.bak" && echo "  [BACKUP] config.yaml → config.yaml.bak"
        cp "$config_src" "$config_dest"
        echo "  [INSTALLED] config.yaml"
    fi
fi

# --- .env (from $ENV secret) ---
env_dest="$HERMES_HOME/.env"

if [[ -z "${ENV:-}" ]]; then
    echo "  [SKIP] .env — \$ENV variable not set"
else
    if [[ "$DRY_RUN" == true ]]; then
        [[ -f "$env_dest" ]] && echo "  [WOULD BACKUP] $env_dest"
        echo "  [WOULD INSTALL] .env (from \$ENV secret, $(printf '%s' "$ENV" | wc -l) lines)"
    else
        mkdir -p "$HERMES_HOME"
        [[ -f "$env_dest" ]] && cp "$env_dest" "${env_dest}.bak" && echo "  [BACKUP] .env → .env.bak"
        printf '%s\n' "$ENV" > "$env_dest"
        chmod 600 "$env_dest"
        echo "  [INSTALLED] .env (from \$ENV secret)"
    fi
fi

# --- auth.json (from $AUTH secret) ---
auth_dest="$HERMES_HOME/auth.json"

if [[ -z "${AUTH:-}" ]]; then
    echo "  [SKIP] auth.json — \$AUTH variable not set"
else
    if [[ "$DRY_RUN" == true ]]; then
        [[ -f "$auth_dest" ]] && echo "  [WOULD BACKUP] $auth_dest"
        echo "  [WOULD INSTALL] auth.json (from \$AUTH secret)"
    else
        mkdir -p "$HERMES_HOME"
        [[ -f "$auth_dest" ]] && cp "$auth_dest" "${auth_dest}.bak" && echo "  [BACKUP] auth.json → auth.json.bak"
        printf '%s\n' "$AUTH" > "$auth_dest"
        chmod 600 "$auth_dest"
        echo "  [INSTALLED] auth.json (from \$AUTH secret)"
    fi
fi

echo ""
if [[ "$DRY_RUN" == false && $errors -eq 0 ]]; then
    echo "✓ Configuration installed. Restart hermes for changes to take effect."
elif [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Complete — no changes made."
else
    echo "⚠ Completed with $errors error(s)."
    exit 1
fi
