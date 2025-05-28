# Redis Service Information (Koneksi Staging)

## Connection Details
- **Primary Endpoint**: `koneksi-redis.6xcpqs.ng.0001.apse1.cache.amazonaws.com:6379`
- **Reader Endpoint**: `koneksi-redis-ro.6xcpqs.ng.0001.apse1.cache.amazonaws.com:6379`
- **Port**: 6379 (default Redis port)
- **Security Group ID**: `sg-0703b88277b2e9b56`

## Configuration
- **Redis Version**: 7.1.0
- **Instance Type**: cache.t3.micro
- **Memory**: 384MB max memory
- **Memory Policy**: allkeys-lru (Least Recently Used eviction policy)
- **Replication**: Enabled (Master-Slave setup)

## Connection Examples

### Node.js (using redis)
```javascript
const Redis = require('redis');

const client = Redis.createClient({
    host: 'koneksi-redis.6xcpqs.ng.0001.apse1.cache.amazonaws.com',
    port: 6379
});

// For read operations, use the reader endpoint
const readerClient = Redis.createClient({
    host: 'koneksi-redis-ro.6xcpqs.ng.0001.apse1.cache.amazonaws.com',
    port: 6379
});
```

### Python (using redis-py)
```python
import redis

# For write operations
redis_client = redis.Redis(
    host='koneksi-redis.6xcpqs.ng.0001.apse1.cache.amazonaws.com',
    port=6379
)

# For read operations
redis_reader = redis.Redis(
    host='koneksi-redis-ro.6xcpqs.ng.0001.apse1.cache.amazonaws.com',
    port=6379
)
```

### Go (using go-redis)
```go
import "github.com/go-redis/redis/v8"

// For write operations
client := redis.NewClient(&redis.Options{
    Addr: "koneksi-redis.6xcpqs.ng.0001.apse1.cache.amazonaws.com:6379",
})

// For read operations
reader := redis.NewClient(&redis.Options{
    Addr: "koneksi-redis-ro.6xcpqs.ng.0001.apse1.cache.amazonaws.com:6379",
})
```

## Important Notes
1. **Security**:
   - The Redis instance is only accessible from within the VPC
   - No authentication required (internal VPC access only)
   - Security group allows access from VPC CIDR (10.0.0.0/16)

2. **High Availability**:
   - Automatic failover enabled
   - Use reader endpoint for read operations to distribute load
   - Use primary endpoint for write operations

3. **Memory Management**:
   - Max memory: 384MB
   - Eviction policy: allkeys-lru
   - Monitor memory usage in your application

4. **Best Practices**:
   - Use connection pooling
   - Implement retry logic for connection failures
   - Use the reader endpoint for read operations
   - Monitor Redis metrics in your application

## Monitoring
- Monitor memory usage
- Watch for evicted keys
- Track connection counts
- Monitor replication lag

## Troubleshooting
1. **Connection Issues**:
   - Verify VPC access
   - Check security group rules
   - Ensure application is in the correct VPC

2. **Performance Issues**:
   - Check memory usage
   - Monitor evicted keys
   - Verify connection pooling
   - Check for large keys or slow commands

## Support
For any issues or questions, contact the DevOps team. 