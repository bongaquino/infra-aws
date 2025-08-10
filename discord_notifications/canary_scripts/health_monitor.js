const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

const apiCanaryBlueprint = async function () {
    
    const syntheticConfiguration = synthetics.getConfiguration();
    const endpoint = "${health_endpoint}";
    
    // Set synthetics configuration
    syntheticConfiguration.setConfig({
        restrictedHeaders: [], // Allow all headers
        restrictedUrlParameters: [] // Allow all URL parameters
    });

    let requestOptionsStep1 = {
        hostname: 'server-uat.bongaquino.co.kr',
        method: 'GET',
        path: '/check-health',
        port: 443,
        protocol: 'https:',
        body: "",
        headers: {
            'User-Agent': 'CloudWatch-Synthetics/1.0 (bongaquino-UAT-HealthMonitor)',
            'Accept': 'application/json',
            'Cache-Control': 'no-cache'
        }
    };
    
    requestOptionsStep1['timeout'] = 30000;

    // Log the health check request
    log.info('Starting health check for UAT environment...');
    log.info(`Endpoint: $${endpoint}`);

    let stepConfig = {
        includeRequestHeaders: true,
        includeResponseHeaders: true,
        includeRequestBody: true,
        includeResponseBody: true,
        restrictedHeaders: [],
        restrictedUrlParameters: []
    };

    const stepFunction = async function () {
        return await synthetics.executeHttpStep('healthCheck', requestOptionsStep1, function (res) {
            return new Promise((resolve, reject) => {
                log.info(`Response status code: $${res.statusCode}`);
                
                if (res.statusCode < 200 || res.statusCode > 299) {
                    throw new Error(`Failed: status code $${res.statusCode}`);
                }

                let responseBody = '';
                res.on('data', (d) => {
                    responseBody += d;
                });
                
                res.on('end', () => {
                    try {
                        log.info(`Response body: $${responseBody}`);
                        
                        // Parse the JSON response
                        const healthData = JSON.parse(responseBody);
                        
                        // Validate the expected structure
                        if (!healthData.data) {
                            throw new Error('Missing data property in health response');
                        }
                        
                        if (!healthData.data.hasOwnProperty('healthy')) {
                            throw new Error('Missing healthy property in health response');
                        }
                        
                        if (healthData.data.healthy !== true) {
                            throw new Error(`Health check failed: healthy=$${healthData.data.healthy}`);
                        }
                        
                        if (healthData.status !== 'success') {
                            throw new Error(`Health check failed: status=$${healthData.status}`);
                        }
                        
                        // Validate service name
                        if (healthData.data.name !== 'bongaquino') {
                            log.warn(`Unexpected service name: $${healthData.data.name}`);
                        }
                        
                        // Log success details
                        log.info(`Health check PASSED - Service: $${healthData.data.name}, Version: $${healthData.data.version}`);
                        
                        resolve();
                        
                    } catch (error) {
                        log.error(`Health check validation failed: $${error.message}`);
                        log.error(`Response body: $${responseBody}`);
                        reject(error);
                    }
                });
            });
        });
    };

    return await synthetics.executeStep('healthCheck', stepFunction, stepConfig);
};

exports.handler = async () => {
    return await synthetics.executeStep('healthEndpointCheck', apiCanaryBlueprint);
}; 