package server

import (
	"net"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/shirou/gopsutil/v3/cpu"
	"github.com/shirou/gopsutil/v3/host"
	"github.com/shirou/gopsutil/v3/mem"
	"github.com/tengdw/llmbridge-pc/windows-agent/executor"
	"github.com/tengdw/llmbridge-pc/windows-agent/logger"
)

const Version = "1.0.0"

type Handler struct {
	executor *executor.Executor
}

func NewHandler(exec *executor.Executor) *Handler {
	return &Handler{
		executor: exec,
	}
}

// Health check endpoint
func (h *Handler) Health(c *gin.Context) {
	hostname, _ := os.Hostname()
	c.JSON(http.StatusOK, gin.H{
		"status":   "ok",
		"hostname": hostname,
		"version":  Version,
	})
}

// Execute command endpoint
func (h *Handler) Execute(c *gin.Context) {
	var req executor.ExecuteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request: " + err.Error(),
		})
		return
	}

	result := h.executor.Execute(req)

	statusCode := http.StatusOK
	if !result.Success {
		statusCode = http.StatusInternalServerError
	}

	c.JSON(statusCode, result)
}

// System info endpoint
func (h *Handler) Info(c *gin.Context) {
	hostname, _ := os.Hostname()

	// Get OS info
	hostInfo, _ := host.Info()
	osInfo := hostInfo.Platform + " " + hostInfo.PlatformVersion

	// Get CPU count
	cpuCount, _ := cpu.Counts(true)

	// Get memory info
	memInfo, _ := mem.VirtualMemory()
	memoryTotal := memInfo.Total / (1024 * 1024) // Convert to MB

	// Get IP addresses
	ipAddresses := getIPAddresses()

	// Get MAC address
	macAddress := getMACAddress()

	c.JSON(http.StatusOK, gin.H{
		"hostname":     hostname,
		"os":           osInfo,
		"cpu_count":    cpuCount,
		"memory_total": memoryTotal,
		"ip_addresses": ipAddresses,
		"mac_address":  macAddress,
	})
}

// Power operation endpoint
func (h *Handler) Power(c *gin.Context) {
	var req struct {
		Action string `json:"action" binding:"required"`
		Delay  int    `json:"delay"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid request: " + err.Error(),
		})
		return
	}

	var cmd *exec.Cmd
	var message string

	switch req.Action {
	case "shutdown":
		if runtime.GOOS == "windows" {
			// Use hybrid shutdown (Fast Startup) - Windows default behavior
			cmd = exec.Command("shutdown", "/s", "/hybrid", "/t", "0")
		} else {
			cmd = exec.Command("shutdown", "-h", "now")
		}
		message = "System will shutdown now (Fast Startup)"

	case "restart":
		if runtime.GOOS == "windows" {
			cmd = exec.Command("shutdown", "/r", "/t", "0")
		} else {
			cmd = exec.Command("shutdown", "-r", "now")
		}
		message = "System will restart now"

	case "sleep":
		if runtime.GOOS == "windows" {
			// Use rundll32 to trigger sleep
			cmd = exec.Command("rundll32.exe", "powrprof.dll,SetSuspendState", "0,1,0")
		} else {
			cmd = exec.Command("systemctl", "suspend")
		}
		message = "System will sleep now"

	default:
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Invalid action. Must be: shutdown, restart, or sleep",
		})
		return
	}

	logger.Log.Infof("Power action requested: %s", req.Action)

	// Send response before executing power command
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": message,
	})

	// Execute power command after a short delay to ensure response is sent
	go func() {
		time.Sleep(500 * time.Millisecond)
		if err := cmd.Run(); err != nil {
			logger.Log.Errorf("Power command failed: %v", err)
		}
	}()
}

// Helper functions
func getIPAddresses() []string {
	var ips []string

	interfaces, err := net.Interfaces()
	if err != nil {
		return ips
	}

	for _, iface := range interfaces {
		if iface.Flags&net.FlagUp == 0 || iface.Flags&net.FlagLoopback != 0 {
			continue
		}

		addrs, err := iface.Addrs()
		if err != nil {
			continue
		}

		for _, addr := range addrs {
			if ipnet, ok := addr.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
				if ipnet.IP.To4() != nil {
					ips = append(ips, ipnet.IP.String())
				}
			}
		}
	}

	return ips
}

func getMACAddress() string {
	interfaces, err := net.Interfaces()
	if err != nil {
		return ""
	}

	for _, iface := range interfaces {
		if iface.Flags&net.FlagUp != 0 && iface.Flags&net.FlagLoopback == 0 {
			mac := iface.HardwareAddr.String()
			if mac != "" {
				return mac
			}
		}
	}

	return ""
}
