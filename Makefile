# Makefile

.PHONY: install

install:
	# Check if bash is installed, and install it if not
	if ! command -v bash &> /dev/null; then \
		@echo "Bash is not installed. Installing..."; \
		if [ "$(shell uname)" = "Darwin" ]; then \
			if ! command -v brew &> /dev/null; then \
				/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
			fi; \
		else \
			sudo apt-get update && sudo apt-get install -y bash; \
		fi; \
	fi
	bash setup-repository.sh
