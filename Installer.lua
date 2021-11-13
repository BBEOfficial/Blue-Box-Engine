local HttpService = game:GetService("HttpService")
local USEPASTEBIN = true

local s,e = pcall(function()
	HttpService:GetAsync("https://www.google.com")
end)

if s == true then
	warn("Http Service Enabled")
else
	print(e)
	warn("Http Service NOT Enabled")
	return
end

function getDataInTable(Table,CPath)
	local paths = {}
	local currentPath = CPath
	
	for i,v in pairs(Table) do
		if typeof(v) == "table" then
			local p = getDataInTable(v,currentPath.."/"..i)
			for _,x in pairs(p) do
				table.insert(paths,x)
			end
		else
			currentPath = currentPath.."/"..v 
			table.insert(paths,currentPath.."/"..v )
			currentPath = CPath
		end
	end
	
	return paths
end

function findFiles(parent,current)
	local folders = {}
	
	for i,v in pairs(current) do
		if typeof(v) == "table" then
			local folder = Instance.new("Folder")
			folder.Name = i
			folder.Parent = parent
			table.insert(folders,folder)
			
			print("Generated "..i.." in "..parent.Name)
			
			local fMade = findFiles(folder,v)
			if fMade then
				for _,x in pairs(fMade) do
					table.insert(folders,x)
				end
			end
		end
	end
	
	return folders
end

local datatree = {}

local Http = {}
do
	function Http.getAsync(url)
		local response = HttpService:RequestAsync({
			Url = url;
			Method = "GET";
		})

		if response.Success then
			return response.Body
		else
			warn(("%d - %q - While retrieving %q"):format(response.StatusCode, response.StatusMessage, url))
			return nil
		end
	end
end

if USEPASTEBIN == true then
	datatree = HttpService:JSONDecode(Http.getAsync("https://pastebin.com/raw/UftS46ZS"))
end

local Main = {}
do
	function Main.GeneratePaths(urlPrefix)
		warn("Generating file paths")
		
		local paths = {}
		for DataName,data in pairs(datatree) do
			local exc = false
			
	
			local path = ""
			if type(DataName) == "number" then
				path = urlPrefix
				exc = true
			else
				path = urlPrefix..DataName
			end
			local currentData = data
			
			if typeof(data) == "table" then
				for i,v in pairs(data) do
					if typeof(v) == "table" then	
						print("Splitoff")
						local p = getDataInTable(v,path.."/"..i)
						for _,x in pairs(p) do
							for i = #x,1,-1 do
								if string.sub(x,i,i) == "/" then
									print("Removing extra")
									x = string.sub(x,1,i-1)
									break
								end
							end
							
							print("Path: "..x)
							
							table.insert(paths,x)
						end
					end
				end
			else
				path = path.."/"..data
				
				for i = #path,1,-1 do
					if string.sub(path,i,i) == "/" then
						print("Removing extra")
						path = string.sub(path,1,i-1)
						break
					end
				end
				
				print("Path: "..data)
				
				table.insert(paths,path.."/"..data)
				if exc == true then
					path = urlPrefix
				else
					path = urlPrefix..DataName
				end
			end
		end
		
		return paths
	end
	
	function Main.GenerateFileSystem(StartParent)
		warn("Generating file system")
		local folders = {}
		
		for i,v in pairs(datatree) do
			if typeof(v) == "table" then
				local folder = Instance.new("Folder")
				folder.Name = i
				folder.Parent = StartParent
				table.insert(folders,folder)
				
				print("Generated "..i.." in "..StartParent.Name)
				
				local fMade = findFiles(folder,v)
				if fMade then
					for _,x in pairs(fMade) do
						table.insert(folders,x)
					end
				end
			end
		end
		
		print(folders)
		return folders
	end
	
	function Main.DownloadScripts(folders,paths)
		local SCRIPTS = {}
		
		for _,path in pairs(paths) do
			local scriptName = ""
			local scriptParentName = ""
			local counter = 0
			local scN = 0
			
			for i = #path,1,-1 do
				local text = string.sub(path,i,i)
				if text == "/" then
					if counter == 0 then
						counter = 1
						scriptName = string.sub(path,i+1,#path)
						scN = i
					elseif counter == 1 then
						counter = 2
						scriptParentName = string.sub(path,i+1,scN-1)
						break
					end
				end
			end
			
			print("Downloading "..scriptName.." Path: "..path.." To: "..scriptParentName)
			
			local scriptData = Http.getAsync(path)
			local Script = nil
			
			if string.find(scriptData,"@module") then
				local MS = Instance.new("ModuleScript")
				MS.Name = string.sub(scriptName,1,#scriptName-4)
				MS.Source = scriptData
				for _,v in pairs(folders) do
					if v.Name == scriptParentName then
						MS.Parent = v
						break
					end
				end
				Script = MS
				print("Downloaded "..scriptName.." Type: Module Script")
			end
			
			table.insert(SCRIPTS,{Script,scriptData})
		end
		
		return SCRIPTS
	end
	
	function Main.PushScriptParents(scripts)
		warn("Finalizing installation")
		
		for _,v in pairs(scripts) do
			local scriptData = v[2]
			local Script = v[1]
			
			if string.find(scriptData,"@parent=") then
				local s,e = string.find(scriptData,"@parent=")
				local parentName = ""

				for i = e,#scriptData do
					if string.sub(scriptData,i,i) == "*" then
						local PN = string.sub(scriptData,e+1,i-1)
						local par = Script.Parent
						if par:FindFirstChild(PN) == nil then
							warn("Missing: "..PN.." For code parent")
						end

						Script.Parent = par:FindFirstChild(PN)
						print("Moved script to parent: "..PN)
						
						break
					end
				end
			end
		end
	end
end

local MAINFOLDER = Instance.new("Folder")
MAINFOLDER.Name = "BlueBoxEngine"
MAINFOLDER.Parent = game.ServerScriptService

local folders = Main.GenerateFileSystem(MAINFOLDER)
local paths = Main.GeneratePaths("https://raw.githubusercontent.com/JakeyWasTaken/BlueBoxEngine/main/")
local scripts = Main.DownloadScripts(folders,paths)
Main.PushScriptParents(scripts)

print([[

Blue Box Engine Downloaded.]])