#!/bin/bash
set -euo pipefail
if [ "$(id -u)" = 0 ]; then
  echo 'Chạy script bằng tài khoản desktop (thienha), không dùng root.' >&2
  exit 1
fi
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
if [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
  echo 'Chưa có phiên desktop của tài khoản hiện tại. Đăng nhập desktop Pi rồi thử lại.' >&2
  exit 1
fi
repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
command -v python3 >/dev/null
browser="$(command -v chromium || command -v chromium-browser || true)"
if [ -z "$browser" ]; then echo 'Cần cài chromium: sudo apt install chromium' >&2; exit 1; fi
mkdir -p "$HOME/.config/systemd/user" "$HOME/.config/autostart"
service="$HOME/.config/systemd/user/th-gamestudio.service"
entry="$HOME/.config/autostart/th-gamestudio.desktop"
for file in "$service" "$entry"; do
  if [ -e "$file" ] && ! grep -q 'Managed by TH-GameStudio' "$file"; then
    echo "Không ghi đè cấu hình có sẵn: $file" >&2; exit 1
  fi
done
# systemd quoted values: escape paths for spaces, quotes, backslashes and percent.
escaped="${repo_dir//\\/\\\\}"
escaped="${escaped//\"/\\\"}"
escaped="${escaped//%/%%}"
cat > "$service" <<UNIT
# Managed by TH-GameStudio
[Unit]
Description=TH GameStudio local launcher
[Service]
ExecStart=/usr/bin/python3 -m http.server 8765 --bind 127.0.0.1 --directory "$escaped/web"
Restart=on-failure
RestartSec=3
[Install]
WantedBy=default.target
UNIT
# Keep startup in a separate helper so the desktop entry has a simple Exec value.
mkdir -p "$HOME/.local/bin"
helper="$HOME/.local/bin/th-gamestudio-start"
if [ -e "$helper" ] && ! grep -q 'Managed by TH-GameStudio' "$helper"; then
  echo "Không ghi đè $helper" >&2; exit 1
fi
cat > "$helper" <<'HELPER'
#!/bin/bash
# Managed by TH-GameStudio
set -eu
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
if [ ! -S "$XDG_RUNTIME_DIR/bus" ]; then
  echo 'Chưa có phiên desktop. Hãy mở bằng Terminal trên desktop Pi.' >&2
  exit 1
fi
systemctl --user start th-gamestudio.service
for attempt in {1..30}; do
  if python3 -c 'import urllib.request; urllib.request.urlopen("http://127.0.0.1:8765/", timeout=1)' 2>/dev/null; then
    browser="$(command -v chromium || command -v chromium-browser)"
    exec "$browser" --kiosk --no-first-run --user-data-dir="$HOME/.local/share/th-gamestudio/chromium" http://127.0.0.1:8765/
  fi
  sleep 1
done
echo 'Launcher server không sẵn sàng' >&2
exit 1
HELPER
chmod +x "$helper"
cat > "$entry" <<ENTRY
# Managed by TH-GameStudio
[Desktop Entry]
Type=Application
Name=TH GameStudio
Exec="$helper"
Terminal=false
ENTRY
systemctl --user daemon-reload
systemctl --user enable --now th-gamestudio.service
python3 - <<'CHECK'
import time
import urllib.request
for attempt in range(30):
    try:
        with urllib.request.urlopen("http://127.0.0.1:8765/", timeout=1) as response:
            assert b"TH GameStudio" in response.read(), "Port 8765 is serving another application"
        print("Launcher HTTP: OK")
        break
    except OSError:
        if attempt == 29:
            raise
        time.sleep(1)
CHECK
echo 'Đã cài. Đăng nhập desktop lần tiếp theo sẽ mở launcher. Alt+F4 để thoát.'
