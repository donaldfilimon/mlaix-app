#!/bin/bash

# Check if a code signing identity is provided as an argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 <code signing identity>"
    echo "example: $0 XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    exit 1
fi

CODE_SIGNING_IDENTITY=${@: -1}

cd scripts
# Download and sign marp to support presentation creation
./setup-marp.sh "$CODE_SIGNING_IDENTITY"
