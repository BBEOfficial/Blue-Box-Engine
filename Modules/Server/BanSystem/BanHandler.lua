--@script

local event = script.BanEvent
local event2 = script.ClientEvent
local banService = require(script.Parent:WaitForChild("BanService"))
local allowed = require(script.Allowed)

script:WaitForChild("ClientEvent").Parent = game:GetService("ReplicatedStorage")

-- creates events required
local bindable = Instance.new("BindableEvent")
local remote = Instance.new("RemoteEvent")
remote.Name = "ClientEvent"
bindable.Name = "BanEvent"
remote.Parent = script
bindable.Parent = script

game:GetService("Players").PlayerAdded:connect(function(plr)
	print("player added")
	banService.bancheck(plr)
end)

event.Event:Connect(function(plr,args)
	if allowed[plr.Name] then
		local ty,data = table.unpack(args)

		if ty == "ban" then
			--plrUid,length,reason,executor
			local plrUid,length,reason,executor = data["uid"],data["length"],data["reason"],data["executor"]
			
			if length == "" or tonumber(length) == nil then
				length = nil
			end
			
			banService.ban(table.pack(plrUid,length,reason,executor))
		end

		if ty == "unban" then
			local plrUid,executor = data["uid"],data["executor"]
			banService.unban(table.pack(plrUid,executor))
		end
	end
end)

event2.OnServerEvent:Connect(function(plr,args)
	
	print("request")
	if allowed[plr.Name] then
		print("allowed")
		local ty,data = table.unpack(args)

		if ty == "ban" then
			--plrUid,length,reason,executor
			local plrUid,length,reason,executor = data["uid"],data["length"],data["reason"],plr
			
			length = length*86400

			if length == "" or tonumber(length) == nil then
				length = nil
			end

			banService.ban(table.pack(plrUid,length,reason,executor))
		end

		if ty == "unban" then
			local plrUid,executor = data["uid"],plr
			banService.unban(table.pack(plrUid,executor))
		end
	end
end)