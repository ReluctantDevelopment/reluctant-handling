local isOpen = false
local editVehicle = 0

local floatFields = {
    'fMass', 'fInitialDragCoeff', 'fDownforceModifier', 'fPercentSubmerged',
    'fDriveBiasFront', 'fInitialDriveForce', 'fDriveInertia',
    'fClutchChangeRateScaleUpShift', 'fClutchChangeRateScaleDownShift',
    'fInitialDriveMaxFlatVel', 'fBrakeForce', 'fBrakeBiasFront', 'fHandBrakeForce',
    'fSteeringLock', 'fTractionCurveMax', 'fTractionCurveMin', 'fTractionCurveLateral',
    'fTractionSpringDeltaMax', 'fLowSpeedTractionLossMult', 'fCamberStiffnesss',
    'fTractionBiasFront', 'fTractionLossMult', 'fSuspensionForce',
    'fSuspensionCompDamp', 'fSuspensionReboundDamp', 'fSuspensionUpperLimit',
    'fSuspensionLowerLimit', 'fSuspensionRaise', 'fSuspensionBiasFront',
    'fAntiRollBarForce', 'fAntiRollBarBiasFront', 'fRollCentreHeightFront',
    'fRollCentreHeightRear', 'fCollisionDamageMult', 'fWeaponDamageMult',
    'fDeformationDamageMult', 'fEngineDamageMult', 'fPetrolTankVolume', 'fOilVolume',
}

local intFields = {
    'nInitialDriveGears',
}

local vectorFields = {
    'vecCentreOfMassOffset', 'vecInertiaMultiplier',
}

local function CollectHandling(vehicle)
    local data = {}

    for _, field in ipairs(floatFields) do
        data[field] = GetVehicleHandlingFloat(vehicle, 'CHandlingData', field)
    end

    for _, field in ipairs(intFields) do
        data[field] = GetVehicleHandlingInt(vehicle, 'CHandlingData', field)
    end

    for _, field in ipairs(vectorFields) do
        local v = GetVehicleHandlingVector(vehicle, 'CHandlingData', field)
        data[field] = { x = v.x, y = v.y, z = v.z }
    end

    return data
end

local function MaxUpgradeVehicle(vehicle)
    SetVehicleModKit(vehicle, 0)

    -- engine(11), brakes(12), transmission(13), suspension(15) only
    for _, modType in ipairs({ 11, 12, 13, 15 }) do
        local count = GetNumVehicleMods(vehicle, modType)
        if count > 0 then
            SetVehicleMod(vehicle, modType, count - 1, false)
        end
    end

    ToggleVehicleMod(vehicle, 18, true) -- turbo
end

local function RemoveVehicleMods(vehicle)
    SetVehicleModKit(vehicle, 0)

    for modType = 0, 49 do
        SetVehicleMod(vehicle, modType, -1, false)
    end

    ToggleVehicleMod(vehicle, 18, false)
    ToggleVehicleMod(vehicle, 20, false)
    ToggleVehicleMod(vehicle, 22, false)
end

local function OpenEditor()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local vehicle   = GetVehiclePedIsIn(ped, false)
    local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))

    editVehicle = vehicle
    if NetworkGetEntityIsNetworked(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
    end

    SetNuiFocus(true, true)
    isOpen = true

    SendNUIMessage({
        action = 'showEditor',
        data = {
            vehicleName = modelName,
            handling    = CollectHandling(vehicle),
        }
    })
end

RegisterNetEvent('reluctant-handling:open', function()
    if isOpen then return end
    OpenEditor()
end)

RegisterCommand(Config.cmdName, function()
    if isOpen then return end
    TriggerServerEvent('reluctant-handling:permissions')
end, false)

RegisterKeyMapping(Config.cmdName, 'Open Handling Editor', 'keyboard', Config.keybind)

RegisterNUICallback('closeEditor', function(_, cb)
    SetNuiFocus(false, false)
    isOpen = false
    editVehicle = 0
    cb('ok')
end)

RegisterNUICallback('setHandlingFloat', function(data, cb)
    print(('[handling] setHandlingFloat: vehicle=%s field=%s value=%s'):format(editVehicle, tostring(data.field), tostring(data.value)))
    if DoesEntityExist(editVehicle) then
        SetVehicleHandlingFloat(editVehicle, 'CHandlingData', data.field, data.value + 0.0)
        print(('[handling] applied OK (entity exists)'))
    else
        print(('[handling] SKIPPED - entity does not exist'))
    end
    cb('ok')
end)

RegisterNUICallback('setHandlingInt', function(data, cb)
    if DoesEntityExist(editVehicle) then
        SetVehicleHandlingInt(editVehicle, 'CHandlingData', data.field, data.value)
    end
    cb('ok')
end)

RegisterNUICallback('setHandlingVector', function(data, cb)
    if DoesEntityExist(editVehicle) then
        SetVehicleHandlingVector(editVehicle, 'CHandlingData', data.field,
            vector3(data.x + 0.0, data.y + 0.0, data.z + 0.0))
    end
    cb('ok')
end)

RegisterNUICallback('maxUpgradeVehicle', function(_, cb)
    if DoesEntityExist(editVehicle) then
        MaxUpgradeVehicle(editVehicle)
    end
    cb('ok')
end)

RegisterNUICallback('removeVehicleMods', function(_, cb)
    if DoesEntityExist(editVehicle) then
        RemoveVehicleMods(editVehicle)
    end
    cb('ok')
end)
