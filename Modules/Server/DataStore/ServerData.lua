--@module

local SERVER_PLAYER_DATA = require(script.SPDC)

local server = {}
	function server.SetData(userId,data)
		SERVER_PLAYER_DATA[userId] = data
		print("data updated",data)
	end

	function server.GetData(userId)
		local data_table = SERVER_PLAYER_DATA[userId]
		if not data_table then
			warn("missing data table for user: "..userId)
			return nil
		end
	
		return data_table
	end
return server