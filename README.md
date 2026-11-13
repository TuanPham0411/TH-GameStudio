# TH GameStudio

Launcher nhẹ cho Raspberry Pi OS 64-bit Desktop (Wayland/labwc). HTML/CSS/JavaScript thuần và Python 3; không cần npm hoặc dịch vụ ngoài để chơi game offline.

## Chạy thử

Tại thư mục repository:

```bash
python3 -m http.server 8765 --bind 127.0.0.1 --directory web
```

Mở `http://127.0.0.1:8765` trên chính máy chạy server. Dừng bằng Ctrl+C.

## Cài trên Pi

Chạy bằng tài khoản desktop `thienha`, không phải root. Nếu đang ở root remote shell, dùng `sudo -iu thienha` trước.

```bash
sudo apt update
sudo apt install git python3 chromium
cd ~
git clone https://github.com/TuanPham0411/TH-GameStudio.git
cd TH-GameStudio
bash scripts/install-pi.sh
```

Nếu đã có checkout, cập nhật bằng `git pull --ff-only` tại checkout đó thay vì clone đè.

Script tạo user service `th-gamestudio.service`, desktop autostart và helper trong home của tài khoản hiện tại. Server chỉ nghe trên loopback, không có API thực thi lệnh hệ thống. Desktop autologin của Pi cần được bật. Không tạo worktree; dùng checkout hiện có trong mỗi môi trường riêng.

Để mở ngay, chạy lệnh sau **trong Terminal trên desktop Pi**:

```bash
~/.local/bin/th-gamestudio-start
```

Sau khi reboot, kiểm tra launcher tự hiện trên TV và Pi Connect vẫn vào được. Chưa kiểm chứng trực tiếp trên Pi thật. Dùng 720p cho Pi 3B+.

## Điều khiển

- Mũi tên chọn mục, Enter mở. Trong game rắn: mũi tên đổi hướng, Enter chơi lại, Esc thoát game.
- Tay cầm chuẩn Gamepad API: D-pad / cần trái, A chọn, B quay lại. Nhấn nút trên tay cầm để trình duyệt nhận thiết bị. Cần kiểm tra ánh xạ trên tay cầm thực tế.
- Alt+F4 thoát Chromium kiosk về desktop. Mở lại launcher bằng helper phía trên.
- Webgame mở cùng cửa sổ. Alt+Left để quay lại (có thể cần nhiều lần nếu website điều hướng); Alt+F4 rồi chạy lại helper nếu cần. Tay cầm trên website bên ngoài tùy game.

## Phạm vi bản đầu

Có Rắn săn mồi offline, liên kết 2048 và thư viện web itch.io. Chưa tích hợp emulator, chạy executable Linux, tải ROM hoặc cài game. Không bảo đảm mọi webgame chạy tốt trên Pi 3B+.

## Bảo trì

```bash
systemctl --user status th-gamestudio.service
journalctl --user -u th-gamestudio.service -n 50 --no-pager
```

Tắt tự mở giao diện: xóa `~/.config/autostart/th-gamestudio.desktop`. Dừng server bằng `systemctl --user disable --now th-gamestudio.service`. Các thay đổi này không tắt Pi Connect hay SSH.
