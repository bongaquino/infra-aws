const AWS = require('aws-sdk');
const zlib = require('zlib');

const cloudwatchLogs = new AWS.CloudWatchLogs();
const s3 = new AWS.S3();

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        for (const record of event.Records) {
            const bucket = record.s3.bucket.name;
            const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
            
            console.log(`Processing log file: s3://${bucket}/${key}`);
            
            // Get the log file from S3
            const s3Object = await s3.getObject({
                Bucket: bucket,
                Key: key
            }).promise();
            
            // Decompress if gzipped
            let logData;
            if (s3Object.ContentEncoding === 'gzip') {
                logData = zlib.gunzipSync(s3Object.Body).toString('utf8');
            } else {
                logData = s3Object.Body.toString('utf8');
            }
            
            // Parse log lines
            const logLines = logData.split('\n').filter(line => line.trim());
            
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
                await cloudwatchLogs.createLogStream({
                    logGroupName: logGroupName,
                    logStreamName: logStreamName
                }).promise();
            } catch (error) {
                if (error.code !== 'ResourceAlreadyExistsException') {
                    throw error;
                }
            }
            
            // Prepare log events
            const logEvents = logLines.map((line, index) => ({
                timestamp: Date.now() + index, // Ensure unique timestamps
                message: line
            }));
            
            // Send logs to CloudWatch
            if (logEvents.length > 0) {
                await cloudwatchLogs.putLogEvents({
                    logGroupName: logGroupName,
                    logStreamName: logStreamName,
                    logEvents: logEvents
                }).promise();
                
                console.log(`Successfully sent ${logEvents.length} log events to ${logGroupName}/${logStreamName}`);
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