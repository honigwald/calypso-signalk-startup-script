#!/bin/bash

# Ensure MAC address is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <CALYPSO_MAC_ADDRESS>"
    exit 1
fi

# Assign command-line argument
CALYPSO_MAC="$1"

# Variables
BT_ADAPTER=$(hciconfig -a | grep -o 'hci[0-9]*')
SIGNALK_URL='udp+signalk+delta://127.0.0.1:4123'
PIDFILE="$HOME/.aenometer.lock"
BIN_PATH="$HOME/.local/bin/calypso-anemometer"

# Export Paths
export PATH="$PATH:$HOME/.local/bin/"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$HOME/.local/lib/"

# Ensure dependencies are available
if ! command -v hciconfig &>/dev/null; then
    echo "Error: hciconfig not found. Install bluez package."
    exit 1
fi

if [ -z "$BT_ADAPTER" ]; then
    echo "Error: No Bluetooth adapter found."
    exit 1
fi

if [ ! -x "$BIN_PATH" ]; then
    echo "Error: $BIN_PATH is not executable. Check installation."
    exit 1
fi

# Check if process is already running
if pgrep -f "calypso-anemometer" >/dev/null; then
    echo "Calypso anemometer already running (PID: $(pgrep -f calypso-anemometer))"
    exit 0
fi

# Start the Calypso anemometer
echo "Starting Calypso Anemometer with MAC: $CALYPSO_MAC..."
"$BIN_PATH" --quiet read --subscribe --rate=HZ_1 --ble-adapter="$BT_ADAPTER" --ble-address="$CALYPSO_MAC" --target="$SIGNALK_URL" &

# Allow time for startup
sleep 10

# Store PID if started successfully
if pgrep -f "calypso-anemometer" >/dev/null; then
    pgrep -f "calypso-anemometer" > "$PIDFILE"
    echo "Started successfully. PID stored in $PIDFILE"
else
    echo "Error: Failed to start Calypso Anemometer."
    exit 1
fi
