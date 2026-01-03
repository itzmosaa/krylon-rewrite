--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = {}

local function notif(...)
	return vape:CreateNotification(...)
end

run(function()
	local function dumpRemote(tab)
		local ind = table.find(tab, 'Client')
		return ind and tab[ind + 1] or ''
	end

	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function() return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9) end)
		if KnitInit then break end
		task.wait()
	until KnitInit
	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end
	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client

	bedwars = setmetatable({
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	vape:Clean(function()
		table.clear(bedwars)
	end)
end)

for _, v in vape.Modules do
	if v.Category == 'Combat' or v.Category == 'Minigames' then
		vape:Remove(i)
	end
end

run(function()
	local Sprint
	local old
	
	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = false end) end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() bedwars.SprintController:stopSprinting() end))
				bedwars.SprintController:stopSprinting()
			else
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = true end) end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
	})
end)
	
run(function()
	local AutoGamble
	
	AutoGamble = vape.Categories.Minigames:CreateModule({
		Name = 'AutoGamble',
		Function = function(callback)
			if callback then
				AutoGamble:Clean(bedwars.Client:GetNamespace('RewardCrate'):Get('CrateOpened'):Connect(function(data)
					if data.openingPlayer == lplr then
						local tab = bedwars.CrateItemMeta[data.reward.itemType] or {displayName = data.reward.itemType or 'unknown'}
						notif('AutoGamble', 'Won '..tab.displayName, 5)
					end
				end))
	
				repeat
					if not bedwars.CrateAltarController.activeCrates[1] then
						for _, v in bedwars.Store:getState().Consumable.inventory do
							if v.consumable:find('crate') then
								bedwars.CrateAltarController:pickCrate(v.consumable, 1)
								task.wait(1.2)
								if bedwars.CrateAltarController.activeCrates[1] and bedwars.CrateAltarController.activeCrates[1][2] then
									bedwars.Client:GetNamespace('RewardCrate'):Get('OpenRewardCrate'):SendToServer({
										crateId = bedwars.CrateAltarController.activeCrates[1][2].attributes.crateId
									})
								end
								break
							end
						end
					end
					task.wait(1)
				until not AutoGamble.Enabled
			end
		end,
		Tooltip = 'Automatically opens lucky crates, piston inspired!'
	})
end)
	
run(function()
    local ok, err = pcall(function()
        repeat task.wait() until vape and vape.Categories and vape.Categories.Render
        local ClanModule
        local ClanColor = Color3.new(1, 1, 1)
        local enabledFlag = false
        local EquippedTag = nil
    
        local SavedTags = {}
        local TagToggles = {}
        
        local function safeSet(attr, value)
            local lp = game.Players.LocalPlayer
            if lp and lp.SetAttribute then
                pcall(function()
                    lp:SetAttribute(attr, value)
                end)
            end
        end
        
        local function buildTag()
            if not EquippedTag then return "" end
            local hex = string.format("#%02X%02X%02X",
                ClanColor.R * 255,
                ClanColor.G * 255,
                ClanColor.B * 255
            )
            return "<font color='"..hex.."'>"..EquippedTag.."</font>"
        end
        
        local function updateClanTag()
            if enabledFlag then
                safeSet("ClanTag", buildTag())
            else
                safeSet("ClanTag", "")
            end
        end
        
        local function createTagToggles()
            for i, toggle in pairs(TagToggles) do
                if toggle and toggle.Object then
                    toggle.Object:Remove()
                end
            end
            TagToggles = {}
            
            for i, tag in ipairs(SavedTags) do
                if tag and tag ~= "" then
                    TagToggles[i] = ClanModule:CreateToggle({
                        Name = tag,
                        Function = function(callback)
                            if callback then
                                EquippedTag = tag
                                for j, otherToggle in pairs(TagToggles) do
                                    if j ~= i and otherToggle and otherToggle.Enabled then
                                        otherToggle:Toggle()
                                    end
                                end
                            else
                                if EquippedTag == tag then
                                    EquippedTag = nil
                                end
                            end
                            updateClanTag()
                        end
                    })
                end
            end
        end
        
        ClanModule = vape.Categories.Render:CreateModule({
            Name = "CustomClanTag",
            HoverText = "Click tags to equip/unequip",
            Function = function(state)
                enabledFlag = state
                if state then
                    createTagToggles()
                end
                updateClanTag()
            end
        })
        
        ClanModule:CreateColorSlider({
            Name = "Tag Color",
            Function = function(h, s, v)
                ClanColor = Color3.fromHSV(h, s, v)
                updateClanTag()
            end
        })
        
        local tagListObject = ClanModule:CreateTextList({
            Name = "Clan Tags",
            Placeholder = "Add tags here",
            Function = function(list)
                SavedTags = {}
                for i, tag in ipairs(list) do
                    if tag and tag ~= "" then
                        table.insert(SavedTags, tag)
                    end
                end
                
                createTagToggles()
            end
        })
        
    end)
    if not ok then
        warn("CustomClanTag error:", err)
    end
end)

run(function()
	local FalseBan
	local PlayerDropdown
	local InvisibleCharacters = {}
	local CharacterConnections = {}
	
	local function makeCharacterInvisible(character, player)
		if InvisibleCharacters[character] then return end
		
		local parts = {}
		local accessories = {}
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		
		for _, part in character:GetDescendants() do
			if part:IsA("BasePart") then
				parts[part] = {
					Transparency = part.Transparency,
					CanCollide = part.CanCollide,
					CastShadow = part.CastShadow
				}
				part.Transparency = 1
				part.CanCollide = false
				part.CastShadow = false
			elseif part:IsA("Decal") or part:IsA("Texture") then
				parts[part] = {Transparency = part.Transparency}
				part.Transparency = 1
			elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
				parts[part] = {Enabled = part.Enabled}
				part.Enabled = false
			elseif part:IsA("Accessory") then
				accessories[part] = {
					Accessory = part,
					Parent = part.Parent
				}
				part.Parent = nil
			end
		end
		
		if humanoid and humanoid.RootPart then
			parts[humanoid.RootPart] = parts[humanoid.RootPart] or {}
			parts[humanoid.RootPart].Transparency = 1
			humanoid.RootPart.Transparency = 1
			humanoid.RootPart.CanCollide = false
		end
		
		InvisibleCharacters[character] = {
			Parts = parts,
			Accessories = accessories,
			Player = player,
			Connections = {}
		}
		
		local connections = InvisibleCharacters[character].Connections
		
		table.insert(connections, character.DescendantAdded:Connect(function(descendant)
			task.wait()
			if FalseBan.Enabled and InvisibleCharacters[character] then
				if descendant:IsA("BasePart") then
					descendant.Transparency = 1
					descendant.CanCollide = false
					descendant.CastShadow = false
				elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
					descendant.Transparency = 1
				elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
					descendant.Enabled = false
				elseif descendant:IsA("Accessory") then
					local data = {
						Accessory = descendant,
						Parent = descendant.Parent
					}
					InvisibleCharacters[character].Accessories[descendant] = data
					descendant.Parent = nil
				end
			end
		end))
		
		table.insert(connections, character.AncestryChanged:Connect(function(_, parent)
			if parent == nil then
				restoreCharacterVisibility(character)
			end
		end))
		
		if humanoid then
			table.insert(connections, humanoid.Died:Connect(function()
				task.wait(2)
				restoreCharacterVisibility(character)
			end))
		end
	end
	
	local function restoreCharacterVisibility(character)
		if not InvisibleCharacters[character] then return end
		
		local data = InvisibleCharacters[character]
		
		for part, properties in data.Parts do
			if part and part.Parent then
				if part:IsA("BasePart") then
					part.Transparency = properties.Transparency or 0
					part.CanCollide = properties.CanCollide ~= nil and properties.CanCollide or true
					part.CastShadow = properties.CastShadow ~= nil and properties.CastShadow or true
				elseif part:IsA("Decal") or part:IsA("Texture") then
					part.Transparency = properties.Transparency or 0
				elseif part:IsA("ParticleEmitter") or part:IsA("Trail") then
					part.Enabled = properties.Enabled ~= nil and properties.Enabled or true
				end
			end
		end
		
		for accessory, accessoryData in data.Accessories do
			if accessory and accessoryData.Parent then
				accessory.Parent = accessoryData.Parent
			end
		end
		
		for _, connection in data.Connections do
			pcall(function()
				connection:Disconnect()
			end)
		end
		
		InvisibleCharacters[character] = nil
	end
	
	local function getPlayerList()
		local playerList = {}
		
		for _, player in playersService:GetPlayers() do
			if player ~= lplr then
				table.insert(playerList, player.Name)
			end
		end
		
		table.sort(playerList)
		return playerList
	end
	
	local function setupPlayerConnections(player)
		if CharacterConnections[player] then return end
		
		local connections = {}
		
		table.insert(connections, player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			if FalseBan.Enabled and PlayerDropdown.Value == player.Name then
				makeCharacterInvisible(character, player)
			end
		end))
		
		table.insert(connections, player.CharacterRemoving:Connect(function(character)
			restoreCharacterVisibility(character)
		end))
		
		CharacterConnections[player] = connections
	end
	
	local function processSelectedPlayer()
		if PlayerDropdown.Value and PlayerDropdown.Value ~= "" then
			local player = playersService:FindFirstChild(PlayerDropdown.Value)
			if player and player.Character then
				makeCharacterInvisible(player.Character, player)
			end
		end
	end
	
	FalseBan = vape.Categories.Render:CreateModule({
		Name = 'FalseBan',
		Function = function(callback)
			if callback then
				for _, player in playersService:GetPlayers() do
					if player ~= lplr then
						setupPlayerConnections(player)
					end
				end
				
				FalseBan:Clean(playersService.PlayerAdded:Connect(function(player)
					if player == lplr then return end
					
					setupPlayerConnections(player)
					
					if player.Character and FalseBan.Enabled and PlayerDropdown.Value == player.Name then
						task.wait(0.5)
						makeCharacterInvisible(player.Character, player)
					end
				end))
				
				FalseBan:Clean(playersService.PlayerRemoving:Connect(function(player)
					if CharacterConnections[player] then
						for _, connection in CharacterConnections[player] do
							pcall(function()
								connection:Disconnect()
							end)
						end
						CharacterConnections[player] = nil
					end
					
					if player.Character then
						restoreCharacterVisibility(player.Character)
					end
				end))
				
				processSelectedPlayer()
				
			else
				for character, _ in InvisibleCharacters do
					restoreCharacterVisibility(character)
				end
				table.clear(InvisibleCharacters)
				
				for player, connections in CharacterConnections do
					for _, connection in connections do
						pcall(function()
							connection:Disconnect()
						end)
					end
				end
				table.clear(CharacterConnections)
			end
		end,
		Tooltip = 'Select a player to make invisible client-side only.'
	})
	
	PlayerDropdown = FalseBan:CreateDropdown({
		Name = 'Select Player',
		List = getPlayerList(),
		Function = function(val)
			if FalseBan.Enabled then
				FalseBan:Toggle()
				FalseBan:Toggle()
			end
		end
	})
end)

shared.slowmode = 0
run(function()
    local HttpService = game:GetService("HttpService")
    local StaffDetectionSystem = {
        Enabled = false
    }
    local StaffDetectionSystemConfig = {
        GameMode = "Bedwars",
        CustomGroupEnabled = false,
        IgnoreOnline = false,
        AutoCheck = false,
        MemberLimit = 50,
        CustomGroupId = "",
        CustomRoles = {}
    }
    local StaffDetectionSystemStaffData = {
        Games = {
            Bedwars = {groupId = 5774246, roles = {79029254, 86172137, 43926962, 37929139, 87049509, 37929138}},
            PS99 = {groupId = 5060810, roles = {33738740, 33738765}}
        },
        Detected = {}
    }

    local DetectionUtils = {
        resetSlowmode = function() end,
        fetchUsersInRole = function() end,
        fetchUserPresence = function() end,
        fetchGroupRoles = function() end,
        getDetectionConfig = function() end,
        scanStaff = function() end
    }

    DetectionUtils = {
        resetSlowmode = function()
            task.spawn(function()
                while shared.slowmode > 0 do
                    shared.slowmode = shared.slowmode - 1
                    task.wait(1)
                end
                shared.slowmode = 0
            end)
        end,

        fetchUsersInRole = function(groupId, roleId, cursor)
            local url = string.format("https://groups.roblox.com/v1/groups/%d/roles/%d/users?limit=%d%s", groupId, roleId, StaffDetectionSystemConfig.MemberLimit, cursor and "&cursor=" .. cursor or "")
            local success, response = pcall(function()
                return request({Url = url, Method = "GET"})
            end)
            return success and HttpService:JSONDecode(response.Body) or {}
        end,

        fetchUserPresence = function(userIds)
            local success, response = pcall(function()
                return request({
                    Url = "https://presence.roblox.com/v1/presence/users",
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = HttpService:JSONEncode({userIds = userIds})
                })
            end)
            return success and HttpService:JSONDecode(response.Body) or {userPresences = {}}
        end,

        fetchGroupRoles = function(groupId)
            local success, response = pcall(function()
                return request({
                    Url = "https://groups.roblox.com/v1/groups/" .. groupId .. "/roles",
                    Method = "GET"
                })
            end)
            if success and response.StatusCode == 200 then
                local roles = {}
                for _, role in pairs(HttpService:JSONDecode(response.Body).roles) do
                    table.insert(roles, role.id)
                end
                return true, roles
            end
            return false, nil, "Failed to fetch roles: " .. (success and response.StatusCode or "Network error")
        end,

        getDetectionConfig = function()
            if StaffDetectionSystemConfig.CustomGroupEnabled then
                if not StaffDetectionSystemConfig.CustomGroupId or StaffDetectionSystemConfig.CustomGroupId == "" then
                    return false, nil, "Custom Group ID not specified", false, nil, "Custom"
                end
                if #StaffDetectionSystemConfig.CustomRoles == 0 then
                    return true, tonumber(StaffDetectionSystemConfig.CustomGroupId), nil, false, nil, "Custom roles not specified"
                end
                local success, roles, error = DetectionUtils.fetchGroupRoles(StaffDetectionSystemConfig.CustomGroupId)
                return true, tonumber(StaffDetectionSystemConfig.CustomGroupId), nil, success, roles, error, "Custom"
            else
                local gameData = StaffDetectionSystemStaffData.Games[StaffDetectionSystemConfig.GameMode]
                return true, gameData.groupId, nil, true, gameData.roles, nil, "Normal"
            end
        end,

        scanStaff = function(groupId, roleId)
            local users, userIds = {}, {}
            local cursor = nil
            repeat
                local data = DetectionUtils.fetchUsersInRole(groupId, roleId, cursor)
                for _, user in pairs(data.data or {}) do
                    table.insert(users, user)
                    table.insert(userIds, user.userId)
                end
                cursor = data.nextPageCursor
            until not cursor

            local presenceData = DetectionUtils.fetchUserPresence(userIds)
            for _, user in pairs(users) do
                for _, presence in pairs(presenceData.userPresences) do
                    if user.userId == presence.userId then
                        user.presenceType = presence.userPresenceType
                        user.lastLocation = presence.lastLocation
                        break
                    end
                end
            end
            return users
        end
    }

    local function processStaffCheck()
        if shared.slowmode > 0 and not StaffDetectionSystemConfig.AutoCheck then
            notif("StaffDetector", "Slowmode active! Wait " .. shared.slowmode .. " seconds", shared.slowmode)
            return
        end

        shared.slowmode = 5
        DetectionUtils.resetSlowmode()
        notif("StaffDetector", "Checking staff presence...", 5)

        local groupSuccess, groupId, groupError, rolesSuccess, roles, rolesError, mode = DetectionUtils.getDetectionConfig()
        if not groupSuccess or not rolesSuccess then
            shared.slowmode = 0
            if groupError then notif("StaffDetector", groupError, 5) end
            if rolesError then notif("StaffDetector", rolesError, 5) end
            return
        end

        local detectedStaff, uniqueIds = {}, {}
        for _, roleId in pairs(roles) do
            for _, user in pairs(DetectionUtils.scanStaff(groupId, roleId)) do
				local resolve = {
					["Offline"] = '<font color="rgb(128,128,128)">Offline</font>',
					["Online"] = '<font color="rgb(0,255,0)">Online</font>',
					["In Game"] = '<font color="rgb(16, 150, 234)">In Game</font>',
					["In Studio"] = '<font color="rgb(255,165,0)">In Studio</font>'
				}
                local status = ({
                    [0] = "Offline",
                    [1] = "Online",
                    [2] = "In Game",
                    [3] = "In Studio"
                })[user.presenceType or 0]

                if (status == "In Game" or (not StaffDetectionSystemConfig.IgnoreOnline and status == "Online")) and
                   not table.find(uniqueIds, user.userId) then
                    table.insert(uniqueIds, user.userId)
                    local userData = {UserID = tostring(user.userId), Username = user.username, Status = status}
                    if not table.find(detectedStaff, userData) then
                        table.insert(detectedStaff, userData)
                        notif("StaffDetector", "@" .. userData.Username .. "(" .. userData.UserID .. ") is " .. resolve[status], 7)
                    end
                end
            end
        end
        notif("StaffDetector", #detectedStaff .. " staff members detected online/in-game!", 7)
    end

    StaffDetectionSystem = vape.Categories.Utility:CreateModule({
        Name = 'StaffFetcher - Roblox',
        Function = function(enabled)
            StaffDetectionSystem.Enabled = enabled
            if enabled then
                if StaffDetectionSystemConfig.AutoCheck then
                    task.spawn(function()
                        repeat
                            processStaffCheck()
                            task.wait(30)
                        until not StaffDetectionSystem.Enabled or not StaffDetectionSystemConfig.AutoCheck
                        StaffDetectionSystem:Toggle(false)
                    end)
                else
                    processStaffCheck()
                    StaffDetectionSystem:Toggle(false)
                end
            end
        end
    })

    local StaffDetectionSystemUI = {}

    local gameList = {}
    for game in pairs(StaffDetectionSystemStaffData.Games) do table.insert(gameList, game) end
    StaffDetectionSystemUI.GameSelector = StaffDetectionSystem:CreateDropdown({
        Name = "Game Mode",
        Function = function(value) StaffDetectionSystemConfig.GameMode = value end,
        List = gameList
    })

    StaffDetectionSystemUI.RolesList = StaffDetectionSystem:CreateTextList({
        Name = "Custom Roles",
        TempText = "Role ID (number)",
        Function = function(values) StaffDetectionSystemConfig.CustomRoles = values end
    })

    StaffDetectionSystemUI.GroupIdInput = StaffDetectionSystem:CreateTextBox({
        Name = "Custom Group ID",
        TempText = "Group ID (number)",
        Function = function(value) StaffDetectionSystemConfig.CustomGroupId = value end
    })

    StaffDetectionSystem:CreateToggle({
        Name = "Custom Group",
        Function = function(enabled)
            StaffDetectionSystemConfig.CustomGroupEnabled = enabled
            StaffDetectionSystemUI.GroupIdInput.Object.Visible = enabled
            StaffDetectionSystemUI.RolesList.Object.Visible = enabled
            StaffDetectionSystemUI.GameSelector.Object.Visible = not enabled
        end,
        Tooltip = "Use a custom staff group",
        Default = false
    })

    StaffDetectionSystem:CreateToggle({
        Name = "Ignore Online Staff",
        Function = function(enabled) StaffDetectionSystemConfig.IgnoreOnline = enabled end,
        Tooltip = "Only show in-game staff, ignoring online staff",
        Default = false
    })

    StaffDetectionSystem:CreateSlider({
        Name = "Member Limit",
        Min = 1,
        Max = 100,
        Function = function(value) StaffDetectionSystemConfig.MemberLimit = value end,
        Default = 50
    })

    StaffDetectionSystem:CreateToggle({
        Name = "Auto Check",
        Function = function(enabled)
            StaffDetectionSystemConfig.AutoCheck = enabled
            if enabled and shared.slowmode > 0 then
                notif("StaffDetector", "Disable Auto Check to use manually during slowmode!", 5)
            end
        end,
        Tooltip = "Automatically check every 30 seconds",
        Default = false
    })

    StaffDetectionSystemUI.GroupIdInput.Object.Visible = false
    StaffDetectionSystemUI.RolesList.Object.Visible = false
end)

run(function()
    local anim
	local asset
	local lastPosition
    local NightmareEmote
	NightmareEmote = vape.Categories.World:CreateModule({
		Name = "NightmareEmote",
		Function = function(call)
			if call then
				local l__GameQueryUtil__8
				if (not shared.CheatEngineMode) then 
					l__GameQueryUtil__8 = require(game:GetService("ReplicatedStorage")['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil 
				else
					local backup = {}; function backup:setQueryIgnored() end; l__GameQueryUtil__8 = backup;
				end
				local l__TweenService__9 = game:GetService("TweenService")
				local player = game:GetService("Players").LocalPlayer
				local p6 = player.Character
				
				if not p6 then NightmareEmote:Toggle() return end
				
				local v10 = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("NightmareEmote"):Clone();
				asset = v10
				v10.Parent = game.Workspace
				lastPosition = p6.PrimaryPart and p6.PrimaryPart.Position or Vector3.new()
				
				task.spawn(function()
					while asset ~= nil do
						local currentPosition = p6.PrimaryPart and p6.PrimaryPart.Position
						if currentPosition and (currentPosition - lastPosition).Magnitude > 0.1 then
							asset:Destroy()
							asset = nil
							NightmareEmote:Toggle()
							break
						end
						lastPosition = currentPosition
						v10:SetPrimaryPartCFrame(p6.LowerTorso.CFrame + Vector3.new(0, -2, 0));
						task.wait()
					end
				end)
				
				local v11 = v10:GetDescendants();
				local function v12(p8)
					if p8:IsA("BasePart") then
						l__GameQueryUtil__8:setQueryIgnored(p8, true);
						p8.CanCollide = false;
						p8.Anchored = true;
					end;
				end;
				for v13, v14 in ipairs(v11) do
					v12(v14, v13 - 1, v11);
				end;
				local l__Outer__15 = v10:FindFirstChild("Outer");
				if l__Outer__15 then
					l__TweenService__9:Create(l__Outer__15, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = l__Outer__15.Orientation + Vector3.new(0, 360, 0)
					}):Play();
				end;
				local l__Middle__16 = v10:FindFirstChild("Middle");
				if l__Middle__16 then
					l__TweenService__9:Create(l__Middle__16, TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = l__Middle__16.Orientation + Vector3.new(0, -360, 0)
					}):Play();
				end;
                anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://9191822700"
				anim = p6.Humanoid:LoadAnimation(anim)
				anim:Play()
			else 
                if anim then 
					anim:Stop()
					anim = nil
				end
				if asset then
					asset:Destroy() 
					asset = nil
				end
			end
		end
	})
end)

run(function()
    local PlayerLevelSet = {Enabled = false}
    local PlayerLevel = {Value = 100}
    local originalLevel = nil  
    
    PlayerLevelSet = vape.Categories.Utility:CreateModule({
        Name = 'SetPlayerLevel',
        Tooltip = 'Sets your player level to 100 (client sided)',
        Function = function(calling)
            if calling then                 
                if PlayerLevelSet.Enabled and not originalLevel then
                    originalLevel = game.Players.LocalPlayer:GetAttribute("PlayerLevel") or 1
                end
                
                game.Players.LocalPlayer:SetAttribute("PlayerLevel", PlayerLevel.Value)
            else
                if originalLevel then
                    game.Players.LocalPlayer:SetAttribute("PlayerLevel", originalLevel)
                    originalLevel = nil  
                end
            end
        end
    })
    
    PlayerLevel = PlayerLevelSet:CreateSlider({
        Name = 'Sets your player level(client side)',
        Function = function() 
            if PlayerLevelSet.Enabled then 
                game.Players.LocalPlayer:SetAttribute("PlayerLevel", PlayerLevel.Value) 
            end 
        end,
        Min = 1,
        Max = 1000,
        Default = 100
    })
end)

run(function()
    local SetPlayerWins = {Enabled = false}
    local WinsValue = {Value = 1000}
    local originalWins = nil
    local winsStatObject = nil
    
    local function findWinsStat()
        local leaderstats = lplr:FindFirstChild("leaderstats")
        if not leaderstats then return nil end
        
        for _, stat in pairs(leaderstats:GetChildren()) do
            if stat:IsA("IntValue") and (string.lower(stat.Name) == "wins" or 
               string.lower(stat.Name):find("win")) then
                return stat
            end
        end
    
        for _, stat in pairs(leaderstats:GetChildren()) do
            if stat:IsA("IntValue") then
                return stat
            end
        end
        
        return nil
    end
    
    SetPlayerWins = vape.Categories.Utility:CreateModule({
        Name = 'SetPlayerWins',
        Tooltip = 'Sets your wins count (client sided)',
        Function = function(calling)
            if calling then
                winsStatObject = findWinsStat()
                
                if winsStatObject then
                    originalWins = winsStatObject.Value
                    winsStatObject.Value = WinsValue.Value
                    
                    notif("SetPlayerWins", string.format("wins set to %d (client side)", WinsValue.Value), 3)
                else
                    notif("SetPlayerWins", "could not find leaderstats wins value", 5, "alert")
                    SetPlayerWins:Toggle(false)
                end
            else
                if winsStatObject and originalWins then
                    winsStatObject.Value = originalWins
                    originalWins = nil
                    winsStatObject = nil
                    
                    notif("SetPlayerWins", "Wins restored to original value", 3)
                end
            end
        end
    })
    
    WinsValue = SetPlayerWins:CreateSlider({
        Name = 'Set Wins Count',
        Tooltip = 'Sets your wins count (0-10,000)',
        Function = function()
            if SetPlayerWins.Enabled and winsStatObject then
                winsStatObject.Value = WinsValue.Value
            end
        end,
        Min = 0,
        Max = 10000,
        Default = 1000
    })
end)
