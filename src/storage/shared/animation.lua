--[[
	Musual @ 2026
	Animation Handler

	A utility wrapper for Roblox AnimationController / Humanoid:LoadAnimation.
	Manages loading, caching, playing, and stopping animations with a clean API.

	---- Usage:
	local Anim = require(ReplicatedStorage.shared.animation)

	-- Tạo handler cho một humanoid
	local handler = Anim.new(humanoid)

	-- Load + play
	handler:Play("Slash", "rbxassetid://123456", {
		Speed = 1.5,
		FadeTime = 0.2,
		Looped = false,
		Priority = Enum.AnimationPriority.Action,
		Weight = 1,
	})

	-- Stop
	handler:Stop("Slash", 0.2)

	-- Stop all
	handler:StopAll(0.2)

	-- Check đang chơi
	handler:IsPlaying("Slash")

	-- Lấy AnimationTrack
	handler:GetTrack("Slash")

	-- Dọn dẹp
	handler:Destroy()
]]

--------------------------------------------------------------------------------

local Animation = {}
Animation.__index = Animation

--[[
	Tạo animation handler mới cho một Humanoid hoặc AnimationController.
	@param animator: Humanoid | AnimationController
	@return AnimationHandler
]]
function Animation.new(animator: Humanoid | AnimationController)
	assert(animator, "[AnimationHandler] Animator is nil!")

	local self = setmetatable({}, Animation)

	-- Lấy Animator từ Humanoid hoặc AnimationController
	if animator:IsA("Humanoid") then
		self._animator = animator:FindFirstChildOfClass("Animator")
			or Instance.new("Animator", animator)
	elseif animator:IsA("AnimationController") then
		self._animator = animator:FindFirstChildOfClass("Animator")
			or Instance.new("Animator", animator)
	else
		error("[AnimationHandler] Expected Humanoid or AnimationController, got: " .. animator.ClassName)
	end

	-- Cache: { [name] = { Animation = Animation, Track = AnimationTrack } }
	self._cache = {}
	self._connections = {}

	return self
end

--[[
	Load animation vào cache (nếu chưa có).
	@param name: string — Tên định danh
	@param assetId: string — rbxassetid://...
	@return AnimationTrack
]]
function Animation:Load(name: string, assetId: string): AnimationTrack
	-- Kiểm tra cache
	if self._cache[name] then
		return self._cache[name].Track
	end

	-- Tạo Animation instance
	local anim = Instance.new("Animation")
	anim.AnimationId = assetId
	anim.Name = name

	-- Load track
	local track = self._animator:LoadAnimation(anim)

	-- Lưu cache
	self._cache[name] = {
		Animation = anim,
		Track = track,
	}

	return track
end

--[[
	Play animation. Tự động load nếu chưa có trong cache.
	@param name: string — Tên định danh
	@param assetId: string — rbxassetid://...
	@param config: table? — { Speed, FadeTime, Looped, Priority, Weight }
	@return AnimationTrack
]]
function Animation:Play(name: string, assetId: string, config: {
	Speed: number?,
	FadeTime: number?,
	Looped: boolean?,
	Priority: Enum.AnimationPriority?,
	Weight: number?,
}?): AnimationTrack
	local track = self:Load(name, assetId)
	config = config or {}

	-- Cấu hình track
	if config.Looped ~= nil then
		track.Looped = config.Looped
	end

	if config.Priority then
		track.Priority = config.Priority
	end

	-- Play
	local fadeTime = config.FadeTime or 0.1
	local weight = config.Weight or 1
	local speed = config.Speed or 1

	track:Play(fadeTime, weight, speed)

	return track
end

--[[
	Stop animation theo tên.
	@param name: string
	@param fadeTime: number? — Thời gian fade out (default 0.1)
]]
function Animation:Stop(name: string, fadeTime: number?)
	local cached = self._cache[name]
	if not cached then return end

	cached.Track:Stop(fadeTime or 0.1)
end

--[[
	Stop tất cả animation đang chạy.
	@param fadeTime: number?
]]
function Animation:StopAll(fadeTime: number?)
	for _, cached in pairs(self._cache) do
		if cached.Track.IsPlaying then
			cached.Track:Stop(fadeTime or 0.1)
		end
	end
end

--[[
	Kiểm tra animation có đang chơi không.
	@param name: string
	@return boolean
]]
function Animation:IsPlaying(name: string): boolean
	local cached = self._cache[name]
	if not cached then return false end

	return cached.Track.IsPlaying
end

--[[
	Lấy AnimationTrack từ cache.
	@param name: string
	@return AnimationTrack?
]]
function Animation:GetTrack(name: string): AnimationTrack?
	local cached = self._cache[name]
	return cached and cached.Track or nil
end

--[[
	Adjust speed của animation đang chạy.
	@param name: string
	@param speed: number
]]
function Animation:SetSpeed(name: string, speed: number)
	local cached = self._cache[name]
	if not cached then return end

	cached.Track:AdjustSpeed(speed)
end

--[[
	Adjust weight của animation đang chạy.
	@param name: string
	@param weight: number
	@param fadeTime: number?
]]
function Animation:SetWeight(name: string, weight: number, fadeTime: number?)
	local cached = self._cache[name]
	if not cached then return end

	cached.Track:AdjustWeight(weight, fadeTime or 0.1)
end

--[[
	Lắng nghe event Stopped của animation.
	@param name: string
	@param callback: () -> ()
]]
function Animation:OnStopped(name: string, callback: () -> ())
	local cached = self._cache[name]
	if not cached then return end

	local conn = cached.Track.Stopped:Connect(callback)
	table.insert(self._connections, conn)

	return conn
end

--[[
	Lắng nghe KeyframeReached event.
	@param name: string
	@param callback: (keyframeName: string) -> ()
]]
function Animation:OnKeyframe(name: string, callback: (keyframeName: string) -> ())
	local cached = self._cache[name]
	if not cached then return end

	local conn = cached.Track.KeyframeReached:Connect(callback)
	table.insert(self._connections, conn)

	return conn
end

--[[
	Xóa một animation khỏi cache.
	@param name: string
]]
function Animation:Remove(name: string)
	local cached = self._cache[name]
	if not cached then return end

	if cached.Track.IsPlaying then
		cached.Track:Stop(0)
	end

	cached.Track:Destroy()
	cached.Animation:Destroy()
	self._cache[name] = nil
end

--[[
	Dọn dẹp toàn bộ handler. Gọi khi không cần nữa (VD: nhân vật chết).
]]
function Animation:Destroy()
	-- Ngắt tất cả connection
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	self._connections = {}

	-- Dọn cache
	for name, _ in pairs(self._cache) do
		self:Remove(name)
	end

	self._animator = nil

	setmetatable(self, nil)
end

return Animation
