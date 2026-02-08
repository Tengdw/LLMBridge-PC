package server

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/tengdw/llmbridge-pc/windows-agent/config"
	"github.com/tengdw/llmbridge-pc/windows-agent/executor"
	"github.com/tengdw/llmbridge-pc/windows-agent/logger"
)

type Server struct {
	httpServer *http.Server
	handler    *Handler
}

func New(cfg *config.Config, exec *executor.Executor) *Server {
	// Set Gin mode
	gin.SetMode(gin.ReleaseMode)

	router := gin.New()
	router.Use(gin.Recovery())
	router.Use(LoggingMiddleware())

	handler := NewHandler(exec)

	// Public endpoints
	router.GET("/health", handler.Health)

	// Protected endpoints
	api := router.Group("/api/v1")
	api.Use(AuthMiddleware(cfg.Auth.Token))
	{
		api.POST("/execute", handler.Execute)
		api.GET("/info", handler.Info)
		api.POST("/power", handler.Power)
	}

	addr := fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port)

	httpServer := &http.Server{
		Addr:         addr,
		Handler:      router,
		ReadTimeout:  time.Duration(cfg.Server.ReadTimeout) * time.Second,
		WriteTimeout: time.Duration(cfg.Server.WriteTimeout) * time.Second,
	}

	return &Server{
		httpServer: httpServer,
		handler:    handler,
	}
}

func (s *Server) Start() error {
	logger.Log.Infof("Starting server on %s", s.httpServer.Addr)

	if err := s.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		return fmt.Errorf("server failed: %w", err)
	}

	return nil
}

func (s *Server) Shutdown(ctx context.Context) error {
	logger.Log.Info("Shutting down server...")
	return s.httpServer.Shutdown(ctx)
}
