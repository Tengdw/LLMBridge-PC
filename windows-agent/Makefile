.PHONY: build-windows build-linux clean test

build-windows:
	@echo "Building for Windows..."
	GOOS=windows GOARCH=amd64 go build -o bin/windows-agent.exe main.go
	@echo "Windows build complete: bin/windows-agent.exe"

build-linux:
	@echo "Building for Linux..."
	GOOS=linux GOARCH=amd64 go build -o bin/windows-agent-linux main.go
	@echo "Linux build complete: bin/windows-agent-linux"

build-darwin:
	@echo "Building for macOS..."
	GOOS=darwin GOARCH=amd64 go build -o bin/windows-agent-darwin main.go
	@echo "macOS build complete: bin/windows-agent-darwin"

build-all: build-windows build-linux build-darwin

clean:
	@echo "Cleaning build artifacts..."
	rm -rf bin/
	@echo "Clean complete"

test:
	@echo "Running tests..."
	go test -v ./...

deps:
	@echo "Downloading dependencies..."
	go mod tidy
	go mod download
	@echo "Dependencies downloaded"

run:
	@echo "Running agent..."
	go run main.go
