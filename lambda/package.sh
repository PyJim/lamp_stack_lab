#!/bin/bash

# Ensure we're in the correct directory
SCRIPT_DIR=$(dirname "$0")
cd "$SCRIPT_DIR"

# Create a clean folder for dependencies
rm -rf package
mkdir package

# Install dependencies into 'package' folder
pip install -r requirements.txt -t package

# Zip the dependencies and Lambda function together
cd package
zip -r ../lambda_function.zip .  # Correct relative path
cd ..
zip -g lambda_function.zip lambda_function.py  # Add the function file

echo "Lambda package created: lambda_function.zip"
