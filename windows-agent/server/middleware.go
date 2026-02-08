package server

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/tengdw/llmbridge-pc/windows-agent/logger"
)

func AuthMiddleware(token string) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("X-Auth-Token")

		if authHeader == "" {
			logger.Log.Warn("Missing authentication token")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Missing authentication token",
			})
			c.Abort()
			return
		}

		if strings.TrimSpace(authHeader) != strings.TrimSpace(token) {
			logger.Log.Warn("Invalid authentication token")
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Invalid authentication token",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

func LoggingMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		logger.Log.Infof("%s %s from %s", c.Request.Method, c.Request.URL.Path, c.ClientIP())
		c.Next()
	}
}
