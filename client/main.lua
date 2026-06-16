local isOpen = false
local editVehicle = 0
local editVehicleType = 'car'

local activeVehicle = 0
local activeVehicleType = 'car'
local activeHandling = nil
local activeSubHandling = nil

local floatFields = {
    'fMass', 'fInitialDragCoeff', 'fDownforceModifier', 'fPercentSubmerged',
    'fDriveBiasFront', 'fInitialDriveForce', 'fDriveInertia',
    'fClutchChangeRateScaleUpShift', 'fClutchChangeRateScaleDownShift', 'fInitialDriveMaxFlatVel',
    'fBrakeForce', 'fBrakeBiasFront', 'fHandBrakeForce', 'fSteeringLock',
    'fTractionCurveMax', 'fTractionCurveMin', 'fTractionCurveLateral', 'fTractionSpringDeltaMax',
    'fLowSpeedTractionLossMult', 'fCamberStiffnesss', 'fTractionBiasFront', 'fTractionLossMult',
    'fSuspensionForce', 'fSuspensionCompDamp', 'fSuspensionReboundDamp',
    'fSuspensionUpperLimit', 'fSuspensionLowerLimit', 'fSuspensionRaise', 'fSuspensionBiasFront',
    'fAntiRollBarForce', 'fAntiRollBarBiasFront', 'fRollCentreHeightFront', 'fRollCentreHeightRear',
    'fCollisionDamageMult', 'fWeaponDamageMult', 'fDeformationDamageMult', 'fEngineDamageMult',
    'fPetrolTankVolume', 'fPetrolConsumptionRate', 'fOilVolume',
    'fSeatOffsetDistX', 'fSeatOffsetDistY', 'fSeatOffsetDistZ',
}

local intFields = {
    'nInitialDriveGears', 'nMonetaryValue',
}

local vectorFields = {
    'vecCentreOfMassOffset', 'vecInertiaMultiplier',
}

local subHandlingFields = {
    car = {
        className = 'CCarHandlingData',
        floats = {
            'fToeFront', 'fToeRear', 'fCamberFront', 'fCamberRear', 'fCastor',
            'fEngineResistance', 'fMaxDriveBiasTransfer', 'fJumpForceScale',
            'fBackEndPopUpCarImpulseScale', 'fBackEndPopUpBuildingImpulseScale',
            'fBackEndPopUpMaxDeltaSpeed', 'fIncreasedRearBrakesBiasMod', 'fLowSpeedBumpSensitivity',
        }
    },
    bike = {
        className = 'CBikeHandlingData',
        floats = {
            'fLeanFwdCOMMult', 'fLeanFwdForceMult', 'fLeanBakCOMMult', 'fLeanBakForceMult',
            'fMaxBankAngle', 'fFullAnimAngle', 'fDesLeanReturnFrac', 'fStickLeanMult',
            'fBrakingStabilityMult', 'fInAirSteerMult', 'fWheelieBalancePoint', 'fStoppieBalancePoint',
        }
    },
    plane = {
        className = 'CFlyingHandlingData',
        floats = {
            'fThrust', 'fThrustFallOff', 'fThrustVectoring',
            'fYawMult', 'fYawStabilise', 'fSideSlipMult',
            'fRollMult', 'fRollStabilise', 'fPitchMult', 'fPitchStabilise',
            'fAttackLiftMult', 'fAttackDiveMult', 'fFormLiftMult',
            'fGearDownStartSpeed', 'fGearUpEndSpeed',
        }
    },
    heli = {
        className = 'CFlyingHandlingData',
        floats = {
            'fThrust', 'fThrustFallOff', 'fThrustVectoring',
            'fYawMult', 'fYawStabilise', 'fSideSlipMult',
            'fRollMult', 'fRollStabilise', 'fPitchMult', 'fPitchStabilise',
            'fAttackLiftMult', 'fAttackDiveMult', 'fFormLiftMult',
        }
    },
    boat = {
        className = 'CBoatHandlingData',
        floats = { 'fThrust', 'fThrustFallOff', 'fDragCoeff', 'fRudder', 'fSinkMult', 'fAquaplaneForce' }
    },
}

local function DetectVehicleType(vehicle)
    local model = GetEntityModel(vehicle)
    if IsThisModelABike(model) then return 'bike' end
    if IsThisModelAPlane(model) then return 'plane' end
    if IsThisModelAHeli(model) then return 'heli' end
    if IsThisModelABoat(model) then return 'boat' end
    return 'car'
end

local function CollectSubHandling(vehicle, vehicleType)
    local config = subHandlingFields[vehicleType]
    if not config then return {} end

    local data = {}
    for _, field in ipairs(config.floats) do
        local ok, val = pcall(GetVehicleHandlingFloat, vehicle, config.className, field)
        if ok then data[field] = val end
    end
    return data
end

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

    for _, modType in ipairs({ 11, 12, 13, 15 }) do
        local count = GetNumVehicleMods(vehicle, modType)
        if count > 0 then
            SetVehicleMod(vehicle, modType, count - 1, false)
        end
    end

    ToggleVehicleMod(vehicle, 18, true)
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

local function Notify(message)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end

local function EnsureControlOfVehicle(vehicle)
    if not DoesEntityExist(vehicle) then
        return false, 'Vehicle no longer exists'
    end

    if not NetworkGetEntityIsNetworked(vehicle) then
        return true
    end

    if NetworkHasControlOfEntity(vehicle) then
        return true
    end

    local timeoutAt = GetGameTimer() + 1500
    repeat
        NetworkRequestControlOfEntity(vehicle)
        Wait(0)
    until NetworkHasControlOfEntity(vehicle) or GetGameTimer() > timeoutAt

    if NetworkHasControlOfEntity(vehicle) then
        return true
    end

    return false, 'No network control of this vehicle'
end

local function WithEditableVehicle(applyFn)
    local ok, err = EnsureControlOfVehicle(editVehicle)
    if not ok then
        Notify(('Handling update failed: %s'):format(err))
        return false
    end

    applyFn(editVehicle)
    return true
end

local function OpenEditor()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local vehicle = GetVehiclePedIsIn(ped, false)
    local modelName = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    local vehType = DetectVehicleType(vehicle)

    editVehicle = vehicle
    editVehicleType = vehType

    local hasControl, err = EnsureControlOfVehicle(vehicle)
    if not hasControl then
        Notify(('Cannot open handling editor: %s'):format(err))
        return
    end

    local handling = CollectHandling(vehicle)
    local sub = CollectSubHandling(vehicle, vehType)

    activeVehicle = vehicle
    activeVehicleType = vehType
    activeHandling = handling
    activeSubHandling = sub

    SetNuiFocus(true, true)
    isOpen = true

    SendNUIMessage({
        action = 'showEditor',
        data = {
            vehicleName = modelName,
            vehicleType = vehType,
            handling = handling,
            subHandling = sub,
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
    editVehicleType = 'car'
    cb('ok')
end)

RegisterNUICallback('setHandlingFloat', function(data, cb)
    WithEditableVehicle(function(vehicle)
        SetVehicleHandlingFloat(vehicle, 'CHandlingData', data.field, data.value + 0.0)
    end)
    if activeHandling then activeHandling[data.field] = data.value end
    cb('ok')
end)

RegisterNUICallback('setHandlingInt', function(data, cb)
    WithEditableVehicle(function(vehicle)
        SetVehicleHandlingInt(vehicle, 'CHandlingData', data.field, data.value)
    end)
    if activeHandling then activeHandling[data.field] = data.value end
    cb('ok')
end)

RegisterNUICallback('setHandlingVector', function(data, cb)
    WithEditableVehicle(function(vehicle)
        SetVehicleHandlingVector(vehicle, 'CHandlingData', data.field,
            vector3(data.x + 0.0, data.y + 0.0, data.z + 0.0))
    end)
    if activeHandling then activeHandling[data.field] = { x = data.x, y = data.y, z = data.z } end
    cb('ok')
end)

RegisterNUICallback('setSubHandlingFloat', function(data, cb)
    WithEditableVehicle(function(vehicle)
        SetVehicleHandlingFloat(vehicle, data.className, data.field, data.value + 0.0)
    end)
    if activeSubHandling then activeSubHandling[data.field] = data.value end
    cb('ok')
end)

CreateThread(function()
    while true do
        Wait(500)
        if activeVehicle ~= 0 then
            if not DoesEntityExist(activeVehicle) then
                activeVehicle = 0
                activeHandling = nil
                activeSubHandling = nil
            else
                local ped = PlayerPedId()
                if GetVehiclePedIsIn(ped, false) ~= activeVehicle then
                    activeVehicle = 0
                    activeHandling = nil
                    activeSubHandling = nil
                elseif NetworkHasControlOfEntity(activeVehicle) then
                    if activeHandling then
                        for _, field in ipairs(floatFields) do
                            if activeHandling[field] then
                                SetVehicleHandlingFloat(activeVehicle, 'CHandlingData', field, activeHandling[field] + 0.0)
                            end
                        end
                        for _, field in ipairs(intFields) do
                            if activeHandling[field] then
                                SetVehicleHandlingInt(activeVehicle, 'CHandlingData', field, activeHandling[field])
                            end
                        end
                        for _, field in ipairs(vectorFields) do
                            if activeHandling[field] then
                                local v = activeHandling[field]
                                SetVehicleHandlingVector(activeVehicle, 'CHandlingData', field, vector3(v.x + 0.0, v.y + 0.0, v.z + 0.0))
                            end
                        end
                    end
                    if activeSubHandling then
                        local subConfig = subHandlingFields[activeVehicleType]
                        if subConfig then
                            for field, value in pairs(activeSubHandling) do
                                pcall(SetVehicleHandlingFloat, activeVehicle, subConfig.className, field, value + 0.0)
                            end
                        end
                    end
                end
            end
        end
    end
end)

RegisterNUICallback('refreshEditor', function(_, cb)
    if not DoesEntityExist(editVehicle) then
        cb('ok')
        return
    end
    SendNUIMessage({
        action = 'showEditor',
        data = {
            vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(editVehicle)),
            vehicleType = editVehicleType,
            handling = CollectHandling(editVehicle),
            subHandling = CollectSubHandling(editVehicle, editVehicleType),
        }
    })
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
