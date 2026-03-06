.PHONY: start dev build prod setup clean help

# Default target
start: dev

# Start development server
dev:
	@./bin/jarvis

# Start without opening browser
dev-quiet:
	@./bin/jarvis --no-open

# Build for production
build:
	@./bin/jarvis --build

# Run production server
prod:
	@./bin/jarvis --prod

# Install dependencies
setup:
	@cd dashboard && npm install

# Clean build artifacts and caches
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf dashboard/.next
	@rm -f dashboard/.next/dev/lock
	@echo "Done."

# Show help
help:
	@./bin/jarvis --help
