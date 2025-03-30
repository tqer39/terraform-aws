#!/bin/bash

# Update anyenv plugins and environments
if command -v anyenv &> /dev/null; then
  if [ -d "$(anyenv root)/plugins/anyenv-update" ]; then
    $(anyenv root)/plugins/anyenv-update/bin/anyenv-update
  fi
fi

# Update tfenv
if command -v tfenv &> /dev/null; then
  tfenv update
fi

# Update Terraform CLI to the latest version
if command -v tfenv &> /dev/null; then
  latest_version=$(tfenv list-remote | head -n 1)
  tfenv install ${latest_version}
  tfenv use ${latest_version}
fi
