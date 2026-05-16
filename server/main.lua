AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local version = GetResourceMetadata(resource, 'version', 0)
    print('^2[' .. resource .. ']^7 v' .. version .. ' started')
end)

local function CanAccessMenu(source)
    if Config.checkAce and not IsPlayerAceAllowed(source, Config.ace) then
        return false
    end
    return true
end

RegisterNetEvent('reluctant-handling:permissions', function()
    local src = source
    if not CanAccessMenu(src) then return end
    TriggerClientEvent('reluctant-handling:open', src)
end)
