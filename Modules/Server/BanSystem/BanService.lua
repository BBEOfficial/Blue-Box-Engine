-- @module

local dataStore = nil
local http = game:GetService("HttpService")
local players = game:GetService("Players")
local debugg = require(script.debug)
local contentProvider = game:GetService("ContentProvider")
local connectionid = "{992A18B6-89DF-40E1-B869-FA2E42EB2C77}"

local webhooks = {
	["Audit"] = "https://discord.com/api/webhooks/801209772371214396/Mv3NGpqkFSiFCdTP3od5oqP03_FnG5irYsj8HOURJ2AVFC4Ml_rYPpWZa3yz-AtA81hj";
}

local DataStoreKey = "keykey"
local defaultBanLength = 31536000


print("loading ban service")

dataStore = nil

for _,v in pairs(game:GetDescendants()) do
	if v:IsA("ModuleScript") and v.Name == "DataStore" then
		dataStore = require(v)
	end
end

if dataStore == nil then
	warn("Missing data store")
	return
end

function banTimeCalc(banInfo)
	local banLen = banInfo["banLength"]
	local banStart = banInfo["banStart"]
	
	local timeOfUnban = banStart+banLen
	local T = os.time()
	
	if T >= timeOfUnban then
		return false
	else
		local timeleft = (timeOfUnban - T) / 86400
		return true,math.ceil(timeleft)
	end
end

function SendInfo(...)
	local webName,data = table.unpack(...)
	local hook = webhooks[webName]

	data = http:JSONEncode(data)
	http:PostAsync(hook,data)

	warn("Data sent to webhook, last 3 digits: "..string.sub(hook,string.len(hook)-2,string.len(hook)))
end

function sendbanaudit(...)
	local reason,userid,executor = table.unpack(...)
	
	local t = http:GetAsync("http://worldclockapi.com/api/json/utc/now",true)
	t = http:JSONDecode(t)

	local data_embed = {
		["embeds"] = {
			{
				["color"] = tonumber(0xFF3E3E),
				["title"] = reason,
				["url"] = "https://www.roblox.com/users/"..tostring(userid).."/profile",
				["author"] = {
					["name"] = "GAME - "..tostring(userid),
					["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..userid.."&width=100&height=100&format=png"
				},
				["description"] = "Player banned - By: "..executor.Name,
				["footer"] = {
					["text"] = tostring(t["currentDateTime"].." - UTC")
				}
			}
		}
	}
	
	SendInfo(table.pack("Audit",data_embed))
end

function sendunbanaudit(...)
	local userid,executor = table.unpack(...)

	local t = http:GetAsync("http://worldclockapi.com/api/json/utc/now",true)
	t = http:JSONDecode(t)

	local data_embed = {
		["embeds"] = {
			{
				["color"] = tonumber(0xFF3E3E),
				["title"] = "Unbanned",
				["url"] = "https://www.roblox.com/users/"..tostring(userid).."/profile",
				["author"] = {
					["name"] = "GAME - "..tostring(userid),
					["icon_url"] = "https://www.roblox.com/headshot-thumbnail/image?userId="..userid.."&width=100&height=100&format=png"
				},
				["description"] = "Player unbanned - By: "..executor.Name,
				["footer"] = {
					["text"] = tostring(t["currentDateTime"].." - UTC")
				}
			}
		}
	}

	SendInfo(table.pack("Audit",data_embed))
end

print("ban service loaded")


local module = {}
function module.bancheck(plr)
	print("ban check called")
	local data = nil
	local dataKey = script:GetAttribute("datastoreKey")
	local retrys = 0

	repeat
		data = dataStore.GET(dataKey..plr.UserId)
		retrys += 1
	until data ~= {"err"} or retrys == 4
	
	if data == {"err"} then
		plr:Kick("Terribly sorry but we failed to gather your data! Please rejoin.")
	end
	local fullData = data
	data = data["banInfo"]
	if data["isBanned"] == true then
		warn("player is banned!")
		local a,b = banTimeCalc(data)

		local reason,executor = data["reason"],data["exectutor"]

		if a == true then
			local x = [[
			
					You're banned,
					you will be unbanned in: ]]..b..[[ days,
					for the reason: ]]..data["reason"]..[[ 
					by the admin: ]]..data["executor"]..[[
					
					or you can appeal in the discord.]]

			plr:Kick(x)
		else
			fullData["banInfo"] = {
				["isBanned"] = false;
				["banLength"] = 0;
				["banStart"] = 0;
				["reason"] = "";
				["exectutor"] = nil;
			}

			local encode = http:JSONEncode(fullData)
			fullData = http:JSONDecode(encode)

			local retryb = 0
			local postInfo = nil
			repeat
				postInfo = dataStore.POST(dataKey..plr.UserId,fullData)
				retryb += 1
			until postInfo ~= {"err"} or retryb == 4

			if postInfo == {"err"} then
				plr:Kick("Failed to unban, please rejoin so we can try again, if this persists send a screenshot of this message to one of the mods in the discord. {"..math.sin(plr.UserId*15+(plr.UserId/2)).."}")
				return
			end
		end
	end
end

function module.ban(...)
	local plrUid,length,reason,executor = table.unpack(...)
	local dataKey = DataStoreKey
	local plrName = nil
	
	local s,e = pcall(function()
	plrName = players:GetNameFromUserIdAsync(plrUid)
	end)
	
	if s == false then
		warn("player does not exist")
		debugg.sendDebug(table.pack(executor,"Player does not exist.","6328819715",connectionid))
		return 
	end
	
	if length == nil then
		length = script:GetAttribute("defaultBanLength")
	end
	
	local oldData = nil
	local retrys = 0
	
	repeat
		oldData = dataStore.GET(dataKey..plrUid)
		retrys += 1
	until oldData ~= {"err"} or retrys == 4
	
	if oldData == {"err"} then
		warn("Getting the data errored")
		debugg.sendDebug(table.pack(executor,"Getting the data errored, please retry.","6328819715",connectionid))
		return
	end
	
	oldData["banInfo"] = {
		["isBanned"] = true;
		["banLength"] = math.ceil(length);
		["banStart"] = math.ceil(os.time());
		["reason"] = reason;
		["executor"] = executor.Name;
	}
	
	local encode = http:JSONEncode(oldData)
	oldData = http:JSONDecode(encode)
	
	local retryb = 0
	local postInfo = nil
	repeat
		postInfo = dataStore.POST(dataKey..plrUid,oldData)
		retryb += 1
	until postInfo ~= {"err"} or retryb == 4
	
	if postInfo == {"err"} then
		warn("Saving the data errored")
		debugg.sendDebug(table.pack(executor,"Saving the data errored, please retry.","6328819715",connectionid))
		return
	end
	
	debugg.sendDebug(table.pack(executor,"The player ("..plrName..") has been banned for "..math.ceil(length/86400).." day(s).","1682537711",connectionid))
	sendbanaudit(table.pack(reason,plrUid,executor))
	
	if game:GetService("Players"):FindFirstChild(plrName) then
		game:GetService("Players"):FindFirstChild(plrName):Kick()
	end
	return
end

function module.unban(...)
	local plrUid,executor = table.unpack(...)
	local dataKey =	DataStoreKey
	local plrName = nil
	
	local s,e = pcall(function()
		plrName = players:GetNameFromUserIdAsync(plrUid)
	end)

	if s == false then
		warn("player does not exist")
		debugg.sendDebug(table.pack(executor,"Player does not exist.","6328819715",connectionid))
		return 
	end
	
	local oldData = nil
	local retrys = 0

	repeat
		oldData = dataStore.GET(dataKey..plrUid)
		retrys += 1
	until oldData ~= {"err"} or retrys == 4

	if oldData == {"err"} then
		warn("Getting the data errored")
		debugg.sendDebug(table.pack(executor,"Getting the data errored, please retry.","6328819715",connectionid))
		return
	end
	
	oldData["banInfo"] = {
		["isBanned"] = false;
		["banLength"] = 0;
		["banStart"] = 0;
		["reason"] = "";
		["exectutor"] = nil;
	}
	
	local encode = http:JSONEncode(oldData)
	oldData = http:JSONDecode(encode)
	
	local retryb = 0
	local postInfo = nil
	repeat
		postInfo = dataStore.POST(dataKey..plrUid,oldData)
		retryb += 1
	until postInfo ~= {"err"} or retryb == 4

	if postInfo == {"err"} then
		warn("Saving the data errored")
		debugg.sendDebug(table.pack(executor,"Saving the data errored, please retry.","6328819715",connectionid))
		return
	end
	
	debugg.sendDebug(table.pack(executor,"The player ("..plrName..") has been unbanned.","1682537711",connectionid))
	sendunbanaudit(table.pack(plrUid,executor))
	return
end
return module
