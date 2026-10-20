-- ============================================================
-- Studio Lite  <->  Dex++ Explorer bridge
-- Troca o Explorer do Studio Lite pelo do Dex++ mantendo
-- Properties / main / editor de scripts funcionando.
-- ============================================================

task.spawn(function()
	local Players = game:GetService("Players")
	local RS = game:GetService("ReplicatedStorage")
	local UIS = game:GetService("UserInputService")
	local lp = Players.LocalPlayer
	local gui = lp:WaitForChild("PlayerGui"):WaitForChild("StudioGui", 30)
	if not gui then return warn("[DexBridge] StudioGui nao encontrado") end
	local panel = gui:WaitForChild("ExplorerPanel", 30)
	local getSel = panel:WaitForChild("GetSelection", 30)
	local setSel = panel:WaitForChild("SetSelection", 30)
	local evA = workspace:WaitForChild("ExplorerSelectionChanged", 30)
	local evB = workspace:WaitForChild("ExplorerSelectionChangedToMain", 30)

	-- espera o Dex++ terminar de iniciar
	local t0 = os.clock()
	while not (getgenv().DexPP_Explorer and getgenv().DexPP_Explorer.Selection
		and getgenv().DexPP_Explorer.Window) do
		if os.clock() - t0 > 60 then return warn("[DexBridge] Dex++ nao iniciou") end
		task.wait(0.25)
	end
	task.wait(1.5)
	local Explorer = getgenv().DexPP_Explorer
	local Properties = getgenv().DexPP_Properties
	local selection = Explorer.Selection

	-- forca o Explorer do Dex a montar/desenhar a arvore
	pcall(function() Explorer.Window:Show({Align = "right", Pos = 1, Size = 0.5, Silent = true}) end)
	pcall(function()
		Explorer.Active = true
		Explorer.UpdateView()
		Explorer.Update()
		Explorer.Refresh()
	end)
	pcall(function()
		local root = Explorer.GetNodeFromObj(game)
		warn("[DexBridge] filhos de game no Explorer:", root and #root or "sem no raiz")
	end)

	-- 1) desliga o Explorer antigo (mantem o painel como casca invisivel)
	local old = panel:FindFirstChild("Explorer")
	if old and old:IsA("LocalScript") then old.Disabled = true end
	for _, c in ipairs(panel:GetChildren()) do
		if c:IsA("GuiObject") then c.Visible = false end
	end
	panel.BackgroundTransparency = 1

	-- 2) o Properties do Studio Lite continua; esconde o Properties do Dex
	if Properties and Properties.Window then
		pcall(function() Properties.Window:Hide() end)
	end

	-- 3) pecas do Studio Lite usadas pelo editor / criacao de scripts
	local SLF = RS:WaitForChild("StudioLiteFolder", 30)
	local GetScriptSource = SLF:WaitForChild("GetScriptSourceServerFunction", 30)
	local ServerFunctions = SLF:WaitForChild("ServerFunctions", 30)
	local ColorizeSource = require(SLF:WaitForChild("ColorizeSourceModule", 30))
	local GG = (getrenv and getrenv()._G) or _G
	local InsertFrame = gui:WaitForChild("InsertFrame")
	local frS = gui:WaitForChild("InsertScriptFrame")
	local frL = gui:WaitForChild("InsertLocalScriptFrame")
	local frM = gui:WaitForChild("InsertModuleScriptFrame")
	local ViewScriptFrame = gui:WaitForChild("ViewScriptFrame")

	-- estado compartilhado entre os modulos da ponte
	local State = {muted = false}
	local ctx = {
		Players = Players, RS = RS, UIS = UIS, lp = lp, gui = gui, panel = panel,
		getSel = getSel, setSel = setSel, evA = evA, evB = evB,
		Explorer = Explorer, Properties = Properties, selection = selection,
		SLF = SLF, GetScriptSource = GetScriptSource, ServerFunctions = ServerFunctions,
		ColorizeSource = ColorizeSource, GG = GG,
		InsertFrame = InsertFrame, frS = frS, frL = frL, frM = frM, ViewScriptFrame = ViewScriptFrame,
		State = State,
	}
	local Load = getgenv().DexPP_Load

	-- 3) visualizador/teclado/NewPart originais do Studio Lite
	local viewer = Load("src/bridge/studiolite_viewer.lua")(ctx)
	ctx.ShowScript, ctx.MobileAddKeyboard, ctx.NewPart = viewer.ShowScript, viewer.MobileAddKeyboard, viewer.NewPart

	-- 3b) Code Editor novo (opcional: se falhar, o Dex cai no Notepad)
	local okEd, errEd = pcall(function() Load("src/bridge/code_editor.lua")(ctx) end)
	if not okEd then warn("[DexBridge] Code Editor:", errEd) end

	-- 4/5) selecao Dex <-> Studio Lite
	Load("src/bridge/selection_sync.lua")(ctx)

	-- 6) criacao de Script/LocalScript/ModuleScript e Parts
	Load("src/bridge/script_insert.lua")(ctx)

	print("[DexBridge] Explorer do Dex++ ativo no Studio Lite")
end)
