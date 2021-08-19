if component == nil then
	component = require("component")
	computer = require("computer")
end
local uptime, list, pull, INVOKE = computer.uptime, component.list, computer.pullSignal, component.INVOKE
-- we actually want to ref the original pullSignal here because /lib/event intercepts it later
-- because of that, we must re-pushSignal when we use this, else things break badly
local function await(event, callback) 
	while true do
		local ev = table.pack(pull())
		if ev[1] == event then
			if callback(table.unpack(ev)) then
				break
			end
		end
	end
end

local tunnel = list("tunnel")()
INVOKE(tunnel, "send", "awake")

await("modem_message", function(_, _, from, port, _, message, code, name)
  if message == "flash" then -- Received message to flash code.
		local eeprom = list("eeprom")()
    INVOKE(eeprom, "set", code)
		if name ~= nil then
      INVOKE(eeprom, "setLabel", name)
		end
		return true
	end
end)
INVOKE(tunnel, "send", "flashed")
computer.shutdown()
