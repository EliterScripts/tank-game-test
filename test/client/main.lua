--client!!

local host, port = "127.0.0.1", 11055
local socket = require("socket")
local server = assert(socket.tcp())

server:connect(host, port)
server:setoption('keepalive', true)
server:settimeout(0.2)
--note the newline below

while(true)do
    print("sending...")
    server:send("getWorld\n");
    print("sent.")

    while true do
        local s, status, partial = server:receive()
        print("---------------")
        print(s or partial)
        print("---------------")
        print("status: " .. tostring(status) )
        print(type(s or partial))
        break
    end
end
server:close()
