package executor

import (
	"bytes"
	"context"
	"os/exec"
	"runtime"
	"time"

	"github.com/tengdw/llmbridge-pc/windows-agent/logger"
)

type Executor struct {
	validator      *SecurityValidator
	defaultTimeout int
	maxTimeout     int
}

type ExecuteRequest struct {
	Command string `json:"command" binding:"required"`
	Timeout int    `json:"timeout"`
	Shell   string `json:"shell"`
}

type ExecuteResponse struct {
	Success       bool    `json:"success"`
	Stdout        string  `json:"stdout"`
	Stderr        string  `json:"stderr"`
	ExitCode      int     `json:"exit_code"`
	ExecutionTime float64 `json:"execution_time"`
	Error         string  `json:"error,omitempty"`
}

func New(blockedCommands, allowedShells []string, defaultTimeout, maxTimeout int) (*Executor, error) {
	validator, err := NewSecurityValidator(blockedCommands, allowedShells)
	if err != nil {
		return nil, err
	}

	return &Executor{
		validator:      validator,
		defaultTimeout: defaultTimeout,
		maxTimeout:     maxTimeout,
	}, nil
}

func (e *Executor) Execute(req ExecuteRequest) ExecuteResponse {
	startTime := time.Now()

	// Validate command
	if err := e.validator.ValidateCommand(req.Command); err != nil {
		logger.Log.Warnf("Command validation failed: %v", err)
		return ExecuteResponse{
			Success:       false,
			Error:         err.Error(),
			ExecutionTime: time.Since(startTime).Seconds(),
		}
	}

	// Set default shell if not specified
	if req.Shell == "" {
		if runtime.GOOS == "windows" {
			req.Shell = "cmd"
		} else {
			req.Shell = "bash"
		}
	}

	// Validate shell
	if err := e.validator.ValidateShell(req.Shell); err != nil {
		logger.Log.Warnf("Shell validation failed: %v", err)
		return ExecuteResponse{
			Success:       false,
			Error:         err.Error(),
			ExecutionTime: time.Since(startTime).Seconds(),
		}
	}

	// Set timeout
	timeout := req.Timeout
	if timeout == 0 {
		timeout = e.defaultTimeout
	}
	if timeout > e.maxTimeout {
		timeout = e.maxTimeout
	}

	// Execute command
	ctx, cancel := context.WithTimeout(context.Background(), time.Duration(timeout)*time.Second)
	defer cancel()

	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		if req.Shell == "powershell" {
			cmd = exec.CommandContext(ctx, "powershell", "-Command", req.Command)
		} else {
			cmd = exec.CommandContext(ctx, "cmd", "/C", req.Command)
		}
	} else {
		cmd = exec.CommandContext(ctx, "bash", "-c", req.Command)
	}

	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	logger.Log.Infof("Executing command: %s (shell: %s, timeout: %ds)", req.Command, req.Shell, timeout)

	err := cmd.Run()
	executionTime := time.Since(startTime).Seconds()

	exitCode := 0
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			exitCode = exitErr.ExitCode()
		} else {
			exitCode = -1
		}
	}

	success := err == nil
	errorMsg := ""
	if err != nil {
		errorMsg = err.Error()
		logger.Log.Warnf("Command execution failed: %v", err)
	} else {
		logger.Log.Infof("Command executed successfully in %.2fs", executionTime)
	}

	return ExecuteResponse{
		Success:       success,
		Stdout:        stdout.String(),
		Stderr:        stderr.String(),
		ExitCode:      exitCode,
		ExecutionTime: executionTime,
		Error:         errorMsg,
	}
}
