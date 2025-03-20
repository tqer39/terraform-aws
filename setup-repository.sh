#!/bin/bash

#
# This script is used to setup the repository for the first time.
#

# Install Homebrew
if [ "$(uname)" == 'Darwin' ]; then
  # macOS
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
  # Linux
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add Homebrew to PATH
if [ -d "/home/linuxbrew/.linuxbrew/bin" ]; then
  echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"' >> ~/.bashrc
  export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
  source ~/.bashrc
elif [ -d "/opt/homebrew/bin" ]; then
  echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.bashrc
  export PATH="/opt/homebrew/bin:$PATH"
  source ~/.bashrc
fi

# Install git if not available
if ! command -v git &> /dev/null; then
  brew install git
fi

# Install anyenv
if ! command -v anyenv &> /dev/null; then
  git clone https://github.com/anyenv/anyenv ~/.anyenv
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
  mkdir -p $(anyenv root)/plugins
  git clone https://github.com/znz/anyenv-update.git $(anyenv root)/plugins/anyenv-update

  echo 'eval "$(anyenv init -)"' >> ~/.bashrc
  exec bash -l
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
if ! command -v rancher-desktop &> /dev/null; then
  if [ "$(uname)" == 'Darwin' ]; then
    brew install --cask rancher
  elif [ "$(expr substr $(uname -s) 1 5)" == 'Linux' ]; then
    curl -fsSL https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/rancher-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/rancher-archive-keyring.gpg] https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ ./" | sudo tee /etc/apt/sources.list.d/rancher.list
    sudo apt-get update
    sudo apt-get install -y rancher-desktop
  fi
fi
