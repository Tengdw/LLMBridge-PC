package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"syscall"
	"time"

	"github.com/tengdw/llmbridge-pc/windows-agent/config"
	"github.com/tengdw/llmbridge-pc/windows-agent/executor"
	"github.com/tengdw/llmbridge-pc/windows-agent/logger"
	"github.com/tengdw/llmbridge-pc/windows-agent/server"
)

// findConfigFile searches for config file in multiple locations
func findConfigFile() string {
	configNames := []string{
		"llmbridge-agent.yaml",
		"llmbridge-agent.yml",
		"config.yaml",
		"config.yml",
	}

	// Get home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		homeDir = ""
	}

	// Search locations in order of priority
	searchPaths := []string{}

	// 1. Current directory
	for _, name := range configNames {
		searchPaths = append(searchPaths, name)
	}

	// 2. Home directory
	if homeDir != "" {
		for _, name := range configNames {
			searchPaths = append(searchPaths, filepath.Join(homeDir, ".llmbridge", name))
		}
	}

	// 3. System-specific locations
	if runtime.GOOS == "windows" {
		// Windows: C:\LLMBridge\
		for _, name := range configNames {
			searchPaths = append(searchPaths, filepath.Join("C:", "LLMBridge", name))
		}
	} else {
		// Linux/macOS: /etc/llmbridge/
		for _, name := range configNames {
			searchPaths = append(searchPaths, filepath.Join("/etc", "llmbridge", name))
		}
	}

	// Find first existing config file
	for _, path := range searchPaths {
		if _, err := os.Stat(path); err == nil {
			fmt.Printf("Using config file: %s\n", path)
			return path
		}
	}

	// Default fallback
	return "llmbridge-agent.yaml"
}

func main() {
	configPath := flag.String("config", "", "Path to configuration file")
	flag.Parse()

	// Determine config file path
	var cfgPath string
	if *configPath != "" {
		// Use specified config path
		cfgPath = *configPath
	} else {
		// Try multiple locations in order
		cfgPath = findConfigFile()
	}

	// Load configuration
	cfg, err := config.Load(cfgPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load config: %v\n", err)
		os.Exit(1)
	}

	// Initialize logger
	if err := logger.Init(
		cfg.Logging.Level,
		cfg.Logging.File,
		cfg.Logging.MaxSize,
		cfg.Logging.MaxBackups,
		cfg.Logging.MaxAge,
	); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to initialize logger: %v\n", err)
		os.Exit(1)
	}

	logger.Log.Info("Starting LLMBridge Windows Agent")

	// Create executor
	exec, err := executor.New(
		cfg.Executor.BlockedCommands,
		cfg.Executor.AllowedShells,
		cfg.Executor.DefaultTimeout,
		cfg.Executor.MaxTimeout,
	)
	if err != nil {
		logger.Log.Fatalf("Failed to create executor: %v", err)
	}

	// Create server
	srv := server.New(cfg, exec)

	// Start server in goroutine
	go func() {
		if err := srv.Start(); err != nil {
			logger.Log.Fatalf("Server error: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.Log.Info("Received shutdown signal")

	// Graceful shutdown with timeout
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		logger.Log.Errorf("Server shutdown error: %v", err)
	}

	logger.Log.Info("Server stopped")
}
