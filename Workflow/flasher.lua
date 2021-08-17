if component == nil then
	component = require("component")
	computer = require("computer")
	event = require("event")
end
local w, h
local screen = component.list("screen", true)()
local gpu = screen and component.list("gpu", true)()
if gpu then
  gpu = component.proxy(gpu)
  if not gpu.getScreen() then
    gpu.bind(screen)
  end
  -- _G.boot_screen = gpu.getScreen()
  w, h = gpu.maxResolution()
  gpu.setResolution(w, h)
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, w, h, " ")
end

local y = 1
local uptime = computer.uptime
-- we actually want to ref the original pullSignal here because /lib/event intercepts it later
-- because of that, we must re-pushSignal when we use this, else things break badly
local pull = computer.pullSignal
local last_sleep = uptime()
local function sleep(timeout)
  local deadline = uptime() + (timeout or 0)
  repeat
    pull(deadline - uptime())
  until uptime() >= deadline
end
local function print(msg)
  if gpu then
    gpu.set(1, y, msg)
    if y == h then
      gpu.copy(1, 2, w, h - 1, 0, -1)
      gpu.fill(1, h, w, 1, " ")
    else
      y = y + 1
    end
  end
  -- boot can be slow in some environments, protect from timeouts
  if uptime() - last_sleep > 1 then
    local signal = table.pack(pull(0))
    -- there might not be any signal
    if signal.n > 0 then
      -- push the signal back in queue for the system to use it
      computer.pushSignal(table.unpack(signal, 1, signal.n))
    end
    last_sleep = uptime()
  end
end

local tunnel = component.proxy(component.list("tunnel")())
tunnel.send("awake")

while true do
	local _, _, from, port, _, message, code, name = computer.pullSignal(nil, "modem_message")
	if message == "flash" then -- Received message to flash code.
		local eeprom = component.proxy(component.list("eeprom")())
		eeprom.set(code)
		print("Code set!")
		if name ~= nil then
			eeprom.setLabel(name)
			print("Name set!")
		end
		break
	end
end
tunnel.send("flashed")
computer.shutdown()
