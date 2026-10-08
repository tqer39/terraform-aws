#!/bin/bash

#
# This script is used to setup the repository for the first time.
#

case "${SETUP_PROFILE:-full}" in
  full|cli) ;;
  *)
    echo "SETUP_PROFILE must be full or cli" >&2
    exit 2
    ;;
esac

# Reuse Homebrew, including runner installations not yet on PATH.
find_homebrew() {
  if command -v brew &> /dev/null; then
    return 0
  fi
  for brew_prefix in /home/linuxbrew/.linuxbrew /opt/homebrew /usr/local; do
    if [ -x "$brew_prefix/bin/brew" ]; then
      export PATH="$brew_prefix/bin:$PATH"
      return 0
    fi
  done
  return 1
}

# Install Homebrew only when it is unavailable.
if ! find_homebrew; then
  if [ "$(uname)" == 'Darwin' ] || [ "$(uname -s)" == 'Linux' ]; then
    homebrew_installer=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh) || exit 1
    /bin/bash -c "$homebrew_installer" || exit 1
  fi
  find_homebrew || exit 1
fi

# Add the selected Homebrew installation to PATH.
brew_prefix=$(brew --prefix) || exit 1
# shellcheck disable=SC2016 # Expand PATH when the shell starts.
printf 'export PATH=%q/bin:%q/sbin:$PATH\n' "$brew_prefix" "$brew_prefix" >> ~/.bashrc
export PATH="$brew_prefix/bin:$brew_prefix/sbin:$PATH"

# Install git if not available
if ! command -v git &> /dev/null; then
  brew install git
fi

# Install anyenv
if ! command -v anyenv &> /dev/null; then
  git clone https://github.com/anyenv/anyenv ~/.anyenv
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
  mkdir -p "$(anyenv root)/plugins"
  git clone https://github.com/znz/anyenv-update.git "$(anyenv root)/plugins/anyenv-update"

  # shellcheck disable=SC2016 # Initialize anyenv when the shell starts.
  echo 'eval "$(anyenv init -)"' >> ~/.bashrc
  # Continue setup in this process; exec would skip the remaining installers.
fi

# Install tfenv using anyenv
if command -v anyenv &> /dev/null; then
  if [ ! -d "$(anyenv root)/envs/tfenv" ]; then
    anyenv install tfenv
  fi
fi

# Install Terraform CLI using tfenv and .terraform-version
if command -v tfenv &> /dev/null; then
  if [ -f ".terraform-version" ]; then
    tfenv install
    tfenv use
  fi
fi

# Install Rancher Desktop
if [ "${SETUP_PROFILE:-full}" = full ] && ! command -v rancher-desktop &> /dev/null; then
  if [ "$(uname)" == 'Darwin' ]; then
    brew install --cask rancher
  elif [ "$(uname -s)" == 'Linux' ]; then
    curl -fsSL https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/rancher-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/rancher-archive-keyring.gpg] https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ ./" | sudo tee /etc/apt/sources.list.d/rancher.list
    sudo apt-get update
    sudo apt-get install -y rancher-desktop
  fi
fi

# Install session-manager-plugin
if ! command -v session-manager-plugin &> /dev/null; then
  if [ "$(uname)" == 'Darwin' ]; then
    brew install --cask session-manager-plugin
  elif [ "$(uname -s)" == 'Linux' ]; then
    curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb"
    sudo dpkg -i /tmp/session-manager-plugin.deb
    rm /tmp/session-manager-plugin.deb
  fi
fi

# Install aws-vault
if ! command -v aws-vault &> /dev/null; then
  if [ "$(uname)" == 'Darwin' ]; then
    brew install --cask aws-vault
  elif [ "$(uname -s)" == 'Linux' ]; then
    brew install aws-vault
  fi
fi

# Preserve Homebrew PATH for subsequent GitHub Actions steps.
if [ -n "${GITHUB_PATH:-}" ]; then
  brew --prefix | while IFS= read -r brew_prefix; do
    printf '%s/bin\n%s/sbin\n' "$brew_prefix" "$brew_prefix" >> "$GITHUB_PATH"
  done
fi
