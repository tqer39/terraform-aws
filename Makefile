# Makefile

.PHONY: install

install:
	# Check if bash is installed, and install it if not
	if ! command -v bash &> /dev/null; then
		@echo "Bash is not installed. Installing..."
		@sudo apt-get update && sudo apt-get install -y bash
	fi
	bash setup-repository.sh
