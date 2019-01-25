do
	local json = require("json")

	local clients = {}

	local receiveClientData = love.thread.getChannel("receieve-client-data")
	local sendClientData = love.thread.getChannel("send-client-data")

	function newServerClient(new_client, new_server)
		local client = {}
		client.client = new_client
		client.server = new_server
		
		local remoteAddress, remotePort = new_client:getpeername()
		local localAddress, localPort = new_server:getsockname()

		client.remoteAddress = remoteAddress
		client.remotePort = remotePort
		client.localAddress = localAddress
		client.localPort = localPort

		receiveClientData:push( json.encode({
			remoteAddress = client.remoteAddress,
			remotePort = client.remotePort,
			localAddress = client.localAddress,
			localPort = client.localPort,
			["type"] = "meta",
			["message"] = "connect"
		}) )


		return client
	end

end