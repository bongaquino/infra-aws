# 🎯 Staging Environment Endpoints

## 🌍 **Public Staging Endpoints**

All staging endpoints are configured and working:

### **Frontend Application**
- **URL**: `https://app-staging.bongaquino.co.kr`
- **Type**: React Web Application
- **Status**: ✅ Live
- **Configuration**: Amplify + CloudFront

## Backend API

- **Service**: bongaquino Backend API
- **Environment**: Staging
- **URL**: `https://staging.bongaquino.co.kr`
- **Description**: Main backend API service for the bongaquino platform in staging environment
- **Expected Response**: JSON with health status
- **Monitoring**: HTTP status code and response time checking
- **Alert Conditions**: 
  - Non-200 HTTP responses
  - Response time > 5 seconds
  - Connection timeouts

### **MongoDB Admin**
- **Container**: `mongo-express`
- **Type**: MongoDB Administration Interface
- **Status**: ✅ Running
- **Access**: Internal container (not exposed externally)
- **Configuration**: Docker container on staging server

## 🏗️ **Server Configuration**

### **Staging Server**
- **IP**: `52.77.36.120`
- **Domain**: `staging.bongaquino.co.kr`
- **Location**: AWS/Cloud Infrastructure

### **Internal Services**
```bash
# Backend API (Go)
localhost:3000              # Main API server
localhost:3000/health       # Health check endpoint
localhost:3000/check-health  # Alternative health check

# Tyk Gateway
localhost:8080              # API Gateway
localhost:8080/hello        # Gateway health check

# Database Services
localhost:27017             # MongoDB
localhost:6379              # Redis

# No ELK services running
```

## 📊 **Health Check Endpoints**

### **External Health Check**
```bash
curl https://staging.bongaquino.co.kr
# Returns: {"data":{"healthy":true,"name":"bongaquino","version":"1.0.0"},"message":null,"meta":null,"status":"success"}
```

### **Internal Health Checks (Server-Side)**
```bash
# Backend API
curl localhost:3000/health          # HTTP 200 expected
curl localhost:3000/check-health    # Alternative endpoint
curl localhost:3000/                # Root endpoint

# Tyk Gateway
curl localhost:8080/hello           # HTTP 200 expected
```

## 🔧 **Route53 Configuration**

All staging domains are configured in Route53:

```hcl
# Route53 DNS Records
staging.bongaquino.co.kr        → 52.77.36.120
app-staging.bongaquino.co.kr    → CloudFront distribution
```

## 📝 **Nginx Configuration**

The staging server uses Nginx proxy for SSL termination and routing:

```nginx
# staging.bongaquino.co.kr.conf
server_name staging.bongaquino.co.kr;
ssl_certificate /etc/nginx-proxy/ssl/live/staging.bongaquino.co.kr/fullchain.pem;
ssl_certificate_key /etc/nginx-proxy/ssl/live/staging.bongaquino.co.kr/privkey.pem;
```

## 🔄 **Docker Services**

### **Core Services**
- `server` - Go backend API (port 3000)
- `gateway` - Tyk Gateway (port 8080)
- `mongo` - MongoDB database (port 27017)
- `redis` - Redis cache (port 6379)
- `nginx-proxy` - SSL termination and routing

### **Monitoring Services**
- No ELK stack services (removed from staging)

### **Admin Services**
- `mongo-express` - MongoDB admin interface
- `redis-commander` - Redis admin interface

## 📋 **Monitoring Integration**

All staging endpoints are monitored by:
- **Server-side monitoring**: 5-minute health checks
- **Discord notifications**: Real-time alerts via `🟡 bongaquino Staging Bot`
- **CloudWatch integration**: Metrics and logs
- **Daily health reports**: Comprehensive system status

## 🚀 **Testing Commands**

```bash
# Test all endpoints
curl https://app-staging.bongaquino.co.kr
curl https://staging.bongaquino.co.kr

# Internal health checks (on staging server)
curl localhost:3000/health
curl localhost:8080/hello
```

**Last Updated**: 2025-07-13  
**Environment**: Staging  
**Status**: ✅ All endpoints operational 