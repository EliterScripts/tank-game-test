do
	require("serverClient")
	local json = require("json")

	local clients = {}
	local receiveClientData = love.thread.getChannel("receieve-client-data")

	function manageClients()
		local remoteAddress, remotePort;
		local localAddress, localPort;
		local receiveType, message;

		local rawMessage = receiveClientData:pop()

		if(rawMessage == nil)then
			return true
		end

		local stat, err = pcall(function()
			local decoded_json = json.decode(rawMessage)

			remoteAddress = decoded_json["remoteAddress"]
			remotePort = decoded_json["remotePort"]
			localAddress = decoded_json["localAddress"]
			localPort = decoded_json["localPort"]
			receiveType = decoded_json["type"]
			message = decoded_json["message"]
			isPartial = decoded_json["isPartial"]
		end)
		if(stat == false)then
			--attempts to skip the dangerous data currently in the channel
			--do
				--local stat, err = pcall(function()
					--receiveClientData:pop()
				--end)
				--if(stat == false)then
					--return print("game.server.manageClients: could not skip data in receiveClientData, which would result in an error loop: " .. err)
				--end
			--end

			print("game.server.manageClients: could not decode information from receiveClientData channel: " .. err)
			return false
		end

		if(receiveType == "meta")then
			if(message == "connect")then
				print(
					string.format(
						"Establishing connection with client %s:%s on %s:%s...",
						remoteAddress, remotePort, localAddress, localPort
					)
				)
				do
					local client = newServerClient()
					client:setRemoteAddress(remoteAddress)
					client:setRemotePort(remotePort)
					client:setLocalAddress(localAddress)
					client:setLocalPort(localPort)
					table.insert(clients, client)
					return true
				end
			elseif(message == "disconnect")then
				print(
					string.format(
						"Disconnecting with client %s:%s on %s:%s...",
						remoteAddress, remotePort, localAddress, localPort
					)
				)

				for k, client in pairs(clients)do
					if(client:getRemoteAddress() == remoteAddress)and
							(client:getRemotePort() == remotePort)and
							(client:getLocalPort() == localPort)and
							(client:getLocalAddress() == localAddress)then
						client:close()
						table.remove(clients, k)
						return true
					end
				end
				return error("Cannot find client to disconnect!")
			end
		end



		for k, client in pairs(clients)do
			if(client ~= nil)then
				local stat, err = pcall(function()
					if(message == "getWorld")then
						client:send("world: " .. 
							json.encode(
								{"table", "of", "many", "things!"}
							) .. "\n"
						)
					end
				end)
				if(stat == false)then
					local remoteAddress, remotePort = "nil", "nil"
					pcall(function()
						remoteAddress = client:getRemoteAddress() or "nil"
						remotePort = client:getRemotePort() or "nil"
						localAddress = client:getLocalAddress() or "nil"
						localPort = client:getLocalPort() or "nil"
					end)
					return false, print(
						string.format(
							"game.server.manageClients: error sending to client %s:%s on %s:%s: %s",
							remoteAddress, remotePort, localAddress, localPort, err
						)
					)
				end
			else
				table.remove(clients, k)
			end
		end
		print("clients: " .. #clients)
	end

end