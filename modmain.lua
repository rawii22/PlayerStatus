local Widget = GLOBAL.require("widgets/widget")
local Text = GLOBAL.require("widgets/text")
local HOSTONLY = GetModConfigData("HOSTONLY")
local SCALE = GetModConfigData("SCALE")
local TheWorld --since the world won't exist until later, we must define the shortcut later

local playerData

AddPrefabPostInit("player_classified", function(player)
	TheWorld = GLOBAL.TheWorld
	player._playerDataString = GLOBAL.net_string(player.GUID, "_playerDataString", "playerdatadirty")
	
	if TheWorld.ismastersim then
		player:DoPeriodicTask(30 * GLOBAL.FRAMES, function() RefreshText(player) end)
	elseif IsEnabled() then  --taking advantage of the ismastersim check in one place
		player:ListenForEvent("playerdatadirty", RefreshClientText, player)
	end
end)

--creates and formats text properties
AddSimPostInit(function()
	if IsEnabled() then
		CreateText()
		
		local startPos = CalcBasePos()
		playerData:SetPosition(startPos)--(3600,900,0)
		playerData:SetHAlign(GLOBAL.ANCHOR_RIGHT)
		playerData:SetAlpha(.7)
	end
end)

function CreateText()
	playerData = Text("stint-ucr", SCALE, GetPlayerData())
end

--for testing. calculated using the points from the config options using Desmos
function GLOBAL.ChangeScale(playercount)
	local size = 682.827/playercount + 1.8269
	playerData:SetSize(size)
end

function RefreshText(player)
	local data = GetPlayerData()
	playerData:SetString(data)
	playerData:SetPosition(CalcBasePos())
	player._playerDataString:set(data)
end

function RefreshClientText(player)
	local data = player._playerDataString:value()
	playerData:SetString(data)
	playerData:SetPosition(CalcBasePos())
end

--only run on the host and then sent to the client via netvar in the prefab post init
function GetPlayerData()
	local data = "Press \"\\\" to close\n"
	--[[
	for k=1, 100 do
		data = data..k.."\n"
	end]]
	for k,player in pairs(GLOBAL.AllPlayers) do
		data = data..k..": "..player.name
		.." | creative: "..tostring(player.components.builder.freebuildmode)
		.." | godmode: "..tostring(player.components.health.invincible).."\n"
		.."hunger: "..math.floor(player.components.hunger.current+0.5)
		.."  sanity: "..math.floor(player.components.sanity.current+0.5)
		.."  health: "..(player:HasTag("playerghost") and "0 (dead)" or math.floor(player.components.health.currenthealth+0.5)).."\n"
	end
	return data
end

--must use proportions instead of coordinates since we won't know the screen size.
function CalcBasePos()
	local screensize = {GLOBAL.TheSim:GetScreenSize()}
	local playerDataSize = {playerData:GetRegionSize()}
	local marginX = screensize[1] * 0.08 --determined visually
	local marginY = screensize[2] * 0.25
	return GLOBAL.Vector3(
		(screensize[1] - playerDataSize[1]/2 - marginX),
		(screensize[2]/2 - playerDataSize[2]/2 + marginY),
		0
	)
end

--just a bunch of screen positioning math
AddClassPostConstruct("widgets/controls", function(controls)
	if IsEnabled() then
		local screensize = {GLOBAL.TheSim:GetScreenSize()}
		local rootscale = playerData:GetScale()
		local OnUpdate_base = controls.OnUpdate
		controls.OnUpdate = function(self, dt)
			OnUpdate_base(self, dt)
			local curscreensize = {GLOBAL.TheSim:GetScreenSize()}
			local currentPos = playerData:GetPosition()
			local currentScale = playerData:GetScale()
			if curscreensize[1] ~= screensize[1] or curscreensize[2] ~= screensize[2] then
				local newXScale = curscreensize[1] / screensize[1]
				local newYScale = curscreensize[2] / screensize[2]
				playerData:SetPosition(currentPos.x * newXScale, currentPos.y * newYScale, 0)
				playerData:SetScale(currentScale.x * newXScale, currentScale.y * newYScale, 0)
				screensize = curscreensize
			end
		end
	end
end)

function IsEnabled()
	return (HOSTONLY and GLOBAL.TheNet:GetIsServerAdmin()) or not HOSTONLY --for some reason, we cannot use ismastersim, so we must use a TheNet function
end

--just something that came with the AddKeyUpHandler from some other mod (don't remember which...)
function IsDefaultScreen()
	if GLOBAL.TheFrontEnd:GetActiveScreen() and GLOBAL.TheFrontEnd:GetActiveScreen().name and type(GLOBAL.TheFrontEnd:GetActiveScreen().name) == "string" and GLOBAL.TheFrontEnd:GetActiveScreen().name == "HUD" then
		return true
	else
		return false
	end
end

local toggle = "\\"
GLOBAL.TheInput:AddKeyUpHandler(
	toggle:lower():byte(), 
	function()
		if not GLOBAL.IsPaused() and IsDefaultScreen() and IsEnabled() then
			if playerData:IsVisible() then
				playerData:Hide()
			else
				playerData:Show()
			end
		end
	end
)