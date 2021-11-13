-- @module
-- @parent=BanService*

local debugEvent = Instance.new("RemoteEvent")
debugEvent.Name = "debugEvent"
debugEvent.Parent = script

local connectionIds = {
	["{992A18B6-89DF-40E1-B869-FA2E42EB2C77}"] = "BanService"
}

debugEvent.Parent = game:GetService("ReplicatedStorage")

local module = {}
function module.sendDebug(...)
	local player,info,icon,id = table.unpack(...)
	debugEvent:FireClient(player,{connectionIds[id],info,icon})
end
return module
