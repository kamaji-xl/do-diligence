#!/usr/bin/env bash

# NOTE: [Custom sound sources]
# level_up.mp3: https://www.zedge.net/notification-sounds/c18bd496-5c77-4307-962c-91bcd3a2c541
# fahhhhh.mp3: https://www.zedge.net/notification-sounds/f218e179-a6b3-45eb-9975-20d84ff54a44

set -u

DOWNLOAD_DIR="$HOME/Downloads"
LOG_FILE="$HOME/.local/share/do_diligence.log"

# NOTE:
# The sound effects below are not installed by default but I've included the sources of where I got them above.
# Feel free to use your own as well.
# SUCCESS_SOUND="$HOME/.local/share/sounds/level_up.mp3"
# FAIL_SOUND="$HOME/.local/share/sounds/fahhhhh.mp3"

# NOTE:
# If you don't want to install any custom soundeffects comment out the two above,
# and uncomment the two below. They come installed by default on Kali, but I can't
# speak to any other distros.
SUCCESS_SOUND="/usr/share/sounds/freedesktop/stereo/complete.oga"
FAIL_SOUND="/usr/share/sounds/freedesktop/stereo/dialog-error.oga"

mkdir -p "$(dirname "$LOG_FILE")"
touch  "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "SCRIPT STARTED"
log "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unset} DISPLAY=${DISPLAY:-unset}"

play_success_sound() {
    [[ -f "$SUCCESS_SOUND" ]] && paplay "$SUCCESS_SOUND" >/dev/null 2>&1 &
}

play_fail_sound() {
    [[ -f "$FAIL_SOUND" ]] && paplay "$FAIL_SOUND" >/dev/null 2>&1 &
}

get_clipboard_hash() {
    local clip=""

    if command -v xclip >/dev/null 2>&1; then
        clip="$(xclip -selection clipboard -o 2>/dev/null || true)"
    elif command -v xsel >/dev/null 2>&1; then
        clip="$(xsel --clipboard --output 2>/dev/null || true)"
    else
        return 1
    fi

    # NOTE: Parse clipboard entry for hash value
    printf '%s\n' "$clip" \
        | tr '[:upper:]' '[:lower:]' \
        | grep -Eo '[a-f0-9]{64}' \
        | head -n1
}

# NOTE:
# Hashes new file and compares computed hash against expected hash 
# found in the clipboard
verify_file() {
    local file="$1"
    local filename
    local actual_hash
    local clipboard_hash

    filename="$(basename "$file")"
    actual_hash="$(sha256sum "$file" | awk '{print $1}')"
    clipboard_hash="$(get_clipboard_hash)"

    if [[ -z "${clipboard_hash:-}" ]]; then
        log "NO CLIPBOARD HASH FOUND: $filename"
        log "ACTUAL: $actual_hash $file"
        play_fail_sound
        return 1
    fi

    if [[ "${actual_hash,,}" == "${clipboard_hash,,}" ]]; then
        log "VERIFIED OK: $filename"
        log "EXPECTED: ${clipboard_hash,,}"
        log "ACTUAL:   ${actual_hash,,}"
        play_success_sound
        return 0
    else
        log "VERIFICATION FAILED: $filename"
        log "EXPECTED: ${clipboard_hash,,}"
        log "ACTUAL:   ${actual_hash,,}"
        play_fail_sound
        return 1
    fi 
}

# NOTE:
# Waits for file to finish downloading, and fixes downloads
# initiated via the browser.
wait_for_stable_file() {
    local file="$1"
    local last_size=""
    local new_size=""

    while :; do
        new_size=$(stat -c %s "$file" 2>/dev/null) || return 1
        [[ "$new_size" == "$last_size" ]] && break
        last_size="$new_size"
        sleep 1
    done
}

# NOTE:
# Monitors filesystem for files to be moved into ~/Downloads/
# and initiates verification when a new file is detected
inotifywait -m -e moved_to --format '%w%f' "$DOWNLOAD_DIR" |
while IFS= read -r file; do
    [[ -f "$file" ]] || continue

    # Ignore temp files
    case "$file" in
        *.crdownload|*.part|*.tmp)
            continue
            ;;
    esac

    wait_for_stable_file "$file" || continue
    verify_file  "$file"
done
