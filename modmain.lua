--[[
Authors: Alberto and Ricardo Romanach
GitHub page: https://github.com/rawii22/PlayerStatus

Notes: In order to understand some terminology in the comments, I'll describe some stuff here.
	Scenario 1: non-dedicated non-caves
	Scenario 2: non-dedicated with caves
	Scenario 3: dedicated non-caves
	Scenario 4: dedicated with caves
]]

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
--local TheWorld --since the world won't exist until later, we must define the shortcut later
local externalPlayerList
local closeMessage = "Press \""..TOGGLEKEY.."\" to close\n"

local playerData

function IsEnabled()
	return (HOSTONLY and GLOBAL.TheNet:GetIsServerAdmin()) or not HOSTONLY --for some reason, we cannot use ismastersim, so we must use a TheNet function
end

--This sets up the netvar for sending the player data from the server to clients (including the host when necessary)
--Every player with a "player_classified" will have a whole copy of the player stat list.
AddPrefabPostInit("player_classified", function(player)
	--TheWorld = GLOBAL.TheWorld
	player._playerDataString = GLOBAL.net_string(player.GUID, "_playerDataString", "playerdatadirty")
	
	if IsEnabled() then  --taking advantage of the ismastersim check in one place
		player:ListenForEvent("playerdatadirty", RefreshClientText, player)
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

		--only set up the periodic tasks on the server side
		if GLOBAL.TheWorld.ismastersim then
			--Scenario 2 and 4. Each shard will run it's own periodic task. (The IsMaster() and IsSecondary() functions will always return false if caves are not enabled)
			if GLOBAL.TheShard:IsMaster() or GLOBAL.TheShard:IsSecondary() then
				--In this periodic task, we collect the local player data and SEND it to the opposite shard via json and RPC.
				--Originally, we tried sending all the player objects themselves, but those were too ridiculously large. Json was not able to encode all the data.
				GLOBAL.TheWorld:DoPeriodicTask(30 * GLOBAL.FRAMES, function()
					local r, result = pcall(json.encode, GetPlayerData(GLOBAL.AllPlayers, true))
					if not r then print("[Player Status] Could not encode player stat data.") end
					if result then
						SendModRPCToShard(GetShardModRPC(modname, "SendPlayerList"), nil, nil, nil, result)
					end
				end)
			--Scenario 1 and 3. There is only one server to set up a periodic task for. There's no need for an RPC since there's only one shard
			else
				GLOBAL.TheWorld:DoPeriodicTask(30 * GLOBAL.FRAMES, function() RefreshText(GetPlayerData(GLOBAL.AllPlayers)) end)
			end
		end
	end
end)

function CreateText()
	playerData = Text("stint-ucr", SCALE, GetPlayerData(GLOBAL.AllPlayers))
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

--Klei is really nice and provided a way to communicate between shards with the AddShardModRPCHandler mod util.
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


--for testing. calculated using the points from the config options using Desmos
function GLOBAL.ChangeScale(playercount)
	local size = 682.827/playercount + 1.8269
	playerData:SetSize(size)
end

--This function first figures out if the target function (fn) needs to be run on another shard (based on playerNum) and then either sends it to the other shard or executes it locally
local function ExecuteOnShardWithPlayer(playerNum, fn, fnstring)
	local shardPlayerNum = playerNum
	if GLOBAL.TheShard:IsSecondary() then
		shardPlayerNum = playerNum - #externalPlayerList --if we're in the caves, subtract the number of people in the overworld
	end
	if GLOBAL.TheShard:IsMaster() and playerNum > #GLOBAL.AllPlayers then --if called from the overworld, send the function to the caves
		SendModRPCToShard(GetShardModRPC(modname, "ShardInjection"), nil, nil, nil, fnstring)
		return
	elseif GLOBAL.TheShard:IsSecondary() and shardPlayerNum <= 0 then --if called from the caves, send the function to the caves
		SendModRPCToShard(GetShardModRPC(modname, "ShardInjection"), nil, nil, nil, fnstring)
		return
	end
	--this will run locally if the target player is in the same shard as the caller
	fn(shardPlayerNum)
end

--These functions create a mini local function with the desired code, and then defers to ExecuteOnShardWithPlayer for proper execution.

function GLOBAL.RevivePlayer(playerNum)
	local function fn(playerNum)
		GLOBAL.AllPlayers[playerNum]:PushEvent("respawnfromghost")
	end
	
	ExecuteOnShardWithPlayer(playerNum, fn, "RevivePlayer("..playerNum..")")
end

function GLOBAL.RefillStats(playerNum)
	local function fn(playerNum)
		if GLOBAL.TheWorld.ismastersim and GLOBAL.AllPlayers[playerNum] and not GLOBAL.AllPlayers[playerNum]:HasTag("playerghost") then
			GLOBAL.AllPlayers[playerNum].components.health:SetPenalty(0)
			GLOBAL.AllPlayers[playerNum].components.health:SetPercent(1)
			GLOBAL.AllPlayers[playerNum].components.sanity:SetPercent(1)
			GLOBAL.AllPlayers[playerNum].components.hunger:SetPercent(1)
			GLOBAL.AllPlayers[playerNum].components.temperature:SetTemperature(25)
			GLOBAL.AllPlayers[playerNum].components.moisture:SetPercent(0)
		end
	end
	
	ExecuteOnShardWithPlayer(playerNum, fn, "RefillStats("..playerNum..")")
end

function GLOBAL.Godmode(playerNum)
	local function fn(playerNum)
		GLOBAL.c_godmode(GLOBAL.AllPlayers[playerNum])
	end
	
	ExecuteOnShardWithPlayer(playerNum, fn, "Godmode("..playerNum..")")
end

--very dangerous RPC, which is why it's not accessible from the console
AddShardModRPCHandler(modname, "ShardInjection", function(shardId, namespace, code, injection)
	-- Only run if the shard calling the RPC is different from current shard
	if GLOBAL.TheShard:GetShardId() ~= tostring(shardId) then
		GLOBAL.ExecuteConsoleCommand(injection) --just for fun...
	end
end)