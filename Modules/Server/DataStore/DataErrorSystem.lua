--@module
--@parent=DataStore*

local http = game:GetService("HttpService")
local hasWebhookModule = false
local webhookModule = nil

local gameName = "PUT GAME NAME HERE"

local module = {}
	function module.senddataerror(userid,t)
		local user_key = nil;
		local dev_key = "Ged68BMkFKiV7Vzh6w2U_KAZR1x_dbce";
		local apiLogin = "https://pastebin.com/api/api_login.php"
		local apiPost = "https://pastebin.com/api/api_post.php"

		local apiFields = {
			["api_dev_key"] = dev_key;
			["api_user_name"] = "Databackups2";
			["api_user_password"] = "s2)qpvW(;K@!&N]9"
		}

		local a = ""
		for k, v in pairs(apiFields) do
			a = a .. ("&%s=%s"):format(
				http:UrlEncode(k),
				http:UrlEncode(v)
			)
		end

		a = a:sub(2)

		user_key = http:PostAsync(apiLogin, a, Enum.HttpContentType.ApplicationUrlEncoded, false)

		local dataFields = {
			["api_dev_key"] = dev_key;  
			["api_option"] = "paste";                                -- keep as "paste"
			["api_paste_name"] = userid.."_"..gameName;            -- paste name
			["api_paste_code"] = http:JSONEncode(t);                     -- paste content
			["api_paste_format"] = "text";                            -- paste format
			["api_paste_expire_date"] = "N";                       -- expire date        
			["api_paste_private"] = "1";                             -- 0=public, 1=unlisted, 2=private
			["api_user_key"] = user_key;                                   -- user key, if blank post as guest
		}

		local b = ""
		for i, z in pairs(dataFields) do
			b = b .. ("&%s=%s"):format(
				http:UrlEncode(i),
				http:UrlEncode(z)
			)
		end

		local pastebin_link = http:PostAsync(apiPost, b, Enum.HttpContentType.ApplicationUrlEncoded, false)

		local t = http:GetAsync("http://worldclockapi.com/api/json/utc/now",true)
		t = http:JSONDecode(t)

		local data_embed = {
			["embeds"] = {
				{
					["title"] = "Pastebin link",
					["description"] = "Data failure",
					["author"] = {
						["name"] = 	gameName.." - "..tostring(userid)
					},
					["color"] = 20991,
					["url"] = pastebin_link,
					["footer"] = {
						["text"] = tostring(t["currentDateTime"].." - GMT")
					}
				}
			}
		}
		if hasWebhookModule == true then
			local args = table.pack("Datastore",data_embed)
			webhookModule:SendInfo(args)
		end
	end
return module
