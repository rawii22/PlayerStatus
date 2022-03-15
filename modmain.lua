local Widget = GLOBAL.require("widgets/widget")
local Text = GLOBAL.require("widgets/text")
local json = GLOBAL.json
local pcall = GLOBAL.pcall
local HOSTONLY = GetModConfigData("HOSTONLY")
local TOGGLEKEY = GetModConfigData("TOGGLEKEY")
local SHOWPENALTY = GetModConfigData("SHOWPENALTY")
local SHOWPLAYERNUMS = GetModConfigData("SHOWPLAYERNUMS")
local HIDEOWNSTATS = GetModConfigData("HIDEOWNSTATS")
local STATNUMFORMAT = GetModConfigData("STATNUMFORMAT")
local STATSTEXT = GetModConfigData("ABBREVIATESTATS")
local SCALE = GetModConfigData("SCALE")
local TheWorld --since the world won't exist until later, we must define the shortcut later
local externalPlayerList
local closeMessage = "Press \""..TOGGLEKEY.."\" to close\n"

local playerData

function IsEnabled()
	return (HOSTONLY and GLOBAL.TheNet:GetIsServerAdmin()) or not HOSTONLY --for some reason, we cannot use ismastersim, so we must use a TheNet function
end

AddPrefabPostInit("player_classified", function(player)
	TheWorld = GLOBAL.TheWorld
	--This netvar is for sending the player data from the server to clients (including the host when necessary)
	player._playerDataString = GLOBAL.net_string(player.GUID, "_playerDataString", "playerdatadirty")
	
	if IsEnabled() then  --taking advantage of the ismastersim check in one place
		player:ListenForEvent("playerdatadirty", RefreshClientText, player)
		print("player._parent: "..tostring(player._parent))
	end
end)

--creates and formats text properties
AddSimPostInit(function()
	if IsEnabled() then
		CreateText()
		
		local startPos = CalcBasePos()
		playerData:SetPosition(startPos)--(3600,900,0)
		playerData:SetHAlign(GLOBAL.ANCHOR_LEFT)
		playerData:SetAlpha(.8)

		if GLOBAL.TheWorld.ismastersim then
			if GLOBAL.TheShard:IsMaster() or GLOBAL.TheShard:IsSecondary() then
				GLOBAL.TheWorld:DoPeriodicTask(30 * GLOBAL.FRAMES, function()
					local r, result = pcall(json.encode, GetPlayerData(GLOBAL.AllPlayers, true))
					if not r then print("[Player Status] Could not encode player stat data.") end
					if result then
						SendModRPCToShard(GetShardModRPC(modname, "SendPlayerList"), nil, nil, nil, result)
					end
				end)
			else
				GLOBAL.TheWorld:DoPeriodicTask(30 * GLOBAL.FRAMES, function() RefreshText(GetPlayerData(GLOBAL.AllPlayers)) end)
			end
		end
	end
end)

function CreateText()
	playerData = Text("stint-ucr", SCALE, GetPlayerData(GLOBAL.AllPlayers))
end

--for testing. calculated using the points from the config options using Desmos
function GLOBAL.ChangeScale(playercount)
	local size = 682.827/playercount + 1.8269
	playerData:SetSize(size)
end

--update the text and then update netvar for clients. This will trigger the netvar's dirty function, RefreshClientText
function RefreshText(data)
	playerData:SetString(data)
	playerData:SetPosition(CalcBasePos())
	for k,player in pairs(GLOBAL.AllPlayers) do
		if player.player_classified then
			player.player_classified._playerDataString:set(data)
		end
	end
end

--updates the text widget for clients
function RefreshClientText(player)
	local data = player._playerDataString:value()
	playerData:SetString(data)
	playerData:SetPosition(CalcBasePos())
end

--only run on the host and then sent to the client via netvar in the prefab post init
function GetPlayerData(players, asTable)
	
	local statString = (asTable and "" or closeMessage)
	local statTable = {}
	
	for k,player in pairs(players) do
		local currentStat = (SHOWPLAYERNUMS and not asTable and k..": " or "")
		if HIDEOWNSTATS and player.GUID == GLOBAL.ThePlayer.GUID then
			currentStat = currentStat..(SHOWPLAYERNUMS and "[You]" or "")
		else
			local hungerStats = STATSTEXT.HUNGER.." "..string.gsub(STATNUMFORMAT, "%$(%w+)", 
				{
					current=(player:HasTag("playerghost") and "0" or math.floor(player.components.hunger.current+0.5)),
					maximum=player.components.hunger.max,
					percent=math.floor((player:HasTag("playerghost") and 0 or player.components.hunger.current)/player.components.hunger.max*100+0.5),
				})
			local sanityStats = " | "..STATSTEXT.SANITY.." "..string.gsub(STATNUMFORMAT, "%$(%w+)", 
				{
					current=(player:HasTag("playerghost") and "0" or math.floor(player.components.sanity.current+0.5)),
					maximum=player.components.sanity.max,
					percent=math.floor((player:HasTag("playerghost") and 0 or player.components.sanity.current)/player.components.sanity.max*100+0.5),
					
				})
			local healthStats = player.components.health and " | "..STATSTEXT.HEALTH.." "..string.gsub(STATNUMFORMAT, "%$(%w+)", 
				{
					current=(player:HasTag("playerghost") and "0" or math.floor(player.components.health.currenthealth+0.5)),
					maximum=math.floor(player.components.health.maxhealth*(1-player.components.health.penalty)+0.5),
					percent=math.floor((player:HasTag("playerghost") and 0 or player.components.health.currenthealth)/player.components.health.maxhealth*100+0.5),
				}) or ""
				
			--add age stat here later for Wanda users
			currentStat = currentStat..player.name.." ("..player.prefab..")"..(player:HasTag("playerghost") and " [DEAD]" or "")
			..((player.components.builder.freebuildmode or player.components.health.invincible) and " |" or "")
			..(player.components.builder.freebuildmode and " [Free-crafting]" or "")
			..(player.components.health.invincible and " [God-mode]" or "").."\n"
			..hungerStats
			..sanityStats..((SHOWPENALTY and player.components.sanity.penalty > 0) and " (-"..math.floor(player.components.sanity.penalty*100+0.5).."%)" or "")
			..healthStats..((SHOWPENALTY and player.components.health.penalty > 0) and " (-"..math.floor(player.components.health.penalty*100+0.5).."%)" or "").."\n"
		end
		--this is awful, we were lazy
		if asTable then
			table.insert(statTable, currentStat)
		else
			statString = statString..currentStat
		end
	end
		
	return (asTable and statTable or statString)
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

--just something that came with the AddKeyUpHandler from some other mod (don't remember which...)
function IsDefaultScreen()
	if GLOBAL.TheFrontEnd:GetActiveScreen() and GLOBAL.TheFrontEnd:GetActiveScreen().name and type(GLOBAL.TheFrontEnd:GetActiveScreen().name) == "string" and GLOBAL.TheFrontEnd:GetActiveScreen().name == "HUD" then
		return true
	else
		return false
	end
end

GLOBAL.TheInput:AddKeyUpHandler(
	TOGGLEKEY:lower():byte(), 
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

local playerList

--shardId is ID of the shard that sent the RPC
--This is what receives the list of players from the opposite shard and combines them in the proper order (overworld first, then cave players) then saves it to the netvar through RefreshText.
AddShardModRPCHandler(modname, "SendPlayerList", function(shardId, namespace, code, externalPlayerListJson)
	local r
	r, externalPlayerList = pcall(json.decode, externalPlayerListJson)
	if not r then print("Could not decode all items: "..tostring(externalPlayerListJson)) end
	if externalPlayerList then
		-- Only run if the shard calling the RPC is different from current shard
		if GLOBAL.TheShard:GetShardId() ~= tostring(shardId) then
			local playerStatString = ""
			if GLOBAL.TheShard:IsMaster() then
				playerStatString = GetPlayerData(GLOBAL.AllPlayers)
				for k, player in pairs(externalPlayerList) do
					playerStatString = playerStatString..(SHOWPLAYERNUMS and ((#GLOBAL.AllPlayers + k)..": ") or "").."**"..player --the "**" indicates players in caves
				end
			else
				playerStatString = closeMessage
				for k, player in pairs(externalPlayerList) do
					playerStatString = playerStatString..(SHOWPLAYERNUMS and (k..": ") or "")..player
				end
				for k, player in pairs(GetPlayerData(GLOBAL.AllPlayers, true)) do
					playerStatString = playerStatString..(SHOWPLAYERNUMS and ((#externalPlayerList + k)..": ") or "").."**"..player
				end
			end
			RefreshText(playerStatString)
		end
	end
end)

-----------ADDITIONAL CONSOLE FUNCTIONS-----------

function GLOBAL.ShardRevivePlayer(playerNum)
	SendModRPCToShard(GetShardModRPC(modname, "ShardInjection"), nil, nil, nil, "AllPlayers["..playerNum.."]:PushEvent(\"respawnfromghost\")")
end

function GLOBAL.ShardRefillStats(playerNum)
	SendModRPCToShard(GetShardModRPC(modname, "ShardInjection"), nil, nil, nil, "RefillStats("..playerNum..")")
end

--This function expects to receive a player number based on what the player stat list shows (aka the server's version of AllPlayers)
function GLOBAL.RefillStats(playerNum)
	local shardPlayerNum = playerNum
	if GLOBAL.TheShard:IsSecondary() then
		shardPlayerNum = playerNum - #externalPlayerList --if we're in the caves, subtract the number of people in the overworld
	end
	if GLOBAL.TheShard:IsMaster() and playerNum > #GLOBAL.AllPlayers then --if called from the overworld, send the function to the caves
		GLOBAL.ShardRefillStats(playerNum)
		return
	elseif GLOBAL.TheShard:IsSecondary() and shardPlayerNum <= 0 then --if called from the caves, send the function to the caves
		GLOBAL.ShardRefillStats(playerNum)
		return
	end
	if GLOBAL.TheWorld.ismastersim and GLOBAL.AllPlayers[shardPlayerNum] and not GLOBAL.AllPlayers[shardPlayerNum]:HasTag("playerghost") then
		GLOBAL.AllPlayers[shardPlayerNum].components.health:SetPenalty(0)
		GLOBAL.AllPlayers[shardPlayerNum].components.health:SetPercent(1)
		GLOBAL.AllPlayers[shardPlayerNum].components.sanity:SetPercent(1)
		GLOBAL.AllPlayers[shardPlayerNum].components.hunger:SetPercent(1)
		GLOBAL.AllPlayers[shardPlayerNum].components.temperature:SetTemperature(25)
		GLOBAL.AllPlayers[shardPlayerNum].components.moisture:SetPercent(0)
	end
end

function GLOBAL.ShardGodmode(playerNum)
	SendModRPCToShard(GetShardModRPC(modname, "ShardInjection"), nil, nil, nil, "AllPlayers["..playerNum.."].components.health.invincible = true")
end

--very dangerous RPC, which is why it's not accessible from the console
AddShardModRPCHandler(modname, "ShardInjection", function(shardId, namespace, code, injection)
	-- Only run if the shard calling the RPC is different from current shard
	if GLOBAL.TheShard:GetShardId() ~= tostring(shardId) then
		GLOBAL.ExecuteConsoleCommand(injection) --just for fun...
	end
end)