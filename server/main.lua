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
