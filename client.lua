PlayerData = {}

RegisterNetEvent('echorp:playerSpawned')
AddEventHandler('echorp:playerSpawned', function(sentData) PlayerData = sentData end)

RegisterNetEvent('echorp:updateinfo')
AddEventHandler('echorp:updateinfo', function(toChange, targetData) PlayerData[toChange] = targetData end)

RegisterNetEvent('echorp:doLogout')
AddEventHandler('echorp:doLogout', function(sentData) PlayerData = {}  end)

RegisterNetEvent('erp-doors:sentDooronJoin')
AddEventHandler('erp-doors:sentDooronJoin', function(sentData) 
	for doorId=1, #sentData do
		local data = sentData[doorId]
		AddDoorToSystem(doorId, data.doorType, data.coords)
		DoorSystemSetDoorState(doorId, data.lock)
		--DoorSystemSetAutomaticRate(doorId, 5.0, 0, 1)
	end
	print("All doors added to system!")
end)

RegisterNetEvent('erp-doors:updateDoor')
AddEventHandler('erp-doors:updateDoor', function(doorId, isLocked)
  DoorSystemSetDoorState(doorId, isLocked and 1 or 0)
end)

local function loadAnimDict(dict)
	RequestAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do Wait(100) end
end

AddEventHandler('dooranim', function()
	local plyPed = PlayerPedId()
	ClearPedSecondaryTask(plyPed)
	if not IsPedInAnyVehicle(plyPed, false) then
		loadAnimDict("anim@heists@keycard@") 
		TaskPlayAnim(plyPed, "anim@heists@keycard@", "exit", 8.0, 1.0, -1, 16, 0, 0, 0, 0 )
	end
	PlaySoundFromEntity(-1, "Keycard_Success", plyPed, "DLC_HEISTS_BIOLAB_FINALE_SOUNDS", 1, 5.0);
	Wait(850)
	ClearPedTasks(plyPed)
end)

local Bollards = {
	["gabz_mrpd_bollards1"] = { doorId = 66, inZone = false },
	["gabz_mrpd_bollards2"] = { doorId = 67, inZone = false },
}

exports('GetDoors', function()
  return doorInfo
end)

local function RotationToDirection(rotation)
	local adjustedRotation = 
	{ 
		x = (math.pi / 180) * rotation.x, 
		y = (math.pi / 180) * rotation.y, 
		z = (math.pi / 180) * rotation.z 
	}
	local direction = 
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), 
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function RayCastGamePlayCamera(distance)
	local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination = {  x = cameraCoord.x + direction.x * distance,  y = cameraCoord.y + direction.y * distance,  z = cameraCoord.z + direction.z * distance  }
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 1))
	return b, c, e
end

local uiPrompt = { msgtype = 1, doorNum = 0 }
local currZone
local currDoorId = 0

local function GetDoorIdFromEntity(ent)
	local Doors = DoorSystemGetActive()
	for i=1, #Doors do
		local thisDoor = Doors[i]
		if thisDoor[2] == ent then
			return thisDoor[1]
		end
	end
	return nil
end

CreateThread(function()

	while PlayerData['cid'] == nil do Wait(1000) end;

	exports["erp-polyzone"]:AddBoxZone("gabz_mrpd_bollards1", vector3(411.66, -1027.95, 29.24), 7.8, 23.4, {
		heading=0,
		minZ=28.14,
		maxZ=32.14,
		debugPoly = false
	})

	exports["erp-polyzone"]:AddBoxZone("gabz_mrpd_bollards2", vector3(411.66, -1020.09, 29.34), 7.8, 23.4, {
		heading=0,
		minZ=28.14,
		maxZ=32.14,
		debugPoly = false
	})

	while true do
		Wait(500)
		if PlayerData['cid'] then
			local found = false

			if currZone and Bollards[currZone].inZone then
				currDoorId = Bollards[currZone].doorId
				found = true
				local state = DoorSystemGetDoorState(currDoorId)
				if (uiPrompt['msgtype'] ~= state) or (uiPrompt['doorNum'] ~= currDoorId) then
					uiPrompt = { msgtype = state, doorNum = currDoorId }
					if uiPrompt['msgtype'] == 1 then
						TriggerEvent('erp-prompts:ShowUI', 'show', '[E] Locked ('..currDoorId..')')
					else
						TriggerEvent('erp-prompts:ShowUI', 'show', '[E] Unlocked ('..currDoorId..')')
					end
				end
			else
				local hit, coords, entity = RayCastGamePlayCamera(30.0)
				local entType = GetEntityType(entity)
				if hit and entType == 3 then
					local doorId = GetDoorIdFromEntity(entity)
					if doorId then
						local distAdjust = doorInfo[doorId]['distAdjust'] or 0.0						
						local dist = (#(GetEntityCoords(PlayerPedId()) - coords)) - distAdjust
						if dist < 1.5 then
							currDoorId = doorId
							found = true
							local state = DoorSystemGetDoorState(doorId)
							if (uiPrompt['msgtype'] ~= state) or (uiPrompt['doorNum'] ~= doorId) then
								uiPrompt = { msgtype = state, doorNum = doorId }
								if uiPrompt['msgtype'] == 1 then
									TriggerEvent('erp-prompts:ShowUI', 'show', '[E] Locked ('..doorId..')')
								else
									TriggerEvent('erp-prompts:ShowUI', 'show', '[E] Unlocked ('..doorId..')')
								end
							end
						end
					end
				end

				if not found then
					if uiPrompt['doorNum'] ~= 0 then
						TriggerEvent('erp-prompts:HideUI')
						uiPrompt = { msgtype = 1, doorNum = 0 }
					end
					currDoorId = 0
				end
			end
		end
	end
end)

local function OpenCheck(curClosestNum)
	local WantedJob = doorInfo[curClosestNum]["job"]
	local currJob = PlayerData['job']['name']
	local yatype = type(WantedJob)


	if curClosestNum == 467 then
		if exports['erp-inventory']:hasEnoughOfItem('fsm_keycard', 1, false) then
			return true
		else
			return false
		end
	end

	if yatype == 'string' then
		return WantedJob == currJob
	elseif yatype == 'table' then
		local found = false
		for i=1, #WantedJob do 
			if WantedJob[i] == currJob then
				found = true
				break
			end
		end
		return found
	end
end

AddEventHandler('echorp:maincontrol', function()
	if currDoorId ~= 0 then
		if OpenCheck(currDoorId) then
			TriggerEvent('dooranim')
			local type = doorInfo[currDoorId]['doorType']
			if type == `gabz_mrpd_bollards2` or type == `gabz_mrpd_bollards1` then
				TriggerServerEvent('erp-sounds:PlayWithinDistance', 1.5, 'beep', 0.4)
			end
			TriggerServerEvent('erp-doors:alterlockstate', currDoorId)
		end
	end
end)

exports('GetDoorInfo', function(sentId)
	if sentId and doorInfo[sentId] then return doorInfo[sentId]  end
end)

AddEventHandler("erp-polyzone:enter", function(zone, data)
	if zone == "gabz_mrpd_bollards1" or zone == "gabz_mrpd_bollards2" then
		Bollards[zone].inZone = true
		currZone = zone
	end
end)

AddEventHandler("erp-polyzone:exit", function(zone)
	if zone == "gabz_mrpd_bollards1" or zone == "gabz_mrpd_bollards2" then
		Bollards[zone].inZone = false
		currZone = nil
	end
end)

RegisterNetEvent("erp-doors:alterlockstateclient")
AddEventHandler("erp-doors:alterlockstateclient", function(value, lockstatus) 
	doorInfo[value]['lock'] = lockstatus
	DoorSystemSetDoorState(value, lockstatus)
end)