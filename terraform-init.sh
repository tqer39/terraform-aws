#!/bin/bash
set -e
terraform init -chdir ./terraform/environments/$1
