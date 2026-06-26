#!/bin/sh
# Installs Xcode Command Line Tools (a Homebrew prerequisite) and then Homebrew.
# Fleet runs this script as root. softwareupdate/CLT install must run as root;
# Homebrew itself must NOT run as root, so it is run as the console user.

CONSOLE_USER=$(stat -f "%Su" /dev/console)

if [ "$CONSOLE_USER" = "root" ] || [ -z "$CONSOLE_USER" ] || [ "$CONSOLE_USER" = "loginwindow" ]; then
  echo "No non-root user logged in; cannot install Homebrew."
  exit 1
fi

# 1. Ensure Xcode Command Line Tools are installed.
#    Homebrew's NONINTERACTIVE installer does not reliably install the CLT,
#    so install them headlessly first using the softwareupdate on-demand trick.
if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools..."
  CLT_PLACEHOLDER="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  touch "$CLT_PLACEHOLDER"
  CLT_LABEL=$(softwareupdate -l 2>/dev/null \
    | grep -B 1 -E 'Command Line Tools' \
    | awk -F'*' '/^ *\*/ {print $2}' \
    | sed -e 's/^ *Label: //' -e 's/^ *//' \
    | sort -V \
    | tail -n 1)
  if [ -n "$CLT_LABEL" ]; then
    softwareupdate -i "$CLT_LABEL" --verbose
  fi
  rm -f "$CLT_PLACEHOLDER"
  if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
    echo "Failed to install Command Line Tools; cannot install Homebrew."
    exit 1
  fi
fi

# 2. Install Homebrew as the console user if it is not already present.
if sudo -u "$CONSOLE_USER" /bin/bash -c 'eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"; command -v brew' >/dev/null 2>&1; then
  echo "Homebrew is already installed."
  exit 0
fi

sudo -u "$CONSOLE_USER" /bin/bash -c 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
