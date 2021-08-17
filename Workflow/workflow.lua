local shell = require("shell")
local event = require("event")
local sides = require("sides")
local filesystem = require("filesystem")
local component = require("component")
local computer = require("computer")
local os = require("os")
local arguments = shell.parse(...)
local filename = arguments[1]
local quantity = tonumber(arguments[2])
if quantity == nil then 
	quantity = 1
end
local transposer = component.transposer
local computer_side = nil
local chest_side = nil
local chest_size = nil
local cases = {
	["opencomputers:case1"] = true,
	["opencomputers:case2"] = true,
	["opencomputers:case3"] = true
}
local SIDES = { sides.north, sides.south, sides.east, sides.west }

for _, side in ipairs(SIDES) do
	local inventory_name = transposer.getInventoryName(side)
	if inventory_name ~= nil then
		if cases[inventory_name] then
			computer_side = side
		else
			chest_side = side
			chest_size = transposer.getInventorySize(side)
		end
	end
end

if (chest_side == nil) or (computer_side == nil) then
	print("You must attach a computer case and a container to the transposer")
	return 1
end

if chest_size < 2 then
	print("The container must have at least 2 slots")
	return 1
end

if chest_size < (quantity + 1) then
	print("The container must have one more slot than the number of EEPROMs you are trying to make.")
	return 1
end

local first_item = transposer.getStackInSlot(chest_side, 1)

if (first_item.name ~= "opencomputers:storage") or (first_item.damage ~= 0) then
	print("You must insert an EEPROM into the first slot of the container!")
	return 1
end

if first_item.size < quantity then
	print("You must insert at least as many EEPROMs into the first slot of the container as you are trying to make.")
	return 1
end

first_item = nil

print("Crunching Lua...")
shell.execute("crunch " .. filename)
os.sleep(0.5)
local prefix = filename:sub(1, filename:len() - 4)
local new_filename = shell.resolve(prefix .. ".cr.lua")
local crunched_file = filesystem.open(new_filename)
local code_string = ""
while true do
	local next_chunk = crunched_file:read(1000)
	if next_chunk == nil then
		break
	end
	code_string = code_string .. next_chunk
end
print("Lua crunched!")
local current = 0
while current < quantity do
	current = current + 1;
	print("Making " .. current .. "/" .. quantity)
	print("Waking up secondary machine...")
	component.tunnel.send("wakeup")
	while true do
		local _, _, from, port, _, message = event.pull("modem_message")
		if message == "awake" then
			print("Second machine woken! Swapping EEPROM...")
			break
		end
	end
	component.transposer.transferItem(computer_side, chest_side, 1, 10, chest_size)
	os.sleep(0.5)
	component.transposer.transferItem(chest_side, computer_side, 1, 1, 10)
	os.sleep(0.5)
	print("EEPROM Swapped! Flashing...")
	component.tunnel.send("flash", code_string, "EEPROM (" .. prefix:upper() .. " BIOS)")
	while true do
		local _, _, from, port, _, message = event.pull("modem_message")
		if message == "flashed" then
			print("EEPROM flashed! Swapping EEPROMs...")
			break
		end
	end
	os.sleep(2)
	component.transposer.transferItem(computer_side, chest_side, 1, 10)
	os.sleep(0.5)
	component.transposer.transferItem(chest_side, computer_side, 1, chest_size, 10)
	os.sleep(0.5)
	print("EEPROMs Swapped!")
	os.sleep(0.5)
end
print("Done!")
