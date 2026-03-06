#!/bin/sh
CONSOLE_USER=$(stat -f "%Su" /dev/console)
if [ "$CONSOLE_USER" = "root" ] || [ -z "$CONSOLE_USER" ]; then
  echo "No non-root user logged in."
  exit 1
fi
sudo -u "$CONSOLE_USER" /bin/bash -c 'eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"; brew install pandoc'
