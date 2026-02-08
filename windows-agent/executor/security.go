package executor

import (
	"fmt"
	"regexp"
	"strings"
)

type SecurityValidator struct {
	blockedPatterns []*regexp.Regexp
	allowedShells   map[string]bool
}

func NewSecurityValidator(blockedCommands, allowedShells []string) (*SecurityValidator, error) {
	patterns := make([]*regexp.Regexp, 0, len(blockedCommands))
	for _, pattern := range blockedCommands {
		re, err := regexp.Compile("(?i)" + pattern)
		if err != nil {
			return nil, fmt.Errorf("invalid blocked command pattern %q: %w", pattern, err)
		}
		patterns = append(patterns, re)
	}

	shellMap := make(map[string]bool)
	for _, shell := range allowedShells {
		shellMap[strings.ToLower(shell)] = true
	}

	return &SecurityValidator{
		blockedPatterns: patterns,
		allowedShells:   shellMap,
	}, nil
}

func (sv *SecurityValidator) ValidateCommand(command string) error {
	if command == "" {
		return fmt.Errorf("command cannot be empty")
	}

	// Check against blocked patterns
	for _, pattern := range sv.blockedPatterns {
		if pattern.MatchString(command) {
			return fmt.Errorf("command blocked by security policy: matches pattern %q", pattern.String())
		}
	}

	return nil
}

func (sv *SecurityValidator) ValidateShell(shell string) error {
	shell = strings.ToLower(shell)
	if !sv.allowedShells[shell] {
		return fmt.Errorf("shell %q is not allowed", shell)
	}
	return nil
}
