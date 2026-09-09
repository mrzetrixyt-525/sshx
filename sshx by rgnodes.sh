bash -lc '
set -Eeuo pipefail

export NO_COLOR=1

NAME="RGNODES™ ;D"
BASE="/tmp/sshx-rgnodes"
BIN="$BASE/sshx"
LOG="$BASE/sshx.log"
PID="$BASE/sshx.pid"

mkdir -p "$BASE"
chmod 700 "$BASE" 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║              ⚡ RGNODES™ • SSHx                  ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║ Status : Initializing                            ║"
echo "║ Session: $NAME"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# Remove stale PID/session information.
if [ -f "$PID" ]; then
    OLD_PID="$(cat "$PID" 2>/dev/null || true)"

    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        echo "[•] Stopping previous SSHx process: $OLD_PID"
        kill "$OLD_PID" 2>/dev/null || true
    fi

    rm -f "$PID"
fi

# curl is required by the official installer.
if ! command -v curl >/dev/null 2>&1; then
    echo "[•] curl not found. Installing..."

    if [ "$(id -u)" -eq 0 ]; then
        apt-get update -y >/dev/null 2>&1 || true
        apt-get install -y curl ca-certificates >/dev/null 2>&1 || true
    elif command -v sudo >/dev/null 2>&1; then
        sudo apt-get update -y >/dev/null 2>&1 || true
        sudo apt-get install -y curl ca-certificates >/dev/null 2>&1 || true
    fi
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "[❌] curl is unavailable."
    exit 1
fi

# Download only when the binary is missing.
if [ ! -x "$BIN" ]; then
    echo "[•] Downloading official SSHx binary..."

    if ! (
        cd "$BASE"
        curl -sSf https://sshx.io/get | sh -s download
    ) >"$BASE/download.log" 2>&1; then

        echo "[❌] SSHx download failed."
        echo "[•] Download log: $BASE/download.log"
        tail -n 30 "$BASE/download.log" 2>/dev/null || true
        exit 1
    fi

    chmod +x "$BIN" 2>/dev/null || true
fi

if [ ! -x "$BIN" ]; then
    echo "[❌] SSHx binary was not installed correctly."
    exit 1
fi

rm -f "$LOG"

echo "[✅] SSHx binary      : READY"
echo "[✅] Previous session : CLEAN"
echo "[⚡] Launching SSHx    : NOW"
echo ""

# Start SSHx immediately.
nohup "$BIN" \
    --quiet \
    --name "$NAME" \
    >"$LOG" 2>&1 </dev/null &

SSHX_PID=$!
printf "%s\n" "$SSHX_PID" >"$PID"

echo "╔══════════════════════════════════════════════════╗"
echo "║              ✅ SSHx STARTED                     ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║ PID  : $SSHX_PID"
echo "║ LOG  : $LOG"
echo "║ NAME : $NAME"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# No polling / no timeout / no long waiting.
# Read whatever SSHx has already emitted.
if [ -s "$LOG" ]; then
    echo "────────────── SSHx OUTPUT ──────────────"
    cat "$LOG"
    echo "────────────────────────────────────────"
else
    echo "[⚡] SSHx process is running."
    echo "[•] URL will be emitted by SSHx when its session is initialized."
fi

echo ""
echo "[✅] Process check:"
if kill -0 "$SSHX_PID" 2>/dev/null; then
    echo "    ONLINE • PID $SSHX_PID"
else
    echo "    OFFLINE • SSHx exited immediately"
    echo ""
    echo "────────────── FAILURE LOG ──────────────"
    cat "$LOG" 2>/dev/null || true
    echo "────────────────────────────────────────"
    exit 1
fi
'
