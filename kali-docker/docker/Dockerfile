FROM kalilinux/kali-rolling

RUN apt update && apt install -y \
    nmap \
    sqlmap \
    hydra \
    ffuf \
    gobuster \
    tmux \
    git \
    curl \
    iputils-ping \
    net-tools \
    && apt clean

WORKDIR /workspace
