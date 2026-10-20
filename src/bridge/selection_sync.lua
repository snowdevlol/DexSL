-- Dex <-> Studio Lite: sincroniza a selecao e mostra o editor ao selecionar scripts.
local ctx = ...
local Players, RS, UIS, lp, gui, panel = ctx.Players, ctx.RS, ctx.UIS, ctx.lp, ctx.gui, ctx.panel
local getSel, setSel, evA, evB = ctx.getSel, ctx.setSel, ctx.evA, ctx.evB
local Explorer, Properties, selection = ctx.Explorer, ctx.Properties, ctx.selection
local SLF, GetScriptSource, ServerFunctions = ctx.SLF, ctx.GetScriptSource, ctx.ServerFunctions
local ColorizeSource, GG = ctx.ColorizeSource, ctx.GG
local InsertFrame, frS, frL, frM, ViewScriptFrame = ctx.InsertFrame, ctx.frS, ctx.frL, ctx.frM, ctx.ViewScriptFrame
local State = ctx.State
local ShowScript, MobileAddKeyboard, NewPart = ctx.ShowScript, ctx.MobileAddKeyboard, ctx.NewPart

-- 4) Dex -> Studio Lite
local function currentList()
	local out = {}
	for _, node in ipairs(selection.List) do
		local o = node.Obj
		if typeof(o) == "Instance" then out[#out + 1] = o end
	end
	return out
end
getSel.OnInvoke = currentList

local lastScript
local function applySelectionUI(list)
	InsertFrame.Visible = false
	frS.Visible = false; frL.Visible = false; frM.Visible = false
	local first = list[1]
	if first and first:IsA("LuaSourceContainer") then
		if first ~= lastScript or not ViewScriptFrame.Visible then
			lastScript = first
			task.spawn(function()
				local ok, err = pcall(ShowScript, first)
				if not ok then warn("[DexBridge] ShowScript:", err) end
			end)
		end
	else
		lastScript = nil
		ViewScriptFrame.Visible = false
	end
end

local pending = false
selection.Changed:Connect(function()
	if State.muted or pending then return end
	pending = true
	task.defer(function()
		pending = false
		applySelectionUI(currentList())
		evA:Fire()
		evB:Fire()
	end)
end)

-- 5) Studio Lite -> Dex (clique no viewport, etc.)
setSel.OnInvoke = function(list)
	list = type(list) == "table" and list or {}
	local nodesToSel = {}
	for _, o in ipairs(list) do
		local n = typeof(o) == "Instance" and Explorer.GetNodeFromObj(o)
		if n then nodesToSel[#nodesToSel + 1] = n end
	end
	State.muted = true
	pcall(function() selection:SetTable(nodesToSel) end)
	State.muted = false
	if #nodesToSel > 0 then pcall(Explorer.ViewNode, nodesToSel[1]) end
	applySelectionUI(list)
	evA:Fire()
	evB:Fire()
end
