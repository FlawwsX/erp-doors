RegisterNetEvent('echorp:playerSpawned')
AddEventHandler('echorp:playerSpawned', function(PlayerData)
	if PlayerData['source'] then
		TriggerClientEvent('erp-doors:sentDooronJoin', PlayerData['source'], doorInfo)
	end
end)

RegisterNetEvent('erp-doors:requestDoors')
AddEventHandler('erp-doors:requestDoors', function()
	TriggerClientEvent('erp-doors:sentDooronJoin', source, doorInfo)
end)

RegisterNetEvent('erp-doors:alterlockstate')
AddEventHandler('erp-doors:alterlockstate', function(num)
	if doorInfo[num]['lock'] == 1 then doorInfo[num]['lock'] = 0 elseif doorInfo[num]['lock'] == 0 then doorInfo[num]['lock'] = 1 end
	TriggerClientEvent('erp-doors:alterlockstateclient', -1, num, doorInfo[num]['lock'])
end)

RegisterNetEvent('erp-doors:forced:alterlockstate')
AddEventHandler('erp-doors:forced:alterlockstate', function(num, forcedstate)
	doorInfo[num]['lock'] = tonumber(forcedstate)
	TriggerClientEvent('erp-doors:alterlockstateclient', -1, num, doorInfo[num]['lock'])
end)

function getDoorInfo(sentDoor)
	return doorInfo[sentDoor]
end

exports('getDoorInfo', getDoorInfo)