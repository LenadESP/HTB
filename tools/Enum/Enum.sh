#!/bin/bash

# ============================================================================
# HTB ENUM SCRIPT v2
# Runs nmap + ffuf (endpoints recursive + vhosts + files) 
# Usage: ./enum.sh [-i IP] [-d DOMAIN] [-n NAME] [-w1 WL1] [-w2 WL2] [-wv WV] [-wf WF] [-ext EXTENSIONS]
# ============================================================================

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
RESET="\033[0m"

# ============================================================================
# DEFAULTS
# ============================================================================

DEFAULT_EXTENSIONS="php,html,js,txt,json,xml"

# ============================================================================
# PARSE FLAGS
# ============================================================================

while [ $# -gt 0 ]; do
    case "$1" in
        -i)   IP="$2";             shift 2 ;;
        -d)   DOMAIN="$2";         shift 2 ;;
        -n)   MACHINE_NAME="$2";   shift 2 ;;
        -w1)  WORDLIST1="$2";      shift 2 ;;
        -w2)  WORDLIST2="$2";      shift 2 ;;
        -wv)  VHOST_WORDLIST="$2";  shift 2 ;;
        -wf)  FILE_WORDLIST="$2";   shift 2 ;;
        -ext) EXTENSIONS="$2";      shift 2 ;;
        *)    printf "${RED}[-] Unknown flag: $1\n${RESET}"; exit 1 ;;
    esac
done

[ -z "$EXTENSIONS" ] && EXTENSIONS="$DEFAULT_EXTENSIONS"

printf "\n"
printf "${CYAN}============================================\n${RESET}"
printf "${CYAN}           HTB ENUM SCRIPT v2               \n${RESET}"
printf "${CYAN}============================================\n${RESET}"
printf "\n"

# ============================================================================
# PROMPT HELPERS
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
[ -z "$WORDLIST1" ] && prompt_required WORDLIST1 "Endpoint wordlist 1 (absolute path)"
[ -z "$WORDLIST2" ] && prompt_optional WORDLIST2 "Endpoint wordlist 2 (absolute path)"
[ -z "$VHOST_WORDLIST" ] && prompt_optional VHOST_WORDLIST "Vhost wordlist (absolute path)"
[ -z "$FILE_WORDLIST" ] && prompt_optional FILE_WORDLIST "File wordlist (absolute path, e.g. raft-large-files.txt)"

for wl in "$WORDLIST1" "$WORDLIST2" "$VHOST_WORDLIST" "$FILE_WORDLIST"; do
    if [ -n "$wl" ] && [ ! -f "$wl" ]; then
        printf "${RED}[-] Wordlist not found: $wl\n${RESET}"
        exit 1
    fi
done

# ============================================================================
# OUTPUT FILES
# ============================================================================

TREE_FILE="tree.txt"
NMAP_FILE="nmap.txt"
VFUZZ_FILE="vfuzz.txt"

# Initialize tree file
printf "%s\n" "$DOMAIN" > "$TREE_FILE"

# ============================================================================
# TREE HELPERS
# ============================================================================

# Associative array to track discovered paths
declare -A DISCOVERED

# Add a path to the tree file with proper indentation
# Args: $1 = path segment to display, $2 = depth
add_to_tree() {
    local path="$1"
    local depth="$2"
    local indent=""
    local i=0
    while [ $i -lt $depth ]; do
        indent="${indent}    "
        i=$(( i + 1 ))
    done
    printf "%s└── %s\n" "$indent" "$path" >> "$TREE_FILE"
}

# ============================================================================
# FFUF JSON PARSER
# Extracts paths from ffuf json output
# ============================================================================

parse_ffuf() {
    local file="$1"
    grep '"url"' "$file" 2>/dev/null \
        | sed 's/.*"url": *"\([^"]*\)".*/\1/' \
        | sed "s|http://${DOMAIN}||" \
        | sed "s|http://${IP}||" \
        | sort -u
}

# ============================================================================
# FUZZ A SINGLE PATH
# Args: $1 = base path (e.g. "" or "/api"), $2 = depth
# Prints new directory paths found (for recursion)
# ============================================================================

fuzz_path() {
    local base="$1"
    local depth="$2"
    local url="http://${DOMAIN}${base}/FUZZ"
    local tmpfile1 tmpfile2 tmpfile_files
    tmpfile1=$(mktemp /tmp/ffuf_XXXXXX.json)
    tmpfile2=$(mktemp /tmp/ffuf_XXXXXX.json)
    tmpfile_files=$(mktemp /tmp/ffuf_files_XXXXXX.json)

    local display_base="${base:-/}"
    printf "${YELLOW}[*] Fuzzing: %s\n${RESET}" "$display_base"

    # Wordlist 1 - directories
    ffuf -w "$WORDLIST1" \
         -u "$url" \
         -ac \
         -of json \
         -o "$tmpfile1" \
         -s 2>/dev/null

    # Wordlist 2 - directories (if provided)
    if [ -n "$WORDLIST2" ]; then
        ffuf -w "$WORDLIST2" \
             -u "$url" \
             -ac \
             -of json \
             -o "$tmpfile2" \
             -s 2>/dev/null
    fi

    # File fuzzing with extensions — uses dedicated file wordlist if provided, falls back to WORDLIST1
    local file_wl="${FILE_WORDLIST:-$WORDLIST1}"
    local ext_formatted
    ext_formatted=".$(echo "$EXTENSIONS" | sed 's/,/,./g')"
    ffuf -w "$file_wl" \
         -u "$url" \
         -e "$ext_formatted" \
         -ac \
         -of json \
         -o "$tmpfile_files" \
         -s 2>/dev/null

    # Collect, deduplicate, filter already seen
    local all_found
    all_found=$(
        { parse_ffuf "$tmpfile1"; parse_ffuf "$tmpfile2"; parse_ffuf "$tmpfile_files"; } \
        | sort -u
    )

    rm -f "$tmpfile1" "$tmpfile2" "$tmpfile_files"

    local count=0
    local new_dirs=""

    while IFS= read -r p; do
        [ -z "$p" ] && continue
        # Build full path key for dedup
        local full="${base}${p}"
        if [ -z "${DISCOVERED[$full]+x}" ]; then
            DISCOVERED[$full]=1
            count=$(( count + 1 ))
            # Write to tree using just the segment relative to base
            add_to_tree "$p" "$depth"
            # Only queue directories (no file extension) for recursion
            if [[ "$p" != *.* ]]; then
                new_dirs="${new_dirs}${p}"$'\n'
            fi
        fi
    done <<< "$all_found"

    printf "${GREEN}[+] Done: %s — %d new result(s)\n${RESET}" "$display_base" "$count"

    # Print tree so far in real time
    printf "\n"
    printf "${BLUE}--- Tree so far ---\n${RESET}"
    cat "$TREE_FILE"
    printf "${BLUE}-------------------\n${RESET}"
    printf "\n"

    # Output new dirs for caller to queue
    printf "%s" "$new_dirs"
}

# ============================================================================
# RECURSIVE ENDPOINT FUZZER
# BFS layer by layer
# ============================================================================

recursive_fuzz() {
    local -a queue=("")
    local depth=1

    while [ ${#queue[@]} -gt 0 ]; do
        local -a next_queue=()

        printf "\n"
        printf "${MAGENTA}===== LAYER %d — %d path(s) to fuzz =====\n${RESET}" \
               "$depth" "${#queue[@]}"

        for base in "${queue[@]}"; do
            local new_paths
            new_paths=$(fuzz_path "$base" "$(( depth - 1 ))")
            while IFS= read -r p; do
                [ -n "$p" ] && next_queue+=("${base}/${p#/}")
            done <<< "$new_paths"
        done

        if [ ${#next_queue[@]} -gt 0 ]; then
            printf "${YELLOW}[*] Layer %d complete. %d new director(ies) queued for layer %d.\n${RESET}" \
                   "$depth" "${#next_queue[@]}" "$(( depth + 1 ))"
        else
            printf "${GREEN}[+] Layer %d complete. No new directories found. Recursion done.\n${RESET}" \
                   "$depth"
        fi

        depth=$(( depth + 1 ))
        queue=("${next_queue[@]}")
    done
}

# ============================================================================
# NMAP — background
# ============================================================================

printf "\n"
printf "${YELLOW}[*] Starting enumeration for: ${MACHINE_NAME} (${IP} / ${DOMAIN})\n${RESET}"
printf "\n"
printf "${GREEN}[+] nmap running in background -> %s\n${RESET}" "$NMAP_FILE"
nmap -sS -sC -sV -p- "$IP" > "$NMAP_FILE" 2>&1 &
NMAP_PID=$!

# ============================================================================
# VHOST FUZZING — background
# ============================================================================

VFUZZ_PID=""
if [ -n "$VHOST_WORDLIST" ]; then
    printf "${GREEN}[+] ffuf vhost running in background -> %s\n${RESET}" "$VFUZZ_FILE"
    ffuf -w "$VHOST_WORDLIST" \
         -u "http://${IP}" \
         -H "Host: FUZZ.${DOMAIN}" \
         -ac \
         -of json \
         -o "$VFUZZ_FILE" \
         -s 2>/dev/null &
    VFUZZ_PID=$!
fi

# ============================================================================
# RECURSIVE ENDPOINT FUZZING — foreground
# ============================================================================

printf "\n"
printf "${CYAN}============================================\n${RESET}"
printf "${CYAN}       RECURSIVE ENDPOINT FUZZING           \n${RESET}"
printf "${CYAN}============================================\n${RESET}"

recursive_fuzz

# ============================================================================
# FINAL TREE PRINT
# ============================================================================

printf "\n"
printf "${CYAN}============================================\n${RESET}"
printf "${CYAN}            FINAL ENDPOINT TREE             \n${RESET}"
printf "${CYAN}============================================\n${RESET}"
cat "$TREE_FILE"

# ============================================================================
# WAIT FOR BACKGROUND JOBS
# ============================================================================

printf "\n"
printf "${YELLOW}[*] Waiting for nmap and vhost scan...\n${RESET}"

wait "$NMAP_PID" \
    && printf "${GREEN}[+] nmap done -> %s\n${RESET}" "$NMAP_FILE" \
    || printf "${RED}[-] nmap error — check %s\n${RESET}" "$NMAP_FILE"

if [ -n "$VFUZZ_PID" ]; then
    wait "$VFUZZ_PID" \
        && printf "${GREEN}[+] vhost done -> %s\n${RESET}" "$VFUZZ_FILE" \
        || printf "${RED}[-] vhost fuzz error — check %s\n${RESET}" "$VFUZZ_FILE"

    printf "\n"
    printf "${CYAN}--- VHOSTS FOUND ---\n${RESET}"
    local vhosts
    vhosts=$(parse_ffuf "$VFUZZ_FILE")
    if [ -n "$vhosts" ]; then
        echo "$vhosts"
    else
        printf "${YELLOW}  (none)\n${RESET}"
    fi
fi

# ============================================================================
# DONE
# ============================================================================

printf "\n"
printf "${CYAN}============================================\n${RESET}"
printf "${CYAN}       ENUM COMPLETE — ${MACHINE_NAME}      \n${RESET}"
printf "${CYAN}============================================\n${RESET}"
printf "\n"
printf "${BLUE}Files generated:\n${RESET}"
ls -la *.txt *.json 2>/dev/null
printf "\n"
printf "${BLUE}Full tree saved to: %s\n${RESET}" "$TREE_FILE"
printf "\n"
