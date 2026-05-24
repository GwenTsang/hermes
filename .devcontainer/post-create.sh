#!/usr/bin/env bash
# .devcontainer/post-create.sh — Runs automatically after Codespace creation.
#
# Steps:
#   1. Wait for any background apt processes to finish (avoids dpkg lock conflicts)
#   2. Run the main Hermes install script (Python venv, Node deps, Playwright, etc.)
#   3. Bootstrap user config from Codespaces secrets ($ENV, $AUTH)
#   4. Add hermes to PATH for this session

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "════════════════════════════════════════════════════"
echo " Hermes Agent — Codespace Setup"
echo "════════════════════════════════════════════════════"
echo ""

# ─── Step 1: Wait for apt lock ───────────────────────────────────────────────
wait_for_apt_lock() {
    local max_wait=120
    local waited=0
    command -v apt-get >/dev/null 2>&1 || return 0

    while [ $waited -lt $max_wait ]; do
        local locked=false
        for lf in /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
            if [ -f "$lf" ] && fuser "$lf" >/dev/null 2>&1; then
                locked=true
                break
            fi
        done
        if [ "$locked" = false ]; then
            return 0
        fi
        if [ $waited -eq 0 ]; then
            echo "⏳ Waiting for apt/dpkg lock (background process using it)..."
        fi
        sleep 2
        waited=$((waited + 2))
    done
    echo "⚠ apt lock still held after ${max_wait}s — proceeding anyway"
}

echo "→ Checking for apt lock..."
wait_for_apt_lock
echo "✓ apt lock free"
echo ""

# ─── Step 2: Main Hermes install ─────────────────────────────────────────────
echo "→ Running Hermes Agent installer..."
cd "$REPO_DIR/scripts"
bash install.sh
echo ""

# ─── Step 3: Bootstrap user config ───────────────────────────────────────────
echo "→ Bootstrapping user configuration..."
cd "$REPO_DIR"
bash setup/install.sh
echo ""

# ─── Step 4: PATH setup ──────────────────────────────────────────────────────
# The install script adds hermes to ~/.local/bin and updates .bashrc,
# but the current shell doesn't have it yet. Source bashrc for good measure.
if [ -f "$HOME/.bashrc" ]; then
    # shellcheck disable=SC1091
    source "$HOME/.bashrc" 2>/dev/null || true
fi

echo ""
echo "════════════════════════════════════════════════════"
echo " ✓ Hermes Agent ready!"
echo ""
echo "   Run:  hermes"
echo "════════════════════════════════════════════════════"
