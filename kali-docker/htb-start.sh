#!/bin/bash

echo "[*] Launching container..."
docker run --rm -it \
  --network host \
  -v ~/htb/work:/workspace \
  -v ~/htb/resources/SecLists:/wordlists/SecLists \
  -v ~/htb/tools:/tools \
  -v ~/htb/config/.tmux.conf:/root/.tmux.conf \
  htb-kali \
  bash -c "tmux new-session -A -s htb"
