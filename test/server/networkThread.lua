require('love.system')

do
	local json = require("json")
	require("client")

	local receiveClientData = love.thread.getChannel("receieve-client-data")
	local sendClientData = love.thread.getChannel("send-client-data")
	local socket = require("socket")



	local running = true
	while(running)do

		local server, localAddress, localPort, clients;

		local stat, err = pcall(function()


			----------START SERVER:  -------------------------
			local function startServer()
				server = assert(socket.bind("*", 11055))
				localAddress, localPort = server:getsockname()

				server:settimeout(0.2)
				server:setoption('keepalive', true)
				print("Server socket created on " .. localAddress .. ":" .. localPort .. ".")
				clients = {}
			end
			startServer()

			while(running)do

				----------ACCEPTANCE:  -------------------------
				local function acceptNewClient()

					local client = server:accept()
					if(client ~= nil)then
						local Client = newServerClient(client, server)
						table.insert(clients, Client)
					end
				end
				acceptNewClient()


				----------SENDING:  ----------------------------
				local function sendNextInQueue()
					local rawMessage = sendClientData:pop()
			
					if(rawMessage == nil)then
						return nil
					end
			
					local remoteAddress, remotePort;
					local localAddress, localPort;
					local messageType, message;
			
					local stat, err = pcall(function()
						local jd = json.decode(rawMessage)
						remoteAddress, remotePort = jd["remoteAddress"], jd["remotePort"]
						localAddress, localPort = jd["localAddress"], jd["localPort"]
						messageType, message = jd["type"], jd["message"]
						
						for k, client in pairs(clients)do
							if(remoteAddress == client.remoteAddress)and(remotePort == client.remotePort)and
									(localAddress == client.localAddress)and(localPort == client.localPort)then
								if(messageType == "meta")and(message == "close")then
									client.client:close()
									table.remove(clients, k)
									return nil
								end
								if(messageType == "message")then
									client.client:send(message)
									return nil
								end
							end
						end
					end)
					if(stat == false)then
						print("sendNextInQueue: could not send message: " .. err)
					end
				end
				sendNextInQueue()

				----------RECEIVING:  ---------------------------
				local function receiveNext()
					for k, client in pairs(clients)do
						local full_data, s_status, partial_data = client.client:receive()
						if(s_status == "closed")then
							receiveClientData:push( json.encode({
								remoteAddress = client.remoteAddress,
								remotePort = client.remotePort,
								localAddress = client.localAddress,
								localPort = client.localPort,
								["type"] = "meta",
								["message"] = "disconnect"
							}) )
							client.client:close()
							table.remove(clients, k)
						else
							local isPartial;
							if(partial_data ~= nil)then
								isPartial = true
							end
							if(full_data ~= nil)then
								isPartial = false
							end
							receiveClientData:push( json.encode({
								remoteAddress = client.remoteAddress,
								remotePort = client.remotePort,
								localAddress = client.localAddress,
								localPort = client.localPort,
								["type"] = "message",
								["message"] = (full_data or partial_data),
								["isPartial"] = isPartial
							}) )
						end
					end
				end
				receiveNext()
				
			end
		end)
		if(stat == false)then
			print("Error while running the server: " .. err)
			print("Attempting to unbind socket (if still bound)...")

			--attempts to close TCP socket, if exists.
			local stat1, err1 = pcall(function()
				local stat2, err2 = pcall(function()
					if(server == nil)then
						print("server object does not exist.")
					else
						print("Attempting to close server object...")
						server:close()
						print("Successfully closed server object.")
					end
				end)
				if(stat2 == false )then
					print("There was a problem while attempting to close server object: " .. err2)
				end
			end)

			if(stat1 == false)then
				print("There was an error while attempting to close potential port: " .. err)
			end
		end

	end

end