<div align="center">

![Project Banner](assets/banner.png)

# ✨ TranHoangMinh-Product

[![Roblox](https://img.shields.io/badge/Roblox-Powered-00A2FF?style=for-the-badge&logo=roblox&logoColor=white)](https://www.roblox.com)
[![Rojo](https://img.shields.io/badge/Rojo-v7.7.0--rc.1-D32F2F?style=for-the-badge&logo=github&logoColor=white)](https://github.com/rojo-rbx/rojo)
[![Luau](https://img.shields.io/badge/Luau-Typed-7B68EE?style=for-the-badge&logo=lua&logoColor=white)](https://luau-lang.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Một Roblox game framework hiện đại — kiến trúc module, data-driven, và sẵn sàng mở rộng.**

---

[Tài liệu kỹ thuật](TECHNICAL.md) • [Báo lỗi](https://github.com/musual/TranHoangMinh-Product/issues) • [Yêu cầu tính năng](https://github.com/musual/TranHoangMinh-Product/issues)

</div>

---

## 🎮 Tổng quan

**TranHoangMinh-Product** là một Roblox game project được xây dựng với kiến trúc module hiện đại, sử dụng [Rojo](https://rojo.space) để quản lý source code bên ngoài Roblox Studio. Dự án áp dụng mô hình **Client-Server Authority** nghiêm ngặt, đảm bảo an toàn và hiệu suất.

### Tính năng chính

| Tính năng | Mô tả | Trạng thái |
|---|---|---|
| 💾 **Data System** | Lưu/tải dữ liệu player với DataStore, auto-save 60s | ✅ Hoàn thiện |
| 🔄 **Rebirth System** | Rebirth để đổi Cash lấy buff vĩnh viễn (Speed, Jump) | ✅ Hoàn thiện |
| 📦 **Item Spawner** | Hệ thống spawn item configurable với Touch/Click/Prompt | ✅ Hoàn thiện |
| 🎨 **Item Visuals** | Highlight item theo rarity, distance-based rendering | ✅ Hoàn thiện |
| 🖥️ **GUI System** | Main HUD, Rebirth panel với tween animations | ✅ Hoàn thiện |
| 🎬 **Animation Handler** | Wrapper module cho Roblox Animator API | ✅ Hoàn thiện |

---

## 🏗️ Kiến trúc

```
src/
├── api/                    → ServerStorage (Server-only API)
│   └── data/               → Data manipulation modules
├── client/                 → StarterPlayerScripts  
│   ├── gui/                → GUI controllers
│   └── main/               → Client-side logic
├── server/                 → ServerScriptService
│   ├── library/            → Server-side systems (Item Spawner)
│   ├── main/               → Core server scripts (DataManager)
│   ├── remotes/            → Remote event handlers
│   └── setup/              → Bootstrap scripts (Physics, Character)
└── storage/                → ReplicatedStorage (Shared)
    ├── config/             → Game configurations
    └── shared/             → Shared utility modules
```

> **Rojo Mapping:** `src/api` → `ServerStorage` · `src/client` → `StarterPlayerScripts` · `src/server` → `ServerScriptService` · `src/storage` → `ReplicatedStorage`

---

## 🚀 Bắt đầu

### Yêu cầu

- [Roblox Studio](https://www.roblox.com/create)
- [Rojo](https://rojo.space/docs/v7/installation/) (v7.0+)
- [Aftman](https://github.com/lpghatguy/aftman) (Toolchain Manager)

### Cài đặt

```bash
# 1. Clone repo
git clone https://github.com/musual/TranHoangMinh-Product.git
cd TranHoangMinh-Product

# 2. Cài toolchain
aftman install

# 3. Build project
rojo build -o "TranHoangMinh-Product.rbxlx"

# 4. Hoặc khởi động live-sync server
rojo serve
```

### Kết nối Roblox Studio

1. Mở `TranHoangMinh-Product.rbxlx` trong Roblox Studio
2. Cài [Rojo Plugin](https://www.roblox.com/library/13916111004/Rojo) 
3. Click **"Connect"** trong Rojo plugin để đồng bộ code

---

## 📚 Tài liệu

| Tài liệu | Mô tả |
|---|---|
| [📖 TECHNICAL.md](TECHNICAL.md) | Tài liệu kỹ thuật chi tiết cho developer |
| [🔧 default.project.json](default.project.json) | Rojo project configuration |
| [📦 aftman.toml](aftman.toml) | Toolchain dependencies |

---

## 🔧 Shared Modules

Các module tiện ích dùng chung giữa Client và Server (nằm trong `ReplicatedStorage.shared`):

### `tween` — Tween Wrapper
```lua
local Tween = require(ReplicatedStorage.shared.tween)
Tween:Play(instance, {0.5, "Quad", "Out"}, {Transparency = 0})
```

### `numberformat` — Định dạng số
```lua
local Format = require(ReplicatedStorage.shared.numberformat)
Format(1234567, "Suffix")  -- "1.23m"
Format(1234567, "Commas")  -- "1,234,567"
```

### `animation` — Animation Handler
```lua
local Anim = require(ReplicatedStorage.shared.animation)
local handler = Anim.new(humanoid)
handler:Play("Attack", "rbxassetid://123", { Speed = 1.5 })
handler:Stop("Attack")
handler:Destroy()
```

---

## 🤝 Contributing

1. Fork dự án
2. Tạo Feature Branch (`git checkout -b feature/TinhNangMoi`)
3. Commit Changes (`git commit -m 'Thêm tính năng XYZ'`)
4. Push to Branch (`git push origin feature/TinhNangMoi`)
5. Mở Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<div align="center">

Created with ❤️ by **TranHoangMinh** (Musual)

</div>