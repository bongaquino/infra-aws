// Use AWS SDK v3 which is available in Node.js 18.x runtime
const { CloudWatchLogsClient, CreateLogStreamCommand, PutLogEventsCommand } = require('@aws-sdk/client-cloudwatch-logs');
const { S3Client, GetObjectCommand } = require('@aws-sdk/client-s3');
const zlib = require('zlib');

// Initialize AWS SDK v3 clients
const cloudwatchLogs = new CloudWatchLogsClient({ region: process.env.AWS_REGION || 'ap-southeast-1' });
const s3 = new S3Client({ region: process.env.AWS_REGION || 'ap-southeast-1' });

// Function to parse ALB log line into readable format
function parseALBLogLine(line) {
    // Skip lines that don't look like ALB logs
    if (line.startsWith('Enable AccessLog') || line.trim() === '') {
        return line;
    }
    
    const fields = line.split(' ');
    if (fields.length < 12) return line; // Return original if can't parse
    
    try {
        // ALB log format: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
        const [
            type,                    // 0: type (http/https)
            timestamp,               // 1: timestamp
            elb,                     // 2: elb name
            client_ip_port,          // 3: client:port
            target_ip_port,          // 4: target:port
            request_processing_time, // 5: request processing time
            target_processing_time,  // 6: target processing time
            response_processing_time,// 7: response processing time
            elb_status_code,         // 8: elb status code
            target_status_code,      // 9: target status code
            received_bytes,          // 10: received bytes
            sent_bytes,              // 11: sent bytes
            request,                 // 12: request
            user_agent,              // 13: user agent
            ssl_cipher,              // 14: ssl cipher
            ssl_protocol,            // 15: ssl protocol
            target_group_arn,        // 16: target group arn
            trace_id,                // 17: trace id
            domain_name,             // 18: domain name
            chosen_cert_arn,         // 19: chosen cert arn
            matched_rule_priority,   // 20: matched rule priority
            request_creation_time,   // 21: request creation time
            actions_executed,        // 22: actions executed
            redirect_url,            // 23: redirect url
            lambda_error_reason,     // 24: lambda error reason
            target_port_list,        // 25: target port list
            target_status_code_list, // 26: target status code list
            classification,          // 27: classification
            classification_reason    // 28: classification reason
        ] = fields;
        
        // Parse client and target IP/port
        const [client_ip, client_port] = client_ip_port ? client_ip_port.split(':') : ['-', '-'];
        const [target_ip, target_port] = target_ip_port ? target_ip_port.split(':') : ['-', '-'];
        
        // Parse request to get method, URL, and protocol
        let method = '-', url = '-', protocol = '-';
        if (request && request !== '-') {
            const requestParts = request.split(' ');
            if (requestParts.length >= 3) {
                method = requestParts[0];
                url = requestParts[1];
                protocol = requestParts[2];
            }
        }
        
        return JSON.stringify({
            timestamp: new Date(timestamp).toISOString(),
            type,
            elb,
            client: {
                ip: client_ip,
                port: client_port
            },
            target: {
                ip: target_ip,
                port: target_port
            },
            processing_times: {
                request: parseFloat(request_processing_time),
                target: parseFloat(target_processing_time),
                response: parseFloat(response_processing_time)
            },
            status_codes: {
                elb: parseInt(elb_status_code),
                target: parseInt(target_status_code)
            },
            bytes: {
                received: parseInt(received_bytes),
                sent: parseInt(sent_bytes)
            },
            request: {
                method,
                url,
                protocol
            },
            user_agent: user_agent !== '-' ? user_agent : null,
            ssl: {
                cipher: ssl_cipher !== '-' ? ssl_cipher : null,
                protocol: ssl_protocol !== '-' ? ssl_protocol : null
            },
            target_group_arn,
            trace_id,
            domain_name: domain_name !== '-' ? domain_name : null,
            chosen_cert_arn: chosen_cert_arn !== '-' ? chosen_cert_arn : null
        }, null, 2);
    } catch (error) {
        console.error('Error parsing log line:', error, 'Line:', line);
        return line; // Return original if parsing fails
    }
}

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        for (const record of event.Records) {
            const bucket = record.s3.bucket.name;
            const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
            
            console.log(`Processing log file: s3://${bucket}/${key}`);
            
            // Get the log file from S3
            const s3Object = await s3.send(new GetObjectCommand({
                Bucket: bucket,
                Key: key
            }));
            
            // Get the raw data as a buffer
            const rawData = await s3Object.Body.transformToByteArray();
            
            // Decompress if gzipped (check for gzip magic number)
            let logData;
            if (rawData[0] === 0x1f && rawData[1] === 0x8b) {
                console.log('Detected gzipped data, decompressing...');
                logData = zlib.gunzipSync(Buffer.from(rawData)).toString('utf8');
            } else {
                console.log('No compression detected, using raw data');
                logData = Buffer.from(rawData).toString('utf8');
            }
            
            console.log('Log data sample:', logData.substring(0, 200));
            
            // Parse log lines and format them
            const logLines = logData.split('\n').filter(line => line.trim());
            const formattedLogLines = logLines.map(line => parseALBLogLine(line));
            
            // Determine which log group to use based on the S3 key prefix
            let logGroupName = '';
            if (key.includes('main-alb')) {
                if (key.includes('connections')) {
                    logGroupName = process.env.MAIN_ALB_CONNECTION_LOG_GROUP;
                } else {
                    logGroupName = process.env.MAIN_ALB_ACCESS_LOG_GROUP;
                }
            } else if (key.includes('services-alb')) {
                if (key.includes('connections')) {
                    logGroupName = process.env.SERVICES_ALB_CONNECTION_LOG_GROUP;
                } else {
                    logGroupName = process.env.SERVICES_ALB_ACCESS_LOG_GROUP;
                }
            }
            
            if (!logGroupName) {
                console.log(`No matching log group found for key: ${key}`);
                continue;
            }
            
            // Create log stream name based on timestamp
            const timestamp = new Date().toISOString().split('T')[0];
            const logStreamName = `${timestamp}-${Date.now()}`;
            
            // Create log stream
            try {
                await cloudwatchLogs.send(new CreateLogStreamCommand({
                    logGroupName: logGroupName,
                    logStreamName: logStreamName
                }));
            } catch (error) {
                if (error.name !== 'ResourceAlreadyExistsException') {
                    throw error;
                }
            }
            
            // Prepare log events with formatted messages
            const logEvents = formattedLogLines.map((line, index) => ({
                timestamp: Date.now() + index, // Ensure unique timestamps
                message: line
            }));
            
            // Send logs to CloudWatch
            if (logEvents.length > 0) {
                await cloudwatchLogs.send(new PutLogEventsCommand({
                    logGroupName: logGroupName,
                    logStreamName: logStreamName,
                    logEvents: logEvents
                }));
                
                console.log(`Successfully sent ${logEvents.length} formatted log events to ${logGroupName}/${logStreamName}`);
                console.log('Sample formatted log:', formattedLogLines[0]);
            }
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify({ message: 'Logs processed successfully' })
        };
        
    } catch (error) {
        console.error('Error processing logs:', error);
        throw error;
    }
}; 