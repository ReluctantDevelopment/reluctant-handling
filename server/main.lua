local RESOURCE = GetCurrentResourceName()
local VERSION  = GetResourceMetadata(RESOURCE, 'version', 0)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= RESOURCE then return end

    print('^5[reluctant-handling]^7 v' .. VERSION .. ' started')

    PerformHttpRequest(
        'https://api.github.com/repos/ReluctantDevelopment/reluctant-handling/releases/latest',
        function(status, body)
            if status ~= 200 or not body then return end
            local latest = body:match('"tag_name"%s*:%s*"v?([^"]+)"')
            if not latest or latest == VERSION then return end
            print('^3[reluctant-handling]^7 Update available: v' .. latest .. ' (you have v' .. VERSION .. ')')
            print('^3[reluctant-handling]^7 https://github.com/ReluctantDevelopment/reluctant-handling/releases/latest')
        end,
        'GET', '', { ['User-Agent'] = 'reluctant-handling-version-check' }
    )
end)

local function CanAccessMenu(source)
    if Config.checkAce and not IsPlayerAceAllowed(source, Config.ace) then return false end
    return true
end

RegisterNetEvent('reluctant-handling:permissions', function()
    local src = source
    if not CanAccessMenu(src) then return end
    TriggerClientEvent('reluctant-handling:open', src)
end)
