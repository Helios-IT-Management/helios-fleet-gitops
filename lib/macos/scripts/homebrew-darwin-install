#!/bin/sh

CONSOLE_USER=$(stat -f "%Su" /dev/console)

if [ "$CONSOLE_USER" = "root" ] || [ -z "$CONSOLE_USER" ]; then
  echo "No non-root user logged in; cannot install Homebrew."
  exit 1
fi

if sudo -u "$CONSOLE_USER" /bin/bash -c 'eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"; command -v brew' >/dev/null 2>&1; then
  echo "Homebrew is already installed."
  exit 0
fi

sudo -u "$CONSOLE_USER" /bin/bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
