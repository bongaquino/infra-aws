package monitoring

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch"
	"github.com/aws/aws-sdk-go-v2/service/cloudwatch/types"
	"github.com/aws/aws-sdk-go-v2/service/sns"
)

// DiscordMonitoring handles sending metrics and alerts to CloudWatch and Discord
type DiscordMonitoring struct {
	cloudwatchClient *cloudwatch.Client
	snsClient        *sns.Client
	environment      string
	service          string
	snsTopicArn      string
}

// MetricData represents a custom metric to send to CloudWatch
type MetricData struct {
	MetricName string
	Value      float64
	Unit       types.StandardUnit
	Dimensions map[string]string
	Namespace  string
}

// DiscordAlert represents an alert to send to Discord
type DiscordAlert struct {
	Title       string                 `json:"title"`
	Description string                 `json:"description"`
	Type        string                 `json:"type"` // error, warning, info, success
	Details     map[string]interface{} `json:"details"`
}

// NewDiscordMonitoring creates a new monitoring instance
func NewDiscordMonitoring(environment, service string) (*DiscordMonitoring, error) {
	cfg, err := config.LoadDefaultConfig(context.TODO())
	if err != nil {
		return nil, fmt.Errorf("failed to load AWS config: %w", err)
	}

	snsTopicArn := os.Getenv("DISCORD_SNS_TOPIC_ARN")
	if snsTopicArn == "" {
		snsTopicArn = fmt.Sprintf("arn:aws:sns:ap-southeast-1:985869370256:bongaquino-%s-%s-discord-notifications", environment, environment)
	}

	return &DiscordMonitoring{
		cloudwatchClient: cloudwatch.NewFromConfig(cfg),
		snsClient:        sns.NewFromConfig(cfg),
		environment:      environment,
		service:          service,
		snsTopicArn:      snsTopicArn,
	}, nil
}

// SendMetric sends a custom metric to CloudWatch
func (dm *DiscordMonitoring) SendMetric(ctx context.Context, metric MetricData) error {
	dimensions := make([]types.Dimension, 0, len(metric.Dimensions)+2)

	// Add default dimensions
	dimensions = append(dimensions,
		types.Dimension{
			Name:  aws.String("Environment"),
			Value: aws.String(dm.environment),
		},
		types.Dimension{
			Name:  aws.String("Service"),
			Value: aws.String(dm.service),
		},
	)

	// Add custom dimensions
	for key, value := range metric.Dimensions {
		dimensions = append(dimensions, types.Dimension{
			Name:  aws.String(key),
			Value: aws.String(value),
		})
	}

	namespace := metric.Namespace
	if namespace == "" {
		namespace = "bongaquino/Application"
	}

	input := &cloudwatch.PutMetricDataInput{
		Namespace: aws.String(namespace),
		MetricData: []types.MetricDatum{
			{
				MetricName: aws.String(metric.MetricName),
				Value:      aws.Float64(metric.Value),
				Unit:       metric.Unit,
				Timestamp:  aws.Time(time.Now()),
				Dimensions: dimensions,
			},
		},
	}

	_, err := dm.cloudwatchClient.PutMetricData(ctx, input)
	if err != nil {
		return fmt.Errorf("failed to send metric to CloudWatch: %w", err)
	}

	log.Printf("Sent metric %s: %f to CloudWatch", metric.MetricName, metric.Value)
	return nil
}

// SendDiscordAlert sends an alert directly to Discord via SNS
func (dm *DiscordMonitoring) SendDiscordAlert(ctx context.Context, alert DiscordAlert) error {
	messageBytes, err := json.Marshal(alert)
	if err != nil {
		return fmt.Errorf("failed to marshal alert: %w", err)
	}

	input := &sns.PublishInput{
		TopicArn: aws.String(dm.snsTopicArn),
		Message:  aws.String(string(messageBytes)),
		Subject:  aws.String(alert.Title),
	}

	_, err = dm.snsClient.Publish(ctx, input)
	if err != nil {
		return fmt.Errorf("failed to send alert to Discord: %w", err)
	}

	log.Printf("Sent Discord alert: %s", alert.Title)
	return nil
}

// Helper methods for common metrics

// RecordAPIResponseTime records API response time
func (dm *DiscordMonitoring) RecordAPIResponseTime(ctx context.Context, endpoint string, responseTimeMs float64) error {
	return dm.SendMetric(ctx, MetricData{
		MetricName: "ApiResponseTime",
		Value:      responseTimeMs,
		Unit:       types.StandardUnitMilliseconds,
		Dimensions: map[string]string{
			"Endpoint": endpoint,
		},
	})
}

// RecordFileUploadSuccess records file upload success/failure
func (dm *DiscordMonitoring) RecordFileUploadSuccess(ctx context.Context, success bool, fileSize int64) error {
	successRate := 0.0
	if success {
		successRate = 100.0
	}

	// Record success rate
	err := dm.SendMetric(ctx, MetricData{
		MetricName: "FileUploadSuccessRate",
		Value:      successRate,
		Unit:       types.StandardUnitPercent,
	})
	if err != nil {
		return err
	}

	// Record file size
	return dm.SendMetric(ctx, MetricData{
		MetricName: "FileUploadSize",
		Value:      float64(fileSize),
		Unit:       types.StandardUnitBytes,
	})
}

// RecordActiveUsers records current active users
func (dm *DiscordMonitoring) RecordActiveUsers(ctx context.Context, count int) error {
	return dm.SendMetric(ctx, MetricData{
		MetricName: "ActiveUsers",
		Value:      float64(count),
		Unit:       types.StandardUnitCount,
	})
}

// RecordDatabaseConnectionPool records database connection pool utilization
func (dm *DiscordMonitoring) RecordDatabaseConnectionPool(ctx context.Context, utilization float64) error {
	return dm.SendMetric(ctx, MetricData{
		MetricName: "DatabaseConnectionPoolUtilization",
		Value:      utilization,
		Unit:       types.StandardUnitPercent,
	})
}

// RecordMemoryUsage records application memory usage
func (dm *DiscordMonitoring) RecordMemoryUsage(ctx context.Context, usagePercent float64) error {
	return dm.SendMetric(ctx, MetricData{
		MetricName: "MemoryUtilization",
		Value:      usagePercent,
		Unit:       types.StandardUnitPercent,
	})
}

// SendCriticalAlert sends a critical alert to Discord
func (dm *DiscordMonitoring) SendCriticalAlert(ctx context.Context, title, description string, details map[string]interface{}) error {
	return dm.SendDiscordAlert(ctx, DiscordAlert{
		Title:       "🚨 CRITICAL: " + title,
		Description: description,
		Type:        "error",
		Details:     details,
	})
}

// SendWarningAlert sends a warning alert to Discord
func (dm *DiscordMonitoring) SendWarningAlert(ctx context.Context, title, description string, details map[string]interface{}) error {
	return dm.SendDiscordAlert(ctx, DiscordAlert{
		Title:       "⚠️ WARNING: " + title,
		Description: description,
		Type:        "warning",
		Details:     details,
	})
}

// SendInfoAlert sends an informational alert to Discord
func (dm *DiscordMonitoring) SendInfoAlert(ctx context.Context, title, description string, details map[string]interface{}) error {
	return dm.SendDiscordAlert(ctx, DiscordAlert{
		Title:       "ℹ️ INFO: " + title,
		Description: description,
		Type:        "info",
		Details:     details,
	})
}

// =============================================================================
// SERVER MONITORING FUNCTIONS - For Staging Server 52.77.36.120
// =============================================================================

// RecordServerCPUUsage records server CPU usage
func (dm *DiscordMonitoring) RecordServerCPUUsage(ctx context.Context, cpuPercent float64) error {
	if cpuPercent > 80 {
		dm.SendWarningAlert(ctx, "High CPU Usage",
			fmt.Sprintf("Server CPU usage is at %.1f%%", cpuPercent),
			map[string]interface{}{
				"CPU Usage": fmt.Sprintf("%.1f%%", cpuPercent),
				"Threshold": "80%",
				"Server":    "52.77.36.120",
			})
	}

	return dm.SendMetric(ctx, MetricData{
		MetricName: "ServerCPUUsage",
		Value:      cpuPercent,
		Unit:       types.StandardUnitPercent,
		Namespace:  "bongaquino/Server",
	})
}

// RecordServerMemoryUsage records server memory usage
func (dm *DiscordMonitoring) RecordServerMemoryUsage(ctx context.Context, memoryPercent float64, usedGB, totalGB float64) error {
	if memoryPercent > 85 {
		dm.SendCriticalAlert(ctx, "High Memory Usage",
			fmt.Sprintf("Server memory usage is critically high at %.1f%%", memoryPercent),
			map[string]interface{}{
				"Memory Usage": fmt.Sprintf("%.1f%% (%.1fGB/%.1fGB)", memoryPercent, usedGB, totalGB),
				"Threshold":    "85%",
				"Server":       "52.77.36.120",
			})
	}

	return dm.SendMetric(ctx, MetricData{
		MetricName: "ServerMemoryUsage",
		Value:      memoryPercent,
		Unit:       types.StandardUnitPercent,
		Namespace:  "bongaquino/Server",
	})
}

// RecordServerDiskUsage records server disk usage
func (dm *DiscordMonitoring) RecordServerDiskUsage(ctx context.Context, diskPercent float64, availableGB string) error {
	if diskPercent > 90 {
		dm.SendCriticalAlert(ctx, "Critical Disk Space",
			fmt.Sprintf("Server disk usage is critically high at %.1f%%", diskPercent),
			map[string]interface{}{
				"Disk Usage": fmt.Sprintf("%.1f%%", diskPercent),
				"Available":  availableGB,
				"Threshold":  "90%",
				"Server":     "52.77.36.120",
			})
	}

	return dm.SendMetric(ctx, MetricData{
		MetricName: "ServerDiskUsage",
		Value:      diskPercent,
		Unit:       types.StandardUnitPercent,
		Namespace:  "bongaquino/Server",
	})
}

// RecordDockerContainerHealth records Docker container health status
func (dm *DiscordMonitoring) RecordDockerContainerHealth(ctx context.Context, containerName string, isHealthy bool, uptime string) error {
	status := 1.0 // healthy
	if !isHealthy {
		status = 0.0 // unhealthy
		dm.SendCriticalAlert(ctx, "Container Health Alert",
			fmt.Sprintf("Docker container '%s' is unhealthy", containerName),
			map[string]interface{}{
				"Container": containerName,
				"Status":    "Unhealthy",
				"Uptime":    uptime,
				"Server":    "52.77.36.120",
			})
	}

	return dm.SendMetric(ctx, MetricData{
		MetricName: "DockerContainerHealth",
		Value:      status,
		Unit:       types.StandardUnitCount,
		Dimensions: map[string]string{
			"ContainerName": containerName,
		},
		Namespace: "bongaquino/Docker",
	})
}

// CheckBackendAPIHealth checks the backend API health and sends alerts if needed
func (dm *DiscordMonitoring) CheckBackendAPIHealth(ctx context.Context) error {
	start := time.Now()

	// This would be implemented in your actual monitoring script
	// For now, this is a template for the pattern

	responseTime := time.Since(start).Milliseconds()

	// Record the response time
	err := dm.RecordAPIResponseTime(ctx, "/", float64(responseTime))
	if err != nil {
		return err
	}

	// If API is down, send critical alert
	if responseTime > 10000 { // 10 seconds timeout
		return dm.SendCriticalAlert(ctx, "Backend API Down",
			"bongaquino backend API is not responding",
			map[string]interface{}{
				"Endpoint":      "localhost:3000/",
				"Response Time": fmt.Sprintf("%dms", responseTime),
				"Server":        "52.77.36.120",
				"Status":        "Failed",
			})
	}

	return nil
}

// SendServerHealthSummary sends a comprehensive server health summary
func (dm *DiscordMonitoring) SendServerHealthSummary(ctx context.Context, stats map[string]interface{}) error {
	return dm.SendInfoAlert(ctx, "Server Health Summary",
		"Daily health report for staging server",
		map[string]interface{}{
			"Server":      "bongaquino-staging-backend (52.77.36.120)",
			"Report Time": time.Now().Format("2006-01-02 15:04:05 UTC"),
			"Stats":       stats,
		})
}

// =============================================================================
// EXAMPLE INTEGRATION FOR STAGING SERVER MONITORING
// =============================================================================

/*
Example: Add to your Go backend main.go or create a separate monitoring service:

package main

import (
	"context"
	"log"
	"os/exec"
	"strconv"
	"strings"
	"time"
	"your-project/monitoring"
)

func main() {
	// Initialize monitoring for staging environment
	monitor, err := monitoring.NewDiscordMonitoring("staging", "bongaquino-backend")
	if err != nil {
		log.Fatal("Failed to initialize monitoring:", err)
	}

	ctx := context.Background()

	// Run monitoring checks every 5 minutes
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			runSystemHealthChecks(monitor, ctx)
		}
	}
}

func runSystemHealthChecks(monitor *monitoring.DiscordMonitoring, ctx context.Context) {
	// Check CPU usage
	if cpuUsage := getCPUUsage(); cpuUsage > 0 {
		monitor.RecordServerCPUUsage(ctx, cpuUsage)
	}

	// Check memory usage
	if memUsage, usedGB, totalGB := getMemoryUsage(); memUsage > 0 {
		monitor.RecordServerMemoryUsage(ctx, memUsage, usedGB, totalGB)
	}

	// Check disk usage
	if diskUsage, available := getDiskUsage(); diskUsage > 0 {
		monitor.RecordServerDiskUsage(ctx, diskUsage, available)
	}

	// Check Docker containers
	containers := []string{"server", "gateway", "mongo", "redis", "nginx-proxy"}
	for _, container := range containers {
		if isHealthy, uptime := checkDockerContainer(container); uptime != "" {
			monitor.RecordDockerContainerHealth(ctx, container, isHealthy, uptime)
		}
	}

	// Check backend API
	monitor.CheckBackendAPIHealth(ctx)
}

func getCPUUsage() float64 {
	cmd := exec.Command("bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | sed 's/%us,//'")
	output, _ := cmd.Output()
	if val, err := strconv.ParseFloat(strings.TrimSpace(string(output)), 64); err == nil {
		return val
	}
	return 0
}

func getMemoryUsage() (float64, float64, float64) {
	cmd := exec.Command("free")
	output, _ := cmd.Output()
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "Mem:") {
			fields := strings.Fields(line)
			if len(fields) >= 3 {
				total, _ := strconv.ParseFloat(fields[1], 64)
				used, _ := strconv.ParseFloat(fields[2], 64)
				if total > 0 {
					return (used / total) * 100, used / 1024 / 1024, total / 1024 / 1024
				}
			}
		}
	}
	return 0, 0, 0
}

func getDiskUsage() (float64, string) {
	cmd := exec.Command("df", "/")
	output, _ := cmd.Output()
	lines := strings.Split(string(output), "\n")
	if len(lines) > 1 {
		fields := strings.Fields(lines[1])
		if len(fields) >= 5 {
			usage := strings.TrimSuffix(fields[4], "%")
			if val, err := strconv.ParseFloat(usage, 64); err == nil {
				return val, fields[3]
			}
		}
	}
	return 0, ""
}

func checkDockerContainer(name string) (bool, string) {
	cmd := exec.Command("docker", "ps", "--format", "table {{.Names}}\t{{.Status}}", "--filter", "name="+name)
	output, _ := cmd.Output()
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if strings.Contains(line, name) && strings.Contains(line, "Up") {
			return true, strings.TrimSpace(line)
		}
	}
	return false, ""
}
*/
