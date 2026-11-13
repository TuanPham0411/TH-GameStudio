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
# Remote shells do not inherit the desktop Wayland environment.
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  shopt -s nullglob
  sockets=()
  for socket in "$XDG_RUNTIME_DIR"/wayland-*; do
    [ -S "$socket" ] && sockets+=("$socket")
  done
  if [ "${#sockets[@]}" -ne 1 ]; then
    echo 'Không xác định được Wayland desktop. Mở từ Terminal trên desktop Pi hoặc đặt WAYLAND_DISPLAY đúng phiên.' >&2
    exit 1
  fi
  export WAYLAND_DISPLAY="${sockets[0]##*/}"
fi
export XDG_SESSION_TYPE=wayland
systemctl --user start th-gamestudio.service
for attempt in {1..30}; do
  if python3 -c 'import urllib.request; urllib.request.urlopen("http://127.0.0.1:8765/", timeout=1)' 2>/dev/null; then
    browser="$(command -v chromium || command -v chromium-browser)"
    exec "$browser" --ozone-platform=wayland --kiosk --no-first-run --user-data-dir="$HOME/.local/share/th-gamestudio/chromium" http://127.0.0.1:8765/
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
# Install a persistent shortcut and icon, independent of deployment release paths.
mkdir -p "$HOME/.local/share/icons" "$HOME/.local/share/applications"
cp "$repo_dir/web/icon.svg" "$HOME/.local/share/icons/th-gamestudio.svg"
shortcut="$HOME/.local/share/applications/th-gamestudio.desktop"
if [ -e "$shortcut" ] && ! grep -q 'Managed by TH-GameStudio' "$shortcut"; then
  echo "Không ghi đè $shortcut" >&2; exit 1
fi
cat > "$shortcut" <<SHORTCUT
# Managed by TH-GameStudio
[Desktop Entry]
Type=Application
Name=TH GameStudio
Comment=Mở thư viện game trên TV
Exec="$helper"
Icon=$HOME/.local/share/icons/th-gamestudio.svg
Terminal=false
Categories=Game;
SHORTCUT
desktop_dir="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
if [ -z "$desktop_dir" ] || [ "$desktop_dir" = "$HOME" ]; then
  desktop_dir="$HOME/Desktop"
fi
mkdir -p "$desktop_dir"
desktop_shortcut="$desktop_dir/TH-GameStudio.desktop"
if [ -e "$desktop_shortcut" ] && ! grep -q 'Managed by TH-GameStudio' "$desktop_shortcut"; then
  echo "Không ghi đè $desktop_shortcut" >&2; exit 1
fi
cp "$shortcut" "$desktop_shortcut"
chmod +x "$desktop_shortcut"
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
