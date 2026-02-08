package config

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

type Config struct {
	Server   ServerConfig   `yaml:"server"`
	Auth     AuthConfig     `yaml:"auth"`
	Executor ExecutorConfig `yaml:"executor"`
	Logging  LoggingConfig  `yaml:"logging"`
}

type ServerConfig struct {
	Port         int    `yaml:"port"`
	Host         string `yaml:"host"`
	ReadTimeout  int    `yaml:"read_timeout"`
	WriteTimeout int    `yaml:"write_timeout"`
}

type AuthConfig struct {
	Token string `yaml:"token"`
}

type ExecutorConfig struct {
	DefaultTimeout   int      `yaml:"default_timeout"`
	MaxTimeout       int      `yaml:"max_timeout"`
	AllowedShells    []string `yaml:"allowed_shells"`
	BlockedCommands  []string `yaml:"blocked_commands"`
}

type LoggingConfig struct {
	Level      string `yaml:"level"`
	File       string `yaml:"file"`
	MaxSize    int    `yaml:"max_size"`
	MaxBackups int    `yaml:"max_backups"`
	MaxAge     int    `yaml:"max_age"`
}

func Load(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	if err := cfg.Validate(); err != nil {
		return nil, fmt.Errorf("invalid config: %w", err)
	}

	return &cfg, nil
}

func (c *Config) Validate() error {
	if c.Server.Port < 1 || c.Server.Port > 65535 {
		return fmt.Errorf("invalid port: %d", c.Server.Port)
	}

	if c.Auth.Token == "" || c.Auth.Token == "your-secret-token-here-change-me" {
		return fmt.Errorf("auth token must be changed from default")
	}

	if c.Executor.DefaultTimeout < 1 {
		return fmt.Errorf("default_timeout must be positive")
	}

	if c.Executor.MaxTimeout < c.Executor.DefaultTimeout {
		return fmt.Errorf("max_timeout must be >= default_timeout")
	}

	if len(c.Executor.AllowedShells) == 0 {
		return fmt.Errorf("at least one shell must be allowed")
	}

	return nil
}
