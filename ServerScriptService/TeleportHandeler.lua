-- Declare variables
local zones = workspace:WaitForChild("TeleportZones")

local events = game.ReplicatedStorage:WaitForChild("Events")
local zoneEvent = events:WaitForChild("ZoneEvent")

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

-- Table of zones and their properties
local teleportZones = {
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

-- Intialize the teleport zones
for i, v in zones:GetChildren() do
	if not v:IsA("Model") then continue end

	for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
		b.CanTouch = true
	end
end

-- Change the player count interface for the teleport zone
local function updatePlayerCount(zoneId, current, max)
	game.Workspace.TeleportZones[zoneId].BillboardGui.PlayerCount.Text = current .. "/" .. max
end

-- Go through everything inside the zones
for i, v in zones:GetChildren() do
	if not v:IsA("Model") then continue end
	for k, p in v.Border:GetChildren() do
		
		p.Touched:Connect(function(hit)
			if hit.Parent then
				-- Try to find a Humanoid in the parent
				local humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")

				-- If a Humanoid is found, it's a character
				if humanoid then
					-- Get the player from the character's model
					local player = game.Players:GetPlayerFromCharacter(hit.Parent)
					if player then
						
	
						local zoneNumber = i
						
						-- Checks if player isn't in the zone
						if not table.find(teleportZones[i].players, player.UserId) then
							
							table.insert(teleportZones[i].players, player.UserId)

							player.Character.HumanoidRootPart.CFrame = game.Workspace.TeleportZones[i].TP.CFrame
							game.Workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Creating party..."
							
							-- Makes all of the parts in the teleport zones uncollidable
							for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
								b.CanTouch = false
							end
						else
							return
						end
						
						-- Checks if there is an owner to the zone
						if (teleportZones[i].owner == nil) then
							teleportZones[i].owner = player.UserId		
							teleportZones[i].current = 1
							print("Current:" .. teleportZones[i].current)

							zoneEvent:FireClient(player, "showgui")

						else
							teleportZones[i].current += 1
							print("Current:" .. teleportZones[i].current)
							zoneEvent:FireClient(player, "shownothostgui")
						end
						
						updatePlayerCount(i,teleportZones[i].current, teleportZones[i].max)	
						
						-- Checks if a party is already created
						if teleportZones[i].created then
							
							-- Check if full
							if teleportZones[i].current == teleportZones[i].max then
								
								-- Makes it so you cant join
								for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
									b.CanTouch = false

								end

							else
								
								-- Allow people to join
								for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
									b.CanTouch = true
								end

							end
							
						end
																		
					end
				end
			end
		end)
		
	end
end

-- Deletes party and kicks everyone out
local function disband(i)
	
	print("Disband: "..i)
	
	teleportZones[i].owner = nil
	teleportZones[i].current = 0
	teleportZones[i].players = {}
	teleportZones[i].max = 1

	-- Make all borders interactable
	for e, v in zones:GetChildren() do
		if not v:IsA("Model") then continue end

		for a, b in game.Workspace.TeleportZones[e].Border:GetChildren() do
			b.CanTouch = true
		end
	end


	-- Set players to 0/1
	updatePlayerCount(i, 0, 1)


	game.Workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Waiting for players..."

end

-- When zoneEvent is fired
zoneEvent.OnServerEvent:Connect(function(playerFired, type, amount)
	
	-- Player leaves
	if type == "leave" then

		for i, q in teleportZones do
			if not table.find(q.players, playerFired.UserId) then continue end
			
			if teleportZones[i].owner == playerFired.UserId then
				teleportZones[i].owner = 0
			end

			playerFired.Character.HumanoidRootPart.CFrame = game.Workspace.Disband.CFrame

			table.remove(teleportZones[i].players, table.find(teleportZones[i].players, playerFired.UserId))
			
			teleportZones[i].current -= 1
			print("Current: ", teleportZones[i].current)

			updatePlayerCount(i, teleportZones[i].current, teleportZones[i].max)
			
			-- Checks if maximum players
			if teleportZones[i].current == teleportZones[i].max then

				for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
					b.CanTouch = false

				end

			else

				for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
					b.CanTouch = true
				end

			end
			
			-- Checks if players are in the zone
			if teleportZones[i].current == 0 then
				teleportZones[i].created = false
				disband(i)
			end
			
			break

		end

	-- Player creates party
	elseif type == "create" then
			
		
		for i, q in teleportZones do
			
			if q.owner ~= playerFired.UserId then continue end
		
			teleportZones[i].max = amount
			teleportZones[i].created = true
			
			-- Check if max players
			if teleportZones[i].current == teleportZones[i].max then

				for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
					b.CanTouch = false

				end
			
			else
				
				for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
					b.CanTouch = true
				end

			end
			
			updatePlayerCount(i, 1, teleportZones[i].max)
			local timeLeft = 20
			
			for t=timeLeft-3, 3, -1 do
				if not teleportZones[i].created then
					return
				end				
				game.Workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Leaving in " .. tostring(t+3) .. "..."
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
			
			local teleportData = {
				["players"] =  #teleportZones[i].players
			}
			
			
			-- Set options and teleport
			teleportOptions:SetTeleportData(teleportData)
			local success, result = pcall(function()
				TeleportService:TeleportAsync(placeId, playerList, teleportOptions)
			end)
			
			if success then
			else
				warn("Teleport failed: " .. tostring(result))
			end
			
			
			-- Last 3 seconds of loading
			for t=3, 1, -1 do
				if not teleportZones[i].created then
					return
				end
				game.Workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Leaving in " .. tostring(t) .. "..."
				task.wait(1)
			end
			teleportZones[i].created = false
			disband()			
		end
	end
end)
