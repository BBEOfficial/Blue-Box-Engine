--@module

-- Services
local dss = game:GetService("DataStoreService")

-- Variables
local dataStore = dss:GetGlobalDataStore("Data1")
local http = game:GetService("HttpService")
local maxretry = 4

local errorData = {"err"}
local blankData = {}

-- Other required modules
--warn("Data Store module requires, DataErrorSystem, ServerData(With SPDC)")
local DataErrorSystem
local ServerData
local s,e = pcall(function()
	DataErrorSystem = require(script.Parent:FindFirstChild("DataErrorSystem"))
	ServerData = require(script.Parent:FindFirstChild("ServerData"))
end)

local s,e = pcall(function()
	http:PostAsync("https://www.google.com")
end)

if s == true then
	warn("Http Service Enabled")
else
	warn("Http Service NOT Enabled")
	return
end

if s == false then
	warn("Missing atleast one of required modules")
	warn("Data Store module requires, DataErrorSystem, ServerData(With SPDC)")
	
	return
		
else
	warn("Data store loaded successfully")
end

-- Data store code
function set(key,data,userId)
	if key == nil or data == nil or userId == nil then
		warn("missing atleast one required value, set function datastore")
	end
	
	local retry = 0

	local s,e  = false,"just broke, set"

	repeat
		wait()
		s,e = pcall(function()
			dataStore:SetAsync(key,data)
		end)
		retry += 1
	until s == true or retry == maxretry

	if s == false then
		DataErrorSystem.senddataerror(userId,data)
		
		return false,e
	end
end

function get(key,userId)
	local retry = 0
	local d = errorData

	local s,e  = false,"just broke, get"

	repeat
		wait()
		s,e = pcall(function()
			d = dataStore:GetAsync(key)
		end)
		retry += 1
	until s == true or retry == maxretry


	if s == false then
		return d,false,e
	else
		if d == nil then
			d = blankData
		end
		
		ServerData.SetData(userId,d)
		
		return d
	end
end

local module = {}
function module.GET(key,userId)
	local d,x,a = get(key,userId)
	if x == false then
		warn("data error")
		warn(a)
		return d
	end
	return d
end
function module.POST(key,data,userId)
	if data == errorData then
		warn("error data, not saving")
		return
	end
	local x,a = set(key,data,userId)
	if x == false then
		warn("data error")
		warn(a)
	end
end
return module
