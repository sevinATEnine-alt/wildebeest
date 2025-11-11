local zones = workspace:WaitForChild("TeleportZones")

local events = game.ReplicatedStorage:WaitForChild("Events")
local zoneEvent = events:WaitForChild("ZoneEvent")

local default = {
	["owner"] = nil,
	["max"] = 1,
	["current"] = 0,
	["players"] = {},
	["created"] = false
}

local teleportZones = {
	[1] = default,
	[2] = default,
	[3] = default,
	[4] = default,
	[5] = default,
	[6] = default,
	[7] = default
}
for i, v in zones:GetChildren() do
	if not v:IsA("Model") then continue end

	for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
		b.CanTouch = true
		-- print("CanTouch: ", b.CanTouch)

	end
end

local function updatePlayerCount(zoneId, current, max)
	-- print("Zone: "..zoneId.." Current:"..current.." Max:"..max)
	game.Workspace.TeleportZones[zoneId].BillboardGui.PlayerCount.Text = current .. "/" .. max
end

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
						
						-- print("Hit from player: ", player)
						
						local zoneNumber = i
						
						-- print("Player id: ", player.UserId)
						-- print("Player list: ", teleportZones[i].players)
						if not table.find(teleportZones[i].players, player.UserId) then
							-- print("Player not in player list. Teleporting. Player: ", player)
							table.insert(teleportZones[i].players, player.UserId)

							player.Character.HumanoidRootPart.CFrame = game.Workspace.TeleportZones[i].TP.CFrame
							game.Workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Creating party..."
							
							for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
								b.CanTouch = false
								-- print("CanTouch: ", b.CanTouch)
							end
						else
							-- print("Repeated touch. Ignoring")
							return
						end
						
						if (teleportZones[i].owner == nil) then
							teleportZones[i].owner = player.UserId		
							teleportZones[i].current = 1
							print("Current:" .. teleportZones[i].current)

							-- print("New owner: ", player.UserId)
							zoneEvent:FireClient(player, "showgui")

						else
							teleportZones[i].current += 1
							print("Current:" .. teleportZones[i].current)
							-- print("Adding player: ", player)
							zoneEvent:FireClient(player, "shownothostgui")
						end
						
						updatePlayerCount(i,teleportZones[i].current, teleportZones[i].max)	
						
						if teleportZones[i].created then
							if teleportZones[i].current == teleportZones[i].max then

								for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
									b.CanTouch = false
									-- print("CanTouch: ", b.CanTouch)

								end

							else

								for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
									-- print(i, a, b)
									b.CanTouch = true
									-- print("CanTouch: ", b.CanTouch)
								end

							end
							
						end
																		
					end
				end
			end
		end)
		
	end
end

local function disband(i)
		
	teleportZones[i].owner = nil
	teleportZones[i].current = 0
	teleportZones[i].players = {}
	teleportZones[i].max = 1

	for e, v in zones:GetChildren() do
		if not v:IsA("Model") then continue end

		for a, b in game.Workspace.TeleportZones[e].Border:GetChildren() do
			b.CanTouch = true
			-- print("CanTouch: ", b.CanTouch)
		end
	end

	updatePlayerCount(i, 0, 1)


	game.Workspace.TeleportZones[i].BillboardGui.StateLabel.Text = "Waiting for players..."

	-- print(teleportZones[i])

end

zoneEvent.OnServerEvent:Connect(function(playerFired, type, amount)
	-- print(type)
	if type == "leave" then

		for i, q in teleportZones do
			if not table.find(q.players, playerFired.UserId) then continue end

			-- print(i, q, q.players, playerFired.UserId)
			
			if teleportZones[i].owner == playerFired.UserId then
				teleportZones[i].owner = 0
			end

			playerFired.Character.HumanoidRootPart.CFrame = game.Workspace.Disband.CFrame

			table.remove(teleportZones[i].players, table.find(teleportZones[i].players, playerFired.UserId))
			
			teleportZones[i].current -= 1
			print("Current: ", teleportZones[i].current)

			updatePlayerCount(i, teleportZones[i].current, teleportZones[i].max)

			-- print(teleportZones[i])
			
			if teleportZones[i].current == teleportZones[i].max then

				for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
					b.CanTouch = false
					-- print("CanTouch: ", b.CanTouch)

				end

			else

				for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
					-- print(i, a, b)
					b.CanTouch = true
					-- print("CanTouch: ", b.CanTouch)
				end

			end
			
			if teleportZones[i].current == 0 then
				teleportZones[i].created = false
				disband(i)
			end
			
			break

		end

	elseif type == "create" then
			
		-- print("Create " .. amount)
		
		for i, q in teleportZones do
			
			if q.owner ~= playerFired.UserId then continue end
		
			teleportZones[i].max = amount
			teleportZones[i].created = true
			
			if teleportZones[i].current == teleportZones[i].max then

				for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
					b.CanTouch = false
					-- print("CanTouch: ", b.CanTouch)

				end
			
			else
				
				for a, b in game.Workspace.TeleportZones[i].Border:GetChildren() do
					-- print(i, a, b)
					b.CanTouch = true
					-- print("CanTouch: ", b.CanTouch)
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
			
			
			-- Assumes this is a server script.
			local TeleportService = game:GetService("TeleportService")
			local Players = game:GetService("Players")

			-- Replace with your target Place ID
			local placeId = 92127384255319

			-- Get the list of players to teleport
			local playerList = {}
			
			for uid, player in teleportZones[i].players do
				table.insert(playerList, game.Players:GetPlayerByUserId(player))
			end
			
			-- print(playerList)

			-- Create a TeleportOptions object to specify the reserved server.
			local teleportOptions = Instance.new("TeleportOptions")
			teleportOptions.ShouldReserveServer = true

			-- Create a table for the teleport data
			local teleportData = {
				["players"] =  #teleportZones[i].players
			}

			-- Set the teleport data in the options object
			teleportOptions:SetTeleportData(teleportData)

			-- Teleport the players. The PlayerList variable is a table containing all Player objects.
			local success, result = pcall(function()
				TeleportService:TeleportAsync(placeId, playerList, teleportOptions)
			end)

			if success then
				-- print("Players teleported to a reserved server!")
			else
				warn("Teleport failed: " .. tostring(result))
			end
			
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
