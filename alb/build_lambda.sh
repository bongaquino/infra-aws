#!/bin/bash

# Build Lambda function package
echo "Building Lambda function package..."

# Install dependencies
npm install

# Create the zip file
zip -r alb_logs_processor.zip alb_logs_processor.js package.json node_modules/

echo "Lambda package created: alb_logs_processor.zip" 