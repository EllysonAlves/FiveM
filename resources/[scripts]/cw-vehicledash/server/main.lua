-----------------------------------------------
-- cw-vehicledash | server/main.lua
-- Callback de spawn de veículo
-----------------------------------------------

lib.callback.register('cw-vehicledash:server:spawnVehicle', function(source, modelName)
    -- Permitir spawn de qualquer veículo (JFx não está no qbx_core)
    if not modelName or modelName == '' then
        exports.qbx_core:Notify(source, 'Veículo inválido.', 'error')
        return nil
    end

    local ped = GetPlayerPed(source)

    local netId, vehicle = qbx.spawnVehicle({
        model       = modelName,
        spawnSource = ped,
        warp        = true,
    })

    -- Dá as chaves ao jogador
    exports.qbx_vehiclekeys:GiveKeys(source, vehicle)

    return netId
end)
