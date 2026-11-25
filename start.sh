#!/bin/sh
# Clean Your Phone: one-command start for Claude Code (macOS / Linux).
#   curl -fsSL https://raw.githubusercontent.com/posp3h/cleanyourphone/main/start.sh | sh
# Installs or updates the plugin, makes a work folder for backups and starts the guided session.
set -e
REPO=posp3h/cleanyourphone
PLUGIN=cleanyourphone@cleanyourphone

if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code is not installed. Install it first:"
  echo "  curl -fsSL https://claude.ai/install.sh | bash"
  echo "then open a new terminal and run this command again."
  exit 1
fi

echo "Installing / updating the cleanyourphone plugin..."
claude plugin marketplace add "$REPO" >/dev/null </dev/null || true
claude plugin marketplace update cleanyourphone >/dev/null </dev/null || true
claude plugin install "$PLUGIN" >/dev/null </dev/null
claude plugin update "$PLUGIN" >/dev/null </dev/null || true

WORK="$HOME/cleanyourphone"
mkdir -p "$WORK"
cd "$WORK"
echo "Work folder (backups and logs): $WORK"

LANG_NAME=${LC_ALL:-${LC_MESSAGES:-${LANG:-en_US}}}
# stdin is the curl pipe here, so give Claude Code the real terminal.
exec claude "Run the cleanyourphone:debloat-phone skill and guide me through it step by step. My system locale is $LANG_NAME: talk to me in that language unless I write in another one." </dev/tty
