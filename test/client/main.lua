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
        if(s ~= nil)or(partial == nil)or((partial == nil)and(s == nil))then
            print("breaking: complete")
            break
        end
    end
end
server:close()
