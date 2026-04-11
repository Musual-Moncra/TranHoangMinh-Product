<div align="center">

# 📖 TECHNICAL DOCUMENTATION

**TranHoangMinh-Product — Tài liệu kỹ thuật dành cho Developer**

*Phiên bản: 1.0 · Cập nhật: 2026-04-11*

</div>

---

## Mục lục

- [1. Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
- [2. Cấu trúc thư mục](#2-cấu-trúc-thư-mục)
- [3. Rojo Mapping](#3-rojo-mapping)
- [4. Hệ thống Data](#4-hệ-thống-data)
- [5. Hệ thống Rebirth](#5-hệ-thống-rebirth)
- [6. Hệ thống Item Spawner](#6-hệ-thống-item-spawner)
- [7. GUI System](#7-gui-system)
- [8. Shared Modules API](#8-shared-modules-api)
- [9. Server Setup & Bootstrap](#9-server-setup--bootstrap)
- [10. Coding Conventions](#10-coding-conventions)
- [11. Hướng dẫn mở rộng](#11-hướng-dẫn-mở-rộng)
- [12. Troubleshooting](#12-troubleshooting)

---

## 1. Tổng quan kiến trúc

Dự án tuân theo mô hình **Client-Server Authority** của Roblox:

```
┌─────────────────────────────────────────────────────────────────┐
│                         SERVER                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐    │
│  │ DataManager  │  │   Remotes    │  │   Server Setup     │    │
│  │ (Data CRUD)  │  │ (Validation) │  │ (Physics/Char)     │    │
│  └──────┬───────┘  └──────┬───────┘  └────────────────────┘    │
│         │                 │                                     │
│  ┌──────▼─────────────────▼──────┐                              │
│  │     ServerStorage.data (API)  │                              │
│  │  givestats / removestats /    │                              │
│  │  createstatinstance / etc.    │                              │
│  └───────────────────────────────┘                              │
└──────────────────────┬──────────────────────────────────────────┘
                       │ RemoteEvents / ReplicatedStorage
┌──────────────────────▼──────────────────────────────────────────┐
│                         CLIENT                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────┐    │
│  │   GUI Layer  │  │  SetupPlayer │  │   Item Visuals     │    │
│  │ (Main/Rebirth│  │ (Buff apply) │  │ (Highlights)       │    │
│  └──────────────┘  └──────────────┘  └────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────────────┐
│                    SHARED (ReplicatedStorage)                    │
│  ┌──────────┐  ┌──────────────┐  ┌───────────┐  ┌───────────┐ │
│  │  Config   │  │   Modules    │  │   Events  │  │   Assets  │ │
│  │(Data/Item/│  │(tween/number/│  │(remotes/  │  │  (items)  │ │
│  │ Rebirth)  │  │ animation)   │  │ bindable) │  │           │ │
│  └──────────┘  └──────────────┘  └───────────┘  └───────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Nguyên tắc thiết kế

1. **Server Authority**: Mọi logic quan trọng (data, rebirth, item pickup) đều do server xử lý
2. **Config-Driven**: Gameplay behavior được điều khiển bởi config tables, không hard-code
3. **Modular**: Mỗi system là một module độc lập, giao tiếp qua API rõ ràng
4. **Data Replication**: Player data được replicate qua `ReplicatedStorage.PlayerData` để client đọc

---

## 2. Cấu trúc thư mục

```
TranHoangMinh-Product/
│
├── default.project.json          # Rojo project definition
├── aftman.toml                   # Toolchain manager config
├── README.md                     # Tổng quan dự án
├── TECHNICAL.md                  # Tài liệu này
├── assets/
│   └── banner.png                # Project banner image
│
└── src/
    ├── api/                      ──► ServerStorage
    │   └── data/
    │       ├── createbasefolder.lua    # Tạo PlayerData folder
    │       ├── createstatinstance.lua  # Tạo ValueBase instances
    │       ├── givestats.lua          # Cộng stat cho player
    │       └── removestats.lua        # Trừ stat cho player
    │
    ├── client/                   ──► StarterPlayerScripts
    │   ├── gui/
    │   │   ├── maingui.lua           # Main HUD controller
    │   │   └── rebirthgui.lua        # Rebirth panel controller
    │   └── main/
    │       ├── itemvisuals.client.lua # Distance-based item highlights
    │       ├── leaderstats.lua        # Client-side leaderboard display
    │       └── setupplayer.lua        # Apply rebirth buffs on spawn
    │
    ├── server/                   ──► ServerScriptService
    │   ├── library/
    │   │   └── itemspawners.lua      # Item spawner OOP system
    │   ├── main/
    │   │   └── DataManager.server.lua # Core data loading/saving
    │   ├── remotes/
    │   │   ├── requestrebirth.lua     # Rebirth remote handler
    │   │   └── takeitem.lua           # Item pickup handler
    │   └── setup/
    │       ├── character.lua          # Character collision groups
    │       └── physics.lua            # Physics collision group setup
    │
    └── storage/                  ──► ReplicatedStorage
        ├── config/
        │   ├── DataConfig.lua        # Data schema definition
        │   ├── ItemsConfig.lua       # Item definitions & rarity
        │   └── RebirthConfig.lua     # Rebirth costs & buffs
        └── shared/
            ├── animation.lua         # Animation handler wrapper  
            ├── numberformat.lua      # Number formatting utility
            └── tween.lua             # TweenService wrapper
```

---

## 3. Rojo Mapping

Định nghĩa trong `default.project.json`:

| Thư mục Source | Roblox Container | Vai trò |
|---|---|---|
| `src/api` | `ServerStorage` | Server-only API modules (không gửi cho client) |
| `src/client` | `StarterPlayerScripts` | Client scripts, chạy trên máy player |
| `src/server` | `ServerScriptService` | Server scripts, chạy trên server |
| `src/storage` | `ReplicatedStorage` | Shared modules + configs, replicate cho cả 2 |

### Quy tắc đặt tên file

| Pattern | Ý nghĩa |
|---|---|
| `*.server.lua` | Rojo tự nhận dạng là `Script` (server) |
| `*.client.lua` | Rojo tự nhận dạng là `LocalScript` (client) |
| `*.lua` | `ModuleScript` (require được) |

---

## 4. Hệ thống Data

### 4.1 Data Schema — `DataConfig.lua`

```lua
DataList = {
    ["Cash"] = {
        Default = 0,
        Type = "IntValue",
        Leaderstats = {true, 1},  -- {hiển thị, thứ tự}
    },
    ["Rebirth"] = {
        Default = 0,
        Type = "IntValue",
        Leaderstats = {true, 2},
    },
}
```

**Để thêm stat mới**, chỉ cần thêm entry vào `DataList`. Hệ thống tự động:
- Tạo `ValueBase` instance
- Load/Save từ DataStore
- Đồng bộ với leaderstats (nếu bật)

### 4.2 Data Flow

```
Player Join
    │
    ▼
DataManager.LoadData()
    ├── DataStore:GetAsync(key)
    ├── CreateData() → Tạo folder + stat instances
    ├── LoadStats() → Gán giá trị từ DataStore
    └── SetupLeaderstats() → Tạo leaderstats đồng bộ
    
Player Leave / Auto-Save (60s)
    │
    ▼
DataManager.SaveData()
    ├── Thu thập tất cả stat values vào table
    └── DataStore:SetAsync(key, data)
```

### 4.3 Data API — `ServerStorage.data`

Chỉ sử dụng trên **Server**.

#### `givestats(Player, StatName, Value)`
Cộng `Value` vào stat (nếu là Number/IntValue), hoặc gán trực tiếp (nếu là String/BoolValue).

```lua
local givestats = require(ServerStorage.data.givestats)
givestats(player, "Cash", 100)  -- Cash += 100
```

#### `removestats(Player, StatName, Value)`
Trừ `Value` khỏi stat (nếu là Number/IntValue).

```lua
local removestats = require(ServerStorage.data.removestats)
removestats(player, "Cash", 50)  -- Cash -= 50
```

#### `createstatinstance(Type, Default, Parent, Name)`
Tạo một ValueBase instance.

```lua
local create = require(ServerStorage.data.createstatinstance)
create("IntValue", 0, statsFolder, "Coins")
```

#### `createbasefolder(Parent)`
Tạo folder `PlayerData` làm container chứa data tất cả player.

---

## 5. Hệ thống Rebirth

### 5.1 Config — `RebirthConfig.lua`

| Tham số | Giá trị | Mô tả |
|---|---|---|
| `BaseCost` | `1000` | Chi phí rebirth đầu tiên |
| `CostMultiplier` | `2.5` | Hệ số nhân chi phí |
| `MaxRebirth` | `50` | Giới hạn tối đa |
| `BaseStats.WalkSpeed` | `16` | WalkSpeed mặc định |
| `BaseStats.JumpPower` | `50` | JumpPower mặc định |

**Công thức chi phí:**
```
Cost = floor(BaseCost × CostMultiplier ^ currentRebirth)
```

| Rebirth | Chi phí |
|---|---|
| 0 → 1 | 1,000 |
| 1 → 2 | 2,500 |
| 2 → 3 | 6,250 |
| 5 → 6 | 97,656 |
| 10 → 11 | 9,536,743 |

### 5.2 Buff System

**Default buff mỗi rebirth:** +2 WalkSpeed, +5% JumpPower

**Milestone overrides:**

| Mốc | Speed Buff | Jump Buff |
|---|---|---|
| 5 | +5 | +10% |
| 10 | +8 | +15% |
| 25 | +15 | +25% |
| 50 | +25 | +50% |

**Tổng buff tại rebirth N** = tổng cộng dồn tất cả buff từ 1 → N

**Công thức áp dụng:**
```
WalkSpeed = BaseSpeed + totalSpeedBuff
JumpPower = BaseJump × (1 + totalJumpPercentage)
```

### 5.3 Flow

```
Client                          Server
  │                               │
  ├── Click Rebirth Button ──────►│
  │   FireServer()                │
  │                               ├── Validate cooldown (2s)
  │                               ├── Check Cash >= Cost
  │                               ├── Check Rebirth < Max
  │                               ├── Cash = 0
  │                               ├── Rebirth += 1
  │                               ├── Apply buffs to Humanoid
  │◄───── FireClient(true, lvl) ──┤
  │                               │
  ├── Show success animation      │
  ├── Update UI                   │
  └── setupplayer.lua re-applies  │
      buffs on stat change        │
```

### 5.4 Files liên quan

| File | Vai trò |
|---|---|
| `storage/config/RebirthConfig.lua` | Config: costs, buffs, base stats |
| `server/remotes/requestrebirth.lua` | Server handler + buff application on spawn |
| `client/gui/rebirthgui.lua` | GUI controller: toggle, display, animations |
| `client/main/setupplayer.lua` | Client-side buff re-application |
| `client/gui/maingui.lua` | Rebirth button toggle handler |

---

## 6. Hệ thống Item Spawner

### 6.1 Cách hoạt động

Sử dụng **CollectionService Tags** — bất kỳ Model nào trong workspace có tag `ItemsSpawner` sẽ tự động trở thành spawner.

### 6.2 Config

Đặt thuộc tính trên Model hoặc dùng ModuleScript con:

| Attribute | Default | Mô tả |
|---|---|---|
| `ItemName` | `"Noob"` | Item mặc định khi spawn |
| `SpawnRate` | `5` | Giây giữa mỗi lần spawn |
| `MaxItems` | `5` | Số item tối đa cùng lúc |
| `SpawnRadius` | `10` | Bán kính spawn (studs) |
| `InteractType` | `"Touch"` | `"Touch"` / `"Click"` / `"Prompt"` |

**Custom Config** (ModuleScript con tên `Config`):
```lua
return {
    MaxItems = 10,
    SpawnRate = 3,
    InteractType = "Prompt",
    Items = {          -- Drop table với weight
        Noob = 80,     -- 80% chance
        Rare = 15,     -- 15% chance
        Legendary = 5, -- 5% chance
    }
}
```

### 6.3 Item Definitions — `ItemsConfig.lua`

```lua
return {
    Rarity = {
        ["Common"]    = Color3.fromRGB(115, 250, 121),  -- Green
        ["Rare"]      = Color3.fromRGB(0, 150, 255),    -- Blue
        ["Legendary"] = Color3.fromRGB(255, 252, 121),  -- Gold
    },
    Items = {
        ["Noob"] = {
            Price = 100,        -- Cash khi pickup
            Rarity = "Common"
        },
        -- Thêm item mới ở đây
    }
}
```

### 6.4 Pickup Flow

```
Item Spawns → Billboard GUI created → Interaction listener attached
    │
    ▼
Player interacts (Touch/Click/Prompt)
    │
    ▼
TriggerEvent(player)
    ├── Disconnect listener
    ├── Fire BindableEvent "takeitem"
    ├── Pickup animation (tween up + fade out)
    └── Destroy item after 0.35s
    
Server: takeitem handler
    └── givestats(player, "Cash", itemData.Price)
```

### 6.5 Client Visuals — `itemvisuals.client.lua`

- Mỗi frame (`RenderStepped`) kiểm tra khoảng cách player ↔ spawned items
- Items trong phạm vi `25 studs` nhận `Highlight` với màu theo rarity
- Highlight tự động xóa khi ra khỏi phạm vi hoặc item bị destroy

---

## 7. GUI System

### 7.1 Roblox Studio UI Requirements

Cần tạo trong Roblox Studio (không quản lý qua Rojo):

#### ScreenGui `Main`

```
Main (ScreenGui)
├── UIScale
├── Left (Frame)
│   ├── PlayerCard (Frame)
│   │   ├── Username (TextLabel)
│   │   ├── PlayerIcon (Frame) → Icon (ImageLabel)
│   │   ├── HP (Frame) → Fill (Frame) → UIGradient
│   │   ├── Speed (TextLabel)
│   │   └── JumpPower (TextLabel)
│   ├── Cash (TextLabel)
│   └── Rebirth (TextLabel)
└── Right (Frame)
    └── ButtonFrame (Frame)
        └── Rebirth (GuiButton) → UIScale
```

#### ScreenGui `Rebirth`

```
Rebirth (ScreenGui)
└── MainFrame (CanvasGroup)
    ├── ExitButton (GuiButton) → UIScale
    └── Content (Frame)
        ├── Confirm (GuiButton) → UIScale
        ├── CostLabel (TextLabel)     -- Optional
        ├── BuffLabel (TextLabel)     -- Optional
        └── StatusLabel (TextLabel)   -- Optional
```

### 7.2 Giao tiếp giữa GUI scripts

`maingui.lua` gọi `_G.ToggleRebirthUI()` (được expose bởi `rebirthgui.lua`) khi nút Rebirth được click.

> ⚠️ **Lưu ý**: `_G` là cách đơn giản để giao tiếp giữa scripts. Nếu dự án lớn hơn, nên chuyển sang Event-based hoặc Module-based communication.

---

## 8. Shared Modules API

### 8.1 `tween.lua` — Tween Wrapper

Đơn giản hóa `TweenService:Create()`.

```lua
local Tween = require(ReplicatedStorage.shared.tween)

-- Play (tạo + chạy)
local tweenObj = Tween:Play(instance, {duration, easingStyle?, easingDir?}, properties)

-- Chỉ tạo (không chạy)
local tweenObj = Tween:Create(instance, {0.5, "Quad", "Out"}, {Transparency = 0})
tweenObj:Play()
```

| Param | Type | Ví dụ |
|---|---|---|
| `tweenInfo[1]` | `number` | `0.5` (duration) |
| `tweenInfo[2]` | `string?` | `"Quad"`, `"Exponential"`, `"Back"` |
| `tweenInfo[3]` | `string?` | `"Out"`, `"In"`, `"InOut"` |

### 8.2 `numberformat.lua` — Định dạng số

```lua
local Format = require(ReplicatedStorage.shared.numberformat)

Format(123456789, "Suffix")    -- "123.45m"
Format(123456789, "Commas")    -- "123,456,789"
Format(123456789, "Notation")  -- "1.2e08"
Format(999, "Suffix")          -- "999" (dưới 1k trả về nguyên)
```

Suffixes hỗ trợ lên đến `9.999e44`:
`k → m → n → t → qd → qn → sx → sp → oc → n → d → ud → dd → tdd`

### 8.3 `animation.lua` — Animation Handler

OOP wrapper cho `Animator:LoadAnimation()` với **caching** và **cleanup**.

```lua
local Anim = require(ReplicatedStorage.shared.animation)

-- Tạo handler (1 per Humanoid/AnimationController)
local handler = Anim.new(humanoid)

-- Load + Play
handler:Play("Slash", "rbxassetid://123456", {
    Speed = 1.5,              -- Tốc độ (default: 1)
    FadeTime = 0.2,           -- Fade in time (default: 0.1)
    Looped = false,           -- Lặp? (default: từ animation)
    Priority = Enum.AnimationPriority.Action,
    Weight = 1,               -- Trọng số (default: 1)
})

-- Queries
handler:IsPlaying("Slash")    -- boolean
handler:GetTrack("Slash")     -- AnimationTrack?

-- Adjustments
handler:SetSpeed("Slash", 2)
handler:SetWeight("Slash", 0.5, 0.2)

-- Events
handler:OnStopped("Slash", function() print("Done!") end)
handler:OnKeyframe("Slash", function(name) print("Hit: " .. name) end)

-- Stop
handler:Stop("Slash", 0.2)   -- Fade out 0.2s
handler:StopAll(0.1)          -- Stop tất cả

-- Cleanup (gọi khi humanoid die hoặc không cần nữa)
handler:Destroy()
```

---

## 9. Server Setup & Bootstrap

### 9.1 `physics.lua`

Tạo collision groups khi server khởi động:

| Group | Mục đích |
|---|---|
| `Players` | Character parts |
| `SpawnedItems` | Items đã spawn |

**Rules**: Players ↔ SpawnedItems = **không va chạm**

### 9.2 `character.lua`

- Tạo folder `workspace.Characters` chứa tất cả character
- Gán collision group `Players` cho mọi BasePart trong character
- Tự động áp dụng cho parts thêm vào sau (accessories, tools)

### 9.3 Boot Order

```
Server Start
    ├── physics.lua              → Tạo collision groups
    ├── character.lua            → Setup character handling
    ├── DataManager.server.lua   → Lắng nghe PlayerAdded/Removing
    ├── itemspawners.lua         → Quét tags, bắt đầu spawn
    ├── requestrebirth.lua       → Lắng nghe remote events
    └── takeitem.lua             → Lắng nghe bindable events

Client Start (per player)
    ├── maingui.lua              → Initialize HUD
    ├── rebirthgui.lua           → Initialize Rebirth panel
    ├── setupplayer.lua          → Apply rebirth buffs
    ├── leaderstats.lua          → Client leaderboard display
    └── itemvisuals.client.lua   → Item highlight loop
```

---

## 10. Coding Conventions

### Naming

| Element | Convention | Ví dụ |
|---|---|---|
| Variables | PascalCase | `PlayerData`, `MainFrame` |
| Functions | PascalCase | `UpdateValue()`, `LoadData()` |
| Private fields | `_camelCase` | `self._cache`, `self._animator` |
| Config keys | PascalCase | `SpeedBuff`, `BaseCost` |
| File names | lowercase | `givestats.lua`, `maingui.lua` |
| Folders | lowercase | `remotes/`, `config/` |

### Module Pattern

```lua
-- Utility module (singleton)
local Module = {}
function Module:MethodName() end
return Module

-- OOP module (class)
local Class = {}
Class.__index = Class
function Class.new() return setmetatable({}, Class) end
function Class:Method() end
return Class
```

### Comments

```lua
-- Inline comment (tiếng Việt hoặc English)

--[[
    Block comment cho module header:
    @ModuleName - @Author
]]
```

### Remote Events

- Nằm trong `ReplicatedStorage.events.remotes` (RemoteEvent)
- Nằm trong `ReplicatedStorage.events.bindable` (BindableEvent — server-to-server)
- Naming: `snake_case` (VD: `request_rebirth`, `takeitem`)

---

## 11. Hướng dẫn mở rộng

### Thêm Stat mới

1. **Config**: Thêm entry vào `DataConfig.lua → DataList`:
```lua
["Gems"] = {
    Default = 0,
    Type = "IntValue",
    Leaderstats = {true, 3},
}
```
2. ✅ Done. DataManager tự động xử lý phần còn lại.

### Thêm Item mới

1. **Config**: Thêm vào `ItemsConfig.lua → Items`:
```lua
["Diamond"] = {
    Price = 500,
    Rarity = "Legendary"
}
```
2. **Model**: Tạo model `Diamond` trong `ReplicatedStorage.items`
3. **Spawner**: Thêm vào drop table của spawner config

### Thêm Rarity mới

1. **Config**: Thêm màu vào `ItemsConfig.lua → Rarity`:
```lua
["Mythic"] = Color3.fromRGB(255, 0, 255)
```

### Thêm Remote mới

1. Tạo `RemoteEvent` trong `ReplicatedStorage.events.remotes` (trong Roblox Studio)
2. Tạo handler file mới trong `src/server/remotes/`
3. Tạo client caller trong script tương ứng

### Chỉnh Rebirth

- **Thay đổi chi phí**: Sửa `BaseCost` / `CostMultiplier` trong `RebirthConfig.lua`
- **Thêm buff mốc**: Thêm entry vào `RebirthConfig.Buffs`
- **Thêm loại buff mới**: Mở rộng `GetTotalBuffs()` và cập nhật `ApplyRebirthBuffs()` trong cả `requestrebirth.lua` và `setupplayer.lua`

---

## 12. Troubleshooting

### Data không lưu

- Kiểm tra Output console cho lỗi `"Failed to save data"`
- Đảm bảo đang test trong Roblox Studio (không phải Play Solo nếu DataStore bị tắt)
- Bật **Enable Studio Access to API Services** trong Game Settings

### Rebirth không hoạt động

- Kiểm tra `RemoteEvent` `request_rebirth` tồn tại trong `ReplicatedStorage.events.remotes`
- Kiểm tra Output console cho validation failures
- Đảm bảo player có đủ Cash (kiểm tra qua leaderstats)

### Item không spawn

- Kiểm tra Model có tag `ItemsSpawner` trong CollectionService
- Kiểm tra template item tồn tại trong `ReplicatedStorage.items`
- Kiểm tra Output console cho warning `"Item template not found"`

### GUI không hiện

- Đảm bảo ScreenGui `Main` và `Rebirth` đã được tạo trong Roblox Studio
- Kiểm tra cấu trúc UI hierarchy đúng như mô tả ở [Section 7.1](#71-roblox-studio-ui-requirements)
- `MainFrame` của Rebirth phải là `CanvasGroup` (không phải `Frame`)

### Collision group lỗi

- Đảm bảo `physics.lua` chạy trước `character.lua` và `itemspawners.lua`
- Collision groups phải được đăng ký trước khi sử dụng

---

<div align="center">

*Tài liệu này được duy trì bởi team phát triển. Mọi thay đổi kiến trúc cần cập nhật tài liệu tương ứng.*

**TranHoangMinh-Product** · Built by Musual · 2026

</div>
