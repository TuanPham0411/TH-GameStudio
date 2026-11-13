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

## Giao diện và game offline

Bốn game mini 2D chạy tại máy, không tải tài nguyên mạng:

- **Đường đua hoàng hôn**: mũi tên trái/phải hoặc cần trái để tránh xe; va chạm kết thúc lượt.
- **Vệ binh ngân hà**: trái/phải di chuyển, Space hoặc A bắn; va chạm hoặc để đối thủ vượt qua kết thúc lượt.
- **Cặp đôi bí ẩn**: tìm sáu cặp thẻ bằng chuột, bàn phím hoặc tay cầm.
- **Cả nhà cùng đoán**: hai người luân phiên dùng chung bộ điều khiển, tám câu hỏi và điểm riêng từng người.

Đây là game mini giải trí, chưa phải mô phỏng đua xe 3D hoặc game bắn súng thương mại. Không có emulator hoặc game online trong phiên bản này.

## Điều khiển và shortcut

Mũi tên chọn mục, Enter/A chọn. Trong game hành động, Enter khi hết lượt hoặc Start trên tay cầm để chơi lại. Mỗi game có nút **← Quay lại thư viện**; Esc/B cũng quay lại. Tab dùng để tới nút Quay lại khi chơi game hành động. Alt+F4 thoát về desktop.

Bộ cài tạo shortcut **TH GameStudio** trên Desktop và trong menu ứng dụng. Nếu desktop hỏi quyền chạy, chọn cho phép thực thi. Chạy lại workflow để cập nhật shortcut khi nâng cấp từ bản trước. Tay cầm phải hỗ trợ Gamepad API; nhấn nút để Chromium nhận thiết bị. Cần kiểm chứng ánh xạ và hiệu năng trên Pi thật.

## Bảo trì

```bash
systemctl --user status th-gamestudio.service
journalctl --user -u th-gamestudio.service -n 50 --no-pager
```

Tắt tự mở giao diện: xóa `~/.config/autostart/th-gamestudio.desktop`. Dừng server bằng `systemctl --user disable --now th-gamestudio.service`. Các thay đổi này không tắt Pi Connect hay SSH.

## GitHub Actions runner trên Pi

Workflow **Deploy launcher to Raspberry Pi** chạy thủ công từ tab Actions, chỉ cho nhánh `main`. Dùng runner riêng có nhãn `th-gamestudio`; chưa tự triển khai mỗi lần push. Workflow không chạy pull request. Với repository public, chỉ cho người tin cậy quyền ghi và quyền chạy workflow: job trên self-hosted runner có quyền của tài khoản Pi.

### Đăng ký một lần

Trên GitHub vào **Settings → Actions → Runners → New self-hosted runner**, chọn **Linux / ARM64**. GitHub sẽ cung cấp phiên bản hiện hành, lệnh tải, kiểm tra SHA256 và mã đăng ký tạm thời. Không đưa mã đăng ký vào chat hoặc repository.

Trên Pi, tạo thư mục bằng tài khoản desktop:

```bash
sudo -iu thienha
mkdir -p ~/actions-runner
cd ~/actions-runner
```

Thực hiện các lệnh tải và kiểm tra SHA256 do GitHub hiển thị, rồi giải nén tại đây. Chạy lệnh `./config.sh` mà GitHub cung cấp; đặt runner name `th-gamestudio-pi`, thêm label `th-gamestudio`, dùng work folder mặc định `_work`. Không chạy runner dưới root.

Cài công cụ cho launcher nếu chưa có:

```bash
sudo apt update
sudo apt install git python3 chromium
```

Trong `~/actions-runner`, đăng ký service chạy bằng `thienha`:

```bash
sudo ./svc.sh install thienha
sudo ./svc.sh start
sudo ./svc.sh status
```

Runner kết nối ra GitHub qua HTTPS, không cần mở cổng vào Pi và không cần Tailscale trên máy tính. Nếu GitHub báo runner Offline, kiểm tra service và mạng của Pi.

### Triển khai

Giữ desktop `thienha` đăng nhập (autologin), vào **Actions → Deploy launcher to Raspberry Pi → Run workflow → main**. Job cài release vào `~/apps/th-gamestudio/releases/`, cấu hình tự khởi động và kiểm tra HTTP phục vụ đúng JavaScript của release. Chưa tự xóa các release cũ.

Lần đầu, mở Terminal **trên desktop Pi qua Pi Connect** rồi chạy:

```bash
~/.local/bin/th-gamestudio-start
```

Lần sau, refresh launcher đang mở để nhận bản mới. Workflow không đóng Chromium hoặc ngắt Pi Connect. Sau reboot, kiểm tra launcher tự mở và runner trở về trạng thái Idle. HTTP pass không thay thế kiểm tra HDMI, Bluetooth và tay cầm trên Pi thật.
