#!/bin/sh

#set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

YAD="/opt/base/bin/yad"

log() {
    if is-bool-val-true "${CONTAINER_DEBUG:-0}"; then
        echo "$*" >> /tmp/cp_login.log
    fi
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

url_decode() {
    strg="${*}"
    printf '%s' "${strg%%[%+]*}"
    j="${strg#"${strg%%[%+]*}"}"
    strg="${j#?}"
    case "${j}" in "%"* )
        printf '%b' "\\0$(printf '%o' "0x${strg%"${strg#??}"}")"
        strg="${strg#??}"
        ;; "+"* ) printf ' '
        ;;    * ) return
    esac
    if [ -n "${strg}" ] ; then url_decode "${strg}"; fi
}

success() {
    /opt/base/bin/yad \
        --on-top \
        --fixed \
        --center \
        --title "$APP_NAME" \
        --window-icon /opt/noVNC/app/images/icons/master_icon.png \
        --borders 10 \
        --image dialog-info \
        --image-on-top \
        --text "$1" \
        --button=gtk-ok:0
}

error() {
    /opt/base/bin/yad \
        --on-top \
        --fixed \
        --center \
        --title "$APP_NAME" \
        --window-icon /opt/noVNC/app/images/icons/master_icon.png \
        --borders 10 \
        --image dialog-error \
        --image-on-top \
        --text "$1" \
        --button=gtk-ok:0
}

curl_err() {
    if [ -f "$1" ]; then
        cat "$1" | head -n1 | sed 's/^curl: ([0-9]\+) //'
    else
        echo "$1" | head -n1 | sed 's/^curl: ([0-9]\+) //'
    fi
}

# Get the login URL.
LOGIN_URL="${1:-}"
if [ -n "$LOGIN_URL" ]; then
    log "login url provided by CrashPlan app: $LOGIN_URL"
else
    error "No login URL specified."
    exit 1
fi

# Extract the CrashPlan server address from login URL.
SERVER="$(echo "$LOGIN_URL" | awk -F[/:] '{print $4}')"
if [ -n "$SERVER" ]; then
    log "CrashPlan server to use: $SERVER"
else
    error "Failed to parse login URL: could not extract server address."
    exit 1
fi

# Extract username from login URL.
USER="$(echo "$LOGIN_URL" | sed -r 's/.*[&?]username=([^&]+)(&|$).*/\1/')"
USER="$(url_decode "$USER")"
if [ -n "$USER" ]; then
    log "username to use: $USER"
else
    error "Failed to parse login URL: could not extract username."
    exit 1
fi

# Extract UUID from login URL.
UUID="$(echo "$LOGIN_URL" | sed -r 's/.*[&?]uuid=([^&]+)(&|$).*/\1/')"
if [ -n "$UUID" ]; then
    log "uuid to use: $UUID"
else
    error "Failed to parse login URL: could not extract uuid."
    exit 1
fi

output=$(mktemp)
stderr=$(mktemp)
trap '{ rm -f "$output" "$stderr"; }' EXIT

while true; do
    # Ask user credentials.
    $YAD \
        --separator='\n' \
        --geometry=400x100 \
        --borders=10 \
        --on-top \
        --center \
        --title "$APP_NAME" \
        --window-icon /opt/noVNC/app/images/icons/master_icon.png \
        --text "<big>Sign in to CrashPlan</big>" \
        --text-align=center \
        --form \
        --field="Username:RO" \
        --field="Password:H" \
        --field="Authentication code" \
        "$USER" \
        > "$output"

    if [ $? -ne 0 ]; then
        # User clicked cancel.
        exit 1
    fi

    # Get fields.
    PASSWORD="$(awk 'NR==2' "$output" | xargs)"
    TOTP="$(awk 'NR==3' "$output" | xargs)"

    if [ -z "$PASSWORD" ]; then
        error "Password must be provided."
        continue
    fi

    # Fetch the CrashPlan server environment.
    code="$(curl \
        -sS \
        --output "$output" \
        --write-out '%{http_code}' \
        --max-time 60 \
        https://$SERVER/api/v1/ServerEnv \
        2>$stderr)"

    log "fetch of server environment completed:"
    log "HTTP status: $code"
    log "output: $(cat "$output")"
    log "stderr: $(cat "$stderr")"

    if [ $code -eq 0 ] || [ $code -ge 400 ]; then
        error "Unable to fetch CrashPlan server environment: $(curl_err "$stderr")."
        continue
    else
        log "CrashPlan server environment: $(cat "$output")"
    fi

    # Extract the "lcts" field from the environment.
    LCTS="$(grep 'lcts":' "$output" | cut -d ':' -f2 | tr -d '", ')"
    if [ -n "$LCTS" ]; then
        log "lcts value: '$LCTS'"
    else
        error "Received unexpected CrashPlan server environment."
        continue
    fi

    # Build the challenge.
    CHALLENGE="1.$(printf "%s:%s" "$USER" "$LCTS" | openssl dgst -sha256 -binary | base64)"

    # Perform the login.
    code=$(curl \
        -sS \
        --output "$output" \
        --write-out '%{http_code}' \
        --max-time 60 \
        -H "Authorization: Basic $(printf "%s:%s" "$USER" "$PASSWORD" | base64)" \
        -H "totp-auth: $TOTP" \
        -H "X-CrashPlan-LCC: $CHALLENGE" \
        "https://$SERVER/api/v3/auth/jwt?useBody=true" \
        2>$stderr
    )

    log "login completed:"
    log "HTTP status: $code"
    log "output: $(cat "$output")"
    log "stderr: $(cat "$stderr")"

    if [ $code -eq 0 ]; then
        error "Unable to sign in: $(curl_err "$stderr")."
        continue
    elif [ $code -ge 400 ]; then
        if [ $code -eq 401 ]; then
            error "Unable to sign in. Please check username, password and authentication code."
        else
            error "Unable to sign in (HTTP status $code)."
        fi
        continue
    fi

    # Finalize the login.
    code=$(curl \
        -sS \
        -X POST \
        -d "{\"uuid\":\"$UUID\"}" \
        --output "$output" \
        --write-out '%{http_code}' \
        --max-time 60 \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $(cat "$output" | jq -r .data.v3_user_token)" \
        "https://$SERVER/api/v3/agent-login-finalize" \
        2>$stderr
    )

    log "post login completed:"
    log "HTTP status: $code"
    log "output: $(cat "$output")"
    log "stderr: $(cat "$stderr")"

    if [ $code -eq 0 ]; then
        error "Unable to complete sign in: $(curl_err "$stderr")."
        continue
    elif [ $code -ge 400 ]; then
        error "Unable to complete sign in (HTTP status $code)."
        continue
    else
        success "Sign in successful. The $APP_NAME app will be signed in automatically."
        break
    fi
done
