#!/bin/bash

echo "[*] Launching container..."
docker run --rm -it \
  --network host \
  -v ~/htb/work:/workspace \
  -v ~/htb/resources/SecLists:/wordlists \
  -v ~/htb/config/.tmux.conf:/root/.tmux.conf \
  htb-kali \
  bash -c "tmux new-session -A -s htb"
