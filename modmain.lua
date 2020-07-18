local Widget = GLOBAL.require("widgets/widget")
local Text = GLOBAL.require("widgets/text")

local playerData

AddSimPostInit(function()
	CreateText()
	
	local startPos = CalcBasePos()
	playerData:SetPosition(startPos)--(3600,900,0)
	playerData:SetHAlign(GLOBAL.ANCHOR_RIGHT)
	playerData:SetAlpha(.7)
	
	GLOBAL.TheWorld:DoPeriodicTask(45 * GLOBAL.FRAMES, function() RefreshText() end)
end)

function CreateText()
	playerData = Text("stint-ucr", 33, GetPlayerData())
end

function RefreshText()
	playerData:SetString(GetPlayerData())
	playerData:SetPosition(CalcBasePos())
end

function GetPlayerData()
	local data = ""
	--[[
	for k,v in pairs(table1) do
		data = data..v.."\n"
	end]]
	for k,player in pairs(GLOBAL.AllPlayers) do
		data = data..k..": "..player.name
		.." | creative: "..tostring(player.components.builder.freebuildmode)
		.." | godmode: "..tostring(player.components.health.invincible).."\n"
		.."hunger: "..math.floor(player.components.hunger.current+0.5)
		.." | sanity: "..math.floor(player.components.sanity.current+0.5)
		.." | health: "..math.floor(player.components.health.currenthealth+0.5).."\n"
	end
	return data
end

function CalcBasePos()
	local screensize = {GLOBAL.TheSim:GetScreenSize()}
	local playerDataSize = {playerData:GetRegionSize()}
	local marginX = screensize[1] * 0.08
	local marginY = screensize[2] * 0.25
	return GLOBAL.Vector3(
		(screensize[1] - playerDataSize[1]/2 - marginX),
		(screensize[2]/2 - playerDataSize[2]/2 + marginY),
		0
	)
end

AddClassPostConstruct("widgets/controls", function(controls)
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
end)