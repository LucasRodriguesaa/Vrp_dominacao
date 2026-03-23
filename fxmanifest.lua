fx_version 'cerulean'
game 'gta5'

author 'Gemini AI'
description 'Script de Dominação de Elite para vRPex'
version '1.0.0'

-- Arquivos que o script vai ler
shared_script 'config.lua'

client_script 'client.lua'
server_script 'server.lua'

-- Garante que o vRP seja carregado antes
dependencies {
    'vrp'
}
