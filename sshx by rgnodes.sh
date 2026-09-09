bash -lc '
set -Eeuo pipefail

export NO_COLOR=1

NAME="RGNODES™ ;D"
BASE="/tmp/sshx-rgnodes"
BIN="$BASE/sshx"
LOG="$BASE/$(date +%s%N).log"

mkdir -p "$BASE"
chmod 700 "$BASE" 2>/dev/null || true

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║             ⚡ RGNODES™ • SSHx                  ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║ Status : GENERATING SESSION                      ║"
echo "║ Mode   : INSTANT / MULTI-SESSION                 ║"
echo "║ Name   : $NAME"
echo "╚══════════════════════════════════════════════════╝"
echo ""

if ! command -v curl >/dev/null 2>&1; then
    echo "[•] curl not found."

    if [ "$(id -u)" -eq 0 ]; then
        apt-get update -y >/dev/null 2>&1 || true
        apt-get install -y curl ca-certificates >/dev/null 2>&1 || true
    elif command -v sudo >/dev/null 2>&1; then
        sudo apt-get update -y >/dev/null 2>&1 || true
        sudo apt-get install -y curl ca-certificates >/dev/null 2>&1 || true
    fi
fi

command -v curl >/dev/null 2>&1 || {
    echo "[❌] curl is required."
    exit 1
}

if [ ! -x "$BIN" ]; then
    echo "[•] Installing SSHx..."

    if ! (
        cd "$BASE"
        curl -sSf https://sshx.io/get | sh
    ) >/tmp/rgnodes-sshx-install.log 2>&1; then
        echo "[❌] SSHx installation failed."
        echo "[•] Installer log:"
        cat /tmp/rgnodes-sshx-install.log 2>/dev/null || true
        exit 1
    fi

    chmod +x "$BIN" 2>/dev/null || true
fi

[ -x "$BIN" ] || {
    echo "[❌] SSHx executable not found."
    exit 1
}

echo "[✅] SSHx binary : READY"
echo "[⚡] Creating a NEW session..."
echo ""

# Each execution creates its own independent SSHx session.
# Do not kill previous sessions.
"$BIN" \
    --quiet \
    --name "$NAME" \
    2>&1 | tee "$LOG"

STATUS=${PIPESTATUS[0]}

echo ""

if [ "$STATUS" -eq 0 ]; then
    echo "╔══════════════════════════════════════════════════╗"
    echo "║              ✅ SESSION CREATED                  ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║ RGNODES™ SSHx session generated successfully.    ║"
    echo "║ This execution does not terminate other         ║"
    echo "║ existing SSHx sessions.                          ║"
    echo "╚══════════════════════════════════════════════════╝"
else
    echo "╔══════════════════════════════════════════════════╗"
    echo "║              ❌ SESSION FAILED                   ║"
    echo "╠══════════════════════════════════════════════════╣"
    echo "║ Exit code: $STATUS"
    echo "║ Log file : $LOG"
    echo "╚══════════════════════════════════════════════════╝"
    exit "$STATUS"
fi
'
