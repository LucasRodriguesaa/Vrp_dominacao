local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")

vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")

src = {}
Tunnel.bindInterface("vrp_dominacao",src)

local dominacaoEmCurso = false
local areasFinalizadas = {}

-- Verifica se pode iniciar
function src.checkPodeDominar(index)
    local source = source
    local user_id = vRP.getUserId(source)
    local cfg = Config.Dominacao[index]

    if dominacaoEmCurso then
        TriggerClientEvent("Notify",source,"importante","Já existe um conflito ativo na cidade!")
        return false
    end

    if vRP.hasPermission(user_id, cfg.permPermitida) then
        dominacaoEmCurso = true
        return true
    else
        TriggerClientEvent("Notify",source,"negado","Você não tem permissão para tentar liderar esta área.")
        return false
    end
end

RegisterServerEvent("domination:liberarTrava")
AddEventHandler("domination:liberarTrava", function()
    dominacaoEmCurso = false
end)

RegisterServerEvent("domination:checkReward")
AddEventHandler("domination:checkReward", function(index, areaId)
    local source = source
    local user_id = vRP.getUserId(source)
    local cfg = Config.Dominacao[index]

    if cfg and cfg.id == areaId and not areasFinalizadas[areaId] then
        areasFinalizadas[areaId] = true
        dominacaoEmCurso = false
        
        vRP.addUserGroup(user_id, cfg.grupoParaSetar)
        TriggerClientEvent("domination:removerAreaGlobal", -1, areaId)
        TriggerClientEvent("Notify", -1, "aviso", "A área "..cfg.nome.." agora tem um novo Líder!", 8000)
    end
end)

-- Sincronização Global
AddEventHandler("vRP:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        for id, status in pairs(areasFinalizadas) do
            if status then TriggerClientEvent("domination:removerAreaGlobal", source, id) end
        end
    end
end)

-- Reset de trava se o jogador cair
AddEventHandler("playerDropped", function(reason)
    dominacaoEmCurso = false
end)
