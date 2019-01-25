do
	local thread = love.thread.newThread("networkThread.lua")

	thread:start()

end

require("manageClients")

function love.update()
	manageClients()
end