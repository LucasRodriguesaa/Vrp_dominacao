local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")

src = Tunnel.getInterface("vrp_dominacao")

local npcsVivos = {}
local totalNpcsIniciais = 0
local dominando = false
local areasConcluidasGlobal = {}
local grupoInimigo = AddRelationshipGroup("DOMINATION_ENEMIES")

RegisterNetEvent("domination:removerAreaGlobal")
AddEventHandler("domination:removerAreaGlobal", function(areaId)
    areasConcluidasGlobal[areaId] = true
end)

Citizen.CreateThread(function()
    while true do
        local idle = 1000
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)

        if dominando and #npcsVivos > 0 then
            idle = 5
            drawTxt("INIMIGOS NA ÁREA: ~r~" .. #npcsVivos .. " / " .. totalNpcsIniciais, 4, 0.5, 0.10, 0.50, 255, 255, 255, 180)
            drawProgressBar(0.4, 0.14, 0.2 * (#npcsVivos / totalNpcsIniciais), 0.015, 200, 0, 0, 200)
        end

        for i, v in ipairs(Config.Dominacao) do
            if not areasConcluidasGlobal[v.id] and not dominando then
                local dist = #(pCoords - vector3(v.pos.x, v.pos.y, v.pos.z))
                if dist < 10.0 then
                    idle = 5
                    DrawText3D(v.pos.x, v.pos.y, v.pos.z, "Pressione [~g~E~w~] para INICIAR DOMINAÇÃO")
                    if IsControlJustPressed(0, 38) then
                        iniciarInvasao(i)
                    end
                end
            end
        end
        Citizen.Wait(idle)
    end
end)

function iniciarInvasao(index)
    if src.checkPodeDominar(index) then 
        local cfg = Config.Dominacao[index]
        dominando = true
        npcsVivos = {}
        totalNpcsIniciais = cfg.quantidadeNPCs

        SetRelationshipBetweenGroups(5, grupoInimigo, GetHashKey("PLAYER"))
        SetRelationshipBetweenGroups(5, grupoInimigo, GetHashKey("CIVMALE"))
        SetRelationshipBetweenGroups(5, grupoInimigo, GetHashKey("CIVFEMALE"))

        for i = 1, cfg.quantidadeNPCs do
            local spawnX = cfg.pos.x + math.random(-cfg.raioSpawn, cfg.raioSpawn)
            local spawnY = cfg.pos.y + math.random(-cfg.raioSpawn, cfg.raioSpawn)
            local mHash = GetHashKey(cfg.npcHash)
            
            RequestModel(mHash)
            while not HasModelLoaded(mHash) do Wait(1) end

            local nbcPed = CreatePed(4, mHash, spawnX, spawnY, cfg.pos.z, 0.0, true, false)
            
            SetEntityMaxHealth(nbcPed, cfg.vidaNPC) 
            SetEntityHealth(nbcPed, cfg.vidaNPC)
            SetPedArmour(nbcPed, cfg.coleteNPC)
            SetPedAccuracy(nbcPed, cfg.precisaoNPC)
            SetPedRelationshipGroupHash(nbcPed, grupoInimigo)
            
            SetPedConfigFlag(nbcPed, 128, true) 
            SetPedCombatAttributes(nbcPed, 46, true) 
            SetPedCombatAttributes(nbcPed, 142, true)
            
            GiveWeaponToPed(nbcPed, GetHashKey(cfg.armaNPC), 999, false, true)
            TaskCombatHatedTargetsAroundPed(nbcPed, cfg.raioSpawn + 15.0, 0)
            
            table.insert(npcsVivos, nbcPed)
        end

        Citizen.CreateThread(function()
            while #npcsVivos > 0 do
                for k, pedNPC in ipairs(npcsVivos) do
                    if IsEntityDead(pedNPC) then 
                        DeleteEntity(pedNPC)
                        table.remove(npcsVivos, k) 
                    end
                end

                if IsEntityDead(PlayerPedId()) then
                    TriggerServerEvent("domination:liberarTrava")
                    dominando = false
                    break
                end

                if #npcsVivos == 0 then
                    TriggerServerEvent("domination:checkReward", index, cfg.id)
                    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
                    dominando = false
                end
                Wait(500)
            end
        end)
    end
end

-- Utilitários
function drawTxt(text,font,x,y,scale,r,g,b,a)
    SetTextFont(font)
    SetTextScale(scale,scale)
    SetTextColour(r,g,b,a)
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x,y)
end

function drawProgressBar(x, y, w, h, r, g, b, a)
    DrawRect(x + w/2, y + h/2, w, h, r, g, b, a)
end

function DrawText3D(x,y,z, text)
    local onScreen,_x,_y=World3dToScreen2d(x,y,z)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x,_y)
end
