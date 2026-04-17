#!/bin/bash

echo "Starting Bluetooth SPP Server for Smart Home Controller"
echo "======================================================"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    exit 1
fi

# Check if pybluez2 is installed
python3 -c "import bluetooth" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: pybluez2 is not installed."
    echo "Install with: pip install pybluez2"
    exit 1
fi

# Change to the server directory
cd "$(dirname "$0")/spp_server"

echo "Starting SPP server with default settings..."
echo "Service name: SmartHome-SPP-Test"
echo "Channel: 1"
echo "Response delay: 5 seconds"
echo ""
echo "Note: You may need to run with sudo for Bluetooth access:"
echo "sudo $0"
echo ""

# Start the server
python3 spp_server.py --name "SmartHome-SPP-Test" --channel 1 --delay 5
