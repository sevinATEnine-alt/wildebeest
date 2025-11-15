-- Declare variables
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local zones = workspace.TeleportZones

local events = ReplicatedStorage.Events
local zoneEvent = events.ZoneEvent

-- Default zone
local defaultZone = {
	["owner"] = nil,
	["max"] = 1,
	["current"] = 0,
	["players"] = {},
	["created"] = false
}

-- Change the player count interface for the teleport zone
local function updatePlayerCount(zoneId, current, max)
	game.Workspace.TeleportZones[zoneId].BillboardGui.PlayerCount.Text = current .. "/" .. max
end

local teleportZones = {}

teleportZones = {
	[1] = {
		["owner"] = nil,
		["max"] = 1,
		["current"] = 0,
		["players"] = {},
		["created"] = false
	},
	[2] = {
		["owner"] = nil,
		["max"] = 1,
		["current"] = 0,
		["players"] = {},
		["created"] = false
	},
	[3] = {
		["owner"] = nil,
		["max"] = 1,
		["current"] = 0,
		["players"] = {},
		["created"] = false
	},
	[4] = {
		["owner"] = nil,
		["max"] = 1,
		["current"] = 0,
		["players"] = {},
		["created"] = false
	},
	[5] = {
		["owner"] = nil,
		["max"] = 1,
		["current"] = 0,
		["players"] = {},
		["created"] = false
	},
	[6] = {
		["owner"] = nil,
		["max"] = 1,
		["current"] = 0,
		["players"] = {},
		["created"] = false
	},
	[7] = {
		["owner"] = nil,
		["max"] = 1,
		["current"] = 0,
		["players"] = {},
		["created"] = false
	}
}

local function canTouch(i, val)
	for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
		b.CanTouch = val
	end
end

-- Intialize the teleport zones
for i, v in zones:GetChildren() do
	if not v:IsA("Model") then continue end

	canTouch(i, true)
end

-- Go through everything inside the zones
for i, v in zones:GetChildren() do
	if not v:IsA("Model") then continue end
	for k, p in v.Border:GetChildren() do
		
		p.Touched:Connect(function(hit)
			if hit.Parent and hit.Parent:FindFirstChildWhichIsA("Humanoid") and game.Players:GetPlayerFromCharacter(hit.Parent) then

				-- If a Humanoid is found, it's a character					
				local humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
				
				-- Get the player from the character's model
				local player = Players:GetPlayerFromCharacter(hit.Parent)						
				
				-- Checks if player isn't in the zone
				if not table.find(teleportZones[i].players, player.UserId) then
					
					-- If so, add the player to the list of players in that zone
					table.insert(teleportZones[i].players, player.UserId)

					-- Teleports the player into the zone
					player.Character.HumanoidRootPart.CFrame = game.Workspace.TeleportZones[i].TP.CFrame
					game.Workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Creating party..."
					
					-- Makes all of the parts in the teleport zones uncollidable
					canTouch(i, false)
				else
					
					-- The player is in the zone, they cant exit. They have to click the leave button
					return
				end
				
				-- Checks if there is an owner to the zone
				if (teleportZones[i].owner == nil) then
					
					-- There is not an owner, make that player the new owner
					
					-- Set them as owner
					teleportZones[i].owner = player.UserId		
					teleportZones[i].current = 1
					
					-- Show them the "owner" gui
					zoneEvent:FireClient(player, "showgui")

				else
					
					-- They are not the owner, show them the normal gui
					
					teleportZones[i].current += 1
					
					zoneEvent:FireClient(player, "shownothostgui")
				end
				
				
				-- Update the player count on the billboard gui
				updatePlayerCount(i,teleportZones[i].current, teleportZones[i].max)	
				
				-- Checks if a party is already created
				if teleportZones[i].created then
					
					-- Check if max players are in the zone
					if teleportZones[i].current == teleportZones[i].max then
						
						-- If so, makes it so others cant join
						canTouch(i, false)

					else
						
						-- Otherwise, Allow other players to join
						canTouch(i, true)
					end
					
				end
																
			end
			
		end)
	end
end

-- Deletes party and kicks everyone out
local function disband(i)
	

	-- Resets the zone
	
	teleportZones[i].owner = nil
	teleportZones[i].current = 0
	teleportZones[i].players = {}
	teleportZones[i].max = 1

	-- Make all borders interactable

	canTouch(i, true)


	-- Set players to 0/1
	updatePlayerCount(i, 0, 1)


	-- Reset message
	game.Workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Waiting for players..."

end

-- When zoneEvent is fired
zoneEvent.OnServerEvent:Connect(function(playerFired, type, amount)
	
	-- Player presses leave
	if type == "leave" then
		
		-- Find which zone the player is in
		for i, q in teleportZones do
			if not table.find(q.players, playerFired.UserId) then continue end
			
			-- If they are the owner, set the owner to 0
			if teleportZones[i].owner == playerFired.UserId then
				teleportZones[i].owner = 0
			end

			-- Teleport the player to the disband part
			playerFired.Character.HumanoidRootPart.CFrame = game.Workspace.Disband.CFrame

			-- Remove them from the list of users
			table.remove(teleportZones[i].players, table.find(teleportZones[i].players, playerFired.UserId))
			
			-- Subtract 1 from the current player count
			teleportZones[i].current -= 1
			
			-- Update the gui with the player count
			updatePlayerCount(i, teleportZones[i].current, teleportZones[i].max)
			
			-- Allow players to join if not max
			canTouch(i, not (teleportZones[i].current == teleportZones[i].max))
			
			-- If there are no players, disband
			if teleportZones[i].current == 0 then
				teleportZones[i].created = false
				disband(i)
			end
			
			break

		end

	-- Player presses create
	elseif type == "create" then
			
		
		for i, q in teleportZones do
			
			-- Find player
			
			if q.owner ~= playerFired.UserId then continue end
		
			teleportZones[i].max = amount
			teleportZones[i].created = true
			
			-- Allow players to join if not max
			canTouch(i, not (teleportZones[i].current == teleportZones[i].max))
			
			-- Update the gui with the player countt
			updatePlayerCount(i, 1, teleportZones[i].max)
			
			-- Shows a countdown from 20 seconds to 1
			for t=20, 1, -1 do
				-- If anyone leaves (i.e. not created), then cancel
				if not teleportZones[i].created then
					return
				end				
				
				-- Display how many seconds left until teleport
				workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Leaving in " .. tostring(t) .. "..."
				task.wait(1)
				
			end
			
			-- Teleport
			local placeId = 92127384255319 -- Game
			local playerList = {}

			-- Add players
			for uid, player in teleportZones[i].players do
				table.insert(playerList, game.Players:GetPlayerByUserId(player))
			end
			
			-- Set options and players
			local teleportOptions = Instance.new("TeleportOptions")
			teleportOptions.ShouldReserveServer = true
			
			-- Count of players for the game to know how many
			local teleportData = {
				["players"] =  #teleportZones[i].players
			}
			
			-- Set options and teleport
			teleportOptions:SetTeleportData(teleportData)
			
			-- Try to teleport
			local success, result = pcall(function()
				TeleportService:TeleportAsync(placeId, playerList, teleportOptions)
			end)
			
			-- Checks if the the teleport was a success, and if not warns that it failed
			if success then
			else
				warn("Teleport failed: " .. tostring(result))
			end
			
			-- Delay for teleport
			task.wait(1)
			workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Teleporting..."
			
			-- Disband and reset zone
			teleportZones[i].created = false
			disband()			
		end
	end
end)
