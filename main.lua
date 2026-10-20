--[[
	Dex++ x Studio Lite  |  main.lua (unico arquivo que voce executa)

	Uso (cole no executor):
		loadstring(game:HttpGet("https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/main.lua"))()

	Para nao editar este arquivo, defina antes de executar:
		getgenv().DexPP_Config = {Repo = "usuario/repo", Branch = "main"}

	Modo desenvolvimento (sem GitHub): copie a pasta do repo para a workspace do executor
	e use  getgenv().DexPP_Config = {Dev = "DexPP-StudioLite/"}  -> carrega direto dos arquivos locais.
]]

local env = getgenv()
local CONFIG = {
	Repo = "snowdevlol/DexSL", -- <- troque aqui (ou use DexPP_Config)
	Branch = "main",               -- pode ser um commit hash (evita cache do raw.githubusercontent)
	Dev = nil,                     -- pasta local na workspace, ex.: "DexPP-StudioLite/"
}
for k, v in pairs(env.DexPP_Config or {}) do CONFIG[k] = v end

env.DexPP_StudioLiteMode = true -- Explorer mostra so o que o Studio Lite mostrava
env.DexPP_Version = "1.0.0"

local function fetch(path)
	if CONFIG.Dev and readfile and isfile and isfile(CONFIG.Dev .. path) then
		return readfile(CONFIG.Dev .. path)
	end
	local url = ("https://raw.githubusercontent.com/%s/%s/%s"):format(CONFIG.Repo, CONFIG.Branch, path)
	local ok, body = pcall(game.HttpGet, game, url, true)
	if not ok or type(body) ~= "string" or body == "" or body:sub(1, 3) == "404" then
		error(("[DexPP] nao consegui baixar %s (%s)"):format(path, url), 0)
	end
	return body
end

-- DexPP_Load(caminho) -> funcao compilada (cada arquivo do repo e um "chunk")
env.DexPP_Load = function(path)
	local fn, err = loadstring(fetch(path), "=" .. path)
	if not fn then error(("[DexPP] erro de sintaxe em %s: %s"):format(path, tostring(err)), 0) end
	return fn
end

-- 1) ponte Studio Lite <-> Dex (espera o Dex iniciar em segundo plano)
env.DexPP_Load("src/bridge/init.lua")()

-- 2) Dex++ (core.lua carrega os modulos de src/dex/modules/ e inicia)
env.DexPP_Load("src/dex/core.lua")()
