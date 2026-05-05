#!/bin/bash

# ============================================================================
# HTB ENUM SCRIPT
# Runs nmap + ffuf (endpoints + vhosts) in parallel
# Usage: ./enum.sh [-i IP] [-d DOMAIN] [-n NAME] [-w1 WORDLIST1] [-w2 WORDLIST2] [-wv VHOST_WORDLIST]
# ============================================================================

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
RESET="\033[0m"

# ============================================================================
# PARSE FLAGS
# ============================================================================

while [ $# -gt 0 ]; do
    case "$1" in
        -i) IP="$2"; shift 2 ;;
        -d) DOMAIN="$2"; shift 2 ;;
        -n) MACHINE_NAME="$2"; shift 2 ;;
        -w1) WORDLIST1="$2"; shift 2 ;;
        -w2) WORDLIST2="$2"; shift 2 ;;
        -wv) VHOST_WORDLIST="$2"; shift 2 ;;
        *) printf "${RED}[-] Unknown flag: $1\n${RESET}"; exit 1 ;;
    esac
done

printf "\n"
printf "${CYAN}============================================\n${RESET}"
printf "${CYAN}           HTB ENUM SCRIPT                  \n${RESET}"
printf "${CYAN}============================================\n${RESET}"
printf "\n"

# ============================================================================
# PROMPT FOR MISSING REQUIRED FIELDS
# ============================================================================

prompt_required() {
    local varname="$1"
    local label="$2"
    local value=""
    while [ -z "$value" ]; do
        printf "$label: "
        read value
        [ -z "$value" ] && printf "${RED}[-] This field cannot be empty\n${RESET}"
    done
    eval "$varname=\"$value\""
}

prompt_optional() {
    local varname="$1"
    local label="$2"
    printf "$label (leave blank to skip): "
    read value
    eval "$varname=\"$value\""
}

[ -z "$MACHINE_NAME" ] && prompt_required MACHINE_NAME "Machine name"
[ -z "$IP" ]           && prompt_required IP "IP"
[ -z "$DOMAIN" ]       && prompt_required DOMAIN "Domain (e.g. machine.htb)"

printf "\n"
[ -z "$WORDLIST1" ]       && prompt_required WORDLIST1 "Endpoint wordlist 1 (absolute path)"
[ -z "$WORDLIST2" ]       && prompt_optional WORDLIST2 "Endpoint wordlist 2 (absolute path)"
[ -z "$VHOST_WORDLIST" ]  && prompt_optional VHOST_WORDLIST "Vhost wordlist (absolute path)"

# Validate wordlist paths exist
for wl in "$WORDLIST1" "$WORDLIST2" "$VHOST_WORDLIST"; do
    if [ -n "$wl" ] && [ ! -f "$wl" ]; then
        printf "${RED}[-] Wordlist not found: $wl\n${RESET}"
        exit 1
    fi
done

printf "\n"
printf "${YELLOW}[*] Starting enumeration for ${MACHINE_NAME} (${IP} / ${DOMAIN})\n${RESET}"
printf "\n"

# ============================================================================
# NMAP
# ============================================================================

printf "${GREEN}[+] nmap running -> nmap.txt\n${RESET}"
nmap -sS -sC -sV -p- "$IP" > nmap.txt 2>&1 &
NMAP_PID=$!

NMAP_START=$SECONDS
sleep 3
if ! kill -0 "$NMAP_PID" 2>/dev/null; then
    elapsed=$(( SECONDS - NMAP_START ))
    if [ "$elapsed" -lt 3 ]; then
        printf "${RED}[-] nmap failed immediately — output:\n${RESET}"
        cat nmap.txt
        exit 1
    fi
fi

# ============================================================================
# FFUF - ENDPOINTS
# ============================================================================

FFUF1_PID=""
FFUF2_PID=""

if [ -n "$WORDLIST1" ] && [ -n "$WORDLIST2" ]; then
    printf "${GREEN}[+] ffuf endpoint 1 running -> fuzz1.txt\n${RESET}"
    ffuf -w "$WORDLIST1" -u "http://${DOMAIN}/FUZZ" -ac > fuzz1.txt 2>&1 &
    FFUF1_PID=$!

    printf "${GREEN}[+] ffuf endpoint 2 running -> fuzz2.txt\n${RESET}"
    ffuf -w "$WORDLIST2" -u "http://${DOMAIN}/FUZZ" -ac > fuzz2.txt 2>&1 &
    FFUF2_PID=$!

elif [ -n "$WORDLIST1" ]; then
    printf "${GREEN}[+] ffuf endpoint running -> fuzz.txt\n${RESET}"
    ffuf -w "$WORDLIST1" -u "http://${DOMAIN}/FUZZ" -ac > fuzz.txt 2>&1 &
    FFUF1_PID=$!
fi

if [ -n "$FFUF1_PID" ]; then
    FFUF1_START=$SECONDS
    sleep 3
    if ! kill -0 "$FFUF1_PID" 2>/dev/null; then
        elapsed=$(( SECONDS - FFUF1_START ))
        if [ "$elapsed" -lt 3 ]; then
            printf "${RED}[-] ffuf endpoint 1 failed immediately — output:\n${RESET}"
            cat fuzz1.txt 2>/dev/null || cat fuzz.txt 2>/dev/null
        fi
    fi
fi

# ============================================================================
# FFUF - VHOSTS
# ============================================================================

VFUZZ_PID=""

if [ -n "$VHOST_WORDLIST" ]; then
    printf "${GREEN}[+] ffuf vhost running -> vfuzz.txt\n${RESET}"
    ffuf -w "$VHOST_WORDLIST" -u "http://${IP}" -H "Host: FUZZ.${DOMAIN}" -ac > vfuzz.txt 2>&1 &
    VFUZZ_PID=$!

    VFUZZ_START=$SECONDS
    sleep 3
    if ! kill -0 "$VFUZZ_PID" 2>/dev/null; then
        elapsed=$(( SECONDS - VFUZZ_START ))
        if [ "$elapsed" -lt 3 ]; then
            printf "${RED}[-] ffuf vhost failed immediately — output:\n${RESET}"
            cat vfuzz.txt
        fi
    fi
fi

# ============================================================================
# WAIT FOR ALL
# ============================================================================

printf "\n"
printf "${YELLOW}[*] All jobs running, waiting for them to finish...\n${RESET}"
printf "\n"

wait "$NMAP_PID" && printf "${GREEN}[+] nmap done\n${RESET}" || printf "${RED}[-] nmap exited with error — check nmap.txt\n${RESET}"

[ -n "$FFUF1_PID" ] && { wait "$FFUF1_PID" && printf "${GREEN}[+] ffuf endpoint 1 done\n${RESET}" || printf "${RED}[-] ffuf endpoint 1 exited with error\n${RESET}"; }
[ -n "$FFUF2_PID" ] && { wait "$FFUF2_PID" && printf "${GREEN}[+] ffuf endpoint 2 done\n${RESET}" || printf "${RED}[-] ffuf endpoint 2 exited with error\n${RESET}"; }
[ -n "$VFUZZ_PID" ] && { wait "$VFUZZ_PID" && printf "${GREEN}[+] ffuf vhost done\n${RESET}" || printf "${RED}[-] ffuf vhost exited with error\n${RESET}"; }

printf "\n"
printf "${CYAN}============================================\n${RESET}"
printf "${CYAN}        ENUM COMPLETE - ${MACHINE_NAME}     \n${RESET}"
printf "${CYAN}============================================\n${RESET}"
printf "\n"
ls -la *.txt 2>/dev/null
printf "\n"
