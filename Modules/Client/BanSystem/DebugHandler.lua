--@localscript
--@disabled

local startGui = game:GetService("StarterGui")
local repstore = game:GetService("ReplicatedStorage")
local debugEvent = repstore:WaitForChild("debugEvent")

debugEvent.OnClientEvent:connect(function(info)
	startGui:SetCore("SendNotification", {
		Title = info[1],
		Text = info[2],
		Icon = "rbxthumb://type=Asset&id="..info[3].."&w=150&h=150",
		Duration = 3,
	}
	)
end)