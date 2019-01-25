local json = require("json")

do
	local clients = {}

	local receiveClientData = love.thread.getChannel("receieve-client-data")
	local sendClientData = love.thread.getChannel("send-client-data")

	function newServerClient()
		local client = {}
		client.packet_receive_queue = {}
		client.userData = {}

		function client:setRemoteAddress(new_address)
			self.remoteAddress = new_address
		end

		function client:getRemoteAddress()
			return self.remoteAddress
		end

		function client:setLocalAddress(new_address)
			self.localAddress = new_address
		end

		function client:getLocalAddress()
			return self.localAddress
		end

		function client:setRemotePort(new_port)
			self.remotePort = new_port
		end

		function client:getRemotePort()
			return self.remotePort
		end

		function client:setLocalPort(new_port)
			self.localPort = new_port
		end

		function client:getLocalPort()
			return self.localPort
		end

		function client:send(send_string)
			if(type(send_string) ~= "string")then
				print("client:send: argument must be a string! Ignoring this.")
				return false
			end

			local remoteAddress = self:getRemoteAddress()
			local remotePort = self:getRemotePort()
			local localAddress = self:getLocalAddress()
			local localPort = self:getLocalPort()

			sendClientData:push(
				json.encode({
					["remoteAddress"] = remoteAddress,
					["remotePort"] = remotePort,
					["localAddress"] = localAddress,
					["localPort"] = localPort,
					["type"] = "message",
					["message"] = send_string,
					["time"] = love.timer.getTime()
				})
			)
		end

		function client:close()
			local remoteAddress = self:getRemoteAddress()
			local remotePort = self:getRemotePort()
			local localAddress = self:getLocalAddress()
			local localPort = self:getLocalPort()

			print(
				string.format("closing client %s:%s on %s:%s...",
					remoteAddress, remotePort, localAddress, localPort
				)
			)

			sendClientData:push(
				json.encode({
					["remoteAddress"] = remoteAddress,
					["remotePort"] = remotePort,
					["localAddress"] = localAddress,
					["localPort"] = localPort,
					["type"] = "meta",
					["message"] = "close",
					["time"] = love.timer.getTime()
				})
			)

			self = nil
		end

		function client:addToReceiveQueue(message)
			if(type(message) == "string")then
				table.insert(self.packet_receive_queue, message)
			end
		end

		function client:readNext(soft)
			if(#self.packet_receive_queue > 0)and(nil ~= self.packet_receive_queue[1])then
				local nextPacket = self.packet_receive_queue[1]
				if(soft ~= true)then
					table.remove(self.packet_receive_queue, 1)
				end
				return nextPacket
			else
				return false
			end
		end

		function client:readAll(soft)
			if(#self.packet_receive_queue > 0)then
				local allPackets = self.packet_receive_queue
				if(soft ~= true)then
					self.packet_receive_queue = {}
				end
				return allPackets
			else
				return {}
			end
		end

		function client:setUserData(new_userData)
			if(type(new_userData) == "table")then
				self.userData = new_userData
			else
				print("client:setUserData: argument 1 must be a table.")
				return false
			end
		end

		function client:getUserData()
			if(type(self.userData) ~= "table")then
				self.userData = {}
			end
			return self.userData
		end

		function client:replaceUserData(replaceTable)
			local oldData = self:getUserData()
			if(type(replaceTable) == "table")then
				for k,v in pairs(replaceTable) do
					oldData[k] = v
				end
			else
				print("client:replaceUserData: argument 1 must be a table.")
				return false
			end
			self:setUserData(oldData)
		end

		return client
	end

end