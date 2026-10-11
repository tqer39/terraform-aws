#!/bin/bash

# Install versions updated in mise.toml without changing the pinned configuration.
exec mise -C "$(dirname "$0")" install
