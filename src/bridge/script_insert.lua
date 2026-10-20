-- Criacao de Script/LocalScript/ModuleScript (vazio, com SL_CodeTextBox) e Parts pelo Explorer do Dex.
local ctx = ...
local Players, RS, UIS, lp, gui, panel = ctx.Players, ctx.RS, ctx.UIS, ctx.lp, ctx.gui, ctx.panel
local getSel, setSel, evA, evB = ctx.getSel, ctx.setSel, ctx.evA, ctx.evB
local Explorer, Properties, selection = ctx.Explorer, ctx.Properties, ctx.selection
local SLF, GetScriptSource, ServerFunctions = ctx.SLF, ctx.GetScriptSource, ctx.ServerFunctions
local ColorizeSource, GG = ctx.ColorizeSource, ctx.GG
local InsertFrame, frS, frL, frM, ViewScriptFrame = ctx.InsertFrame, ctx.frS, ctx.frL, ctx.frM, ctx.ViewScriptFrame
local State = ctx.State
local ShowScript, MobileAddKeyboard, NewPart = ctx.ShowScript, ctx.MobileAddKeyboard, ctx.NewPart

-- 6) criar Script / LocalScript / ModuleScript do jeito do Studio Lite
local pendingParent
local pickers = {Script = frS, LocalScript = frL, ModuleScript = frM}
local prefixes = {Script = "InsertScript", LocalScript = "InsertLocalScript", ModuleScript = "InsertModuleScript"}

local function selectObj(inst, silent)
	task.wait()
	local n = Explorer.GetNodeFromObj(inst)
	if n then
		if silent then State.muted = true end
		pcall(function() selection:SetTable({n}) end)
		State.muted = false
		pcall(Explorer.ViewNode, n)
		if silent then evA:Fire(); evB:Fire() end
	end
end

local function openPicker(kind, parentObj)
	pendingParent = parentObj
	frS.Visible = false; frL.Visible = false; frM.Visible = false
	local f = pickers[kind]
	if gui.AbsoluteSize.X < 1100 then
		f.Position = UDim2.new(0, 3, 0, 2)
		f.Size = UDim2.new(1, -5, 1, -4)
	end
	ViewScriptFrame.Visible = false
	local tb = gui:FindFirstChild("ToolboxFrame"); if tb then tb.Visible = false end
	InsertFrame.Visible = false
	f.Visible = true
end

for kind, frame in pairs(pickers) do
	local sf = frame:FindFirstChild("ScrollingFrame") or frame:WaitForChild("ScrollingFrame", 10)
	if sf then
		for _, row in ipairs(sf:GetChildren()) do
			if row.Name:sub(1, 3) == "Row" then
				local btn = row:FindFirstChild("InsertScriptButton")
				local lbl = row:FindFirstChild("NameTextLabel")
				if btn and lbl then
					btn.Activated:Connect(function()
						frame.Visible = false
						local parentObj = pendingParent
						if not parentObj or not parentObj.Parent then
							return warn("[DexBridge] selecione onde criar o script")
						end
						local tname = lbl.Text
						local inst = Instance.new(kind)
						inst.Name = tname
						inst.Parent = parentObj
						local okc, err = pcall(function()
							ServerFunctions:InvokeServer("LoadAssetToPlayerGui", prefixes[kind] .. tname)
							local holder = lp.PlayerGui:WaitForChild(prefixes[kind] .. tname, 10)
							if holder then
								for _, c in ipairs(holder:GetChildren()) do c:Clone().Parent = inst end
							end
							ServerFunctions:InvokeServer("ClearAssetFromPlayerGui", prefixes[kind] .. tname)
						end)
						if not okc then warn("[DexBridge] template:", err) end
						selectObj(inst)
					end)
				end
			end
		end
	end
end

-- cria Script/LocalScript/ModuleScript igual ao do Studio Lite, mas com o codigo vazio
local function makeBlank(kind, parentObj)
	if not parentObj or not parentObj.Parent then
		warn("[DexBridge] selecione onde criar o script")
		return
	end
	local inst = Instance.new(kind)
	inst.Name = kind
	inst.Parent = parentObj
	-- 1) tenta o molde original do Studio Lite (via RemoteFunction), linha em branco = nome igual ao tipo
	pcall(function()
		local sf = pickers[kind]:FindFirstChild("ScrollingFrame")
		for _, row in ipairs(sf:GetChildren()) do
			local lbl = row:FindFirstChild("NameTextLabel")
			if row.Name:sub(1, 3) == "Row" and lbl and lbl.Text == kind then
				local nm = prefixes[kind] .. lbl.Text
				ServerFunctions:InvokeServer("LoadAssetToPlayerGui", nm)
				local holder = lp.PlayerGui:WaitForChild(nm, 10)
				if holder then
					for _, c in ipairs(holder:GetChildren()) do c:Clone().Parent = inst end
				end
				ServerFunctions:InvokeServer("ClearAssetFromPlayerGui", nm)
				break
			end
		end
	end)
	-- 2) se o molde nao trouxe o SL_CodeTextBox, monta um igual
	local box = inst:FindFirstChild("SL_CodeTextBox")
	if not (box and box:IsA("TextBox")) then
		if box then box:Destroy() end
		box = Instance.new("TextBox")
		box.Name = "SL_CodeTextBox"
		box.MultiLine = true
		box.ClearTextOnFocus = false
		box.RichText = true
		box.TextXAlignment = Enum.TextXAlignment.Left
		box.TextYAlignment = Enum.TextYAlignment.Top
		box.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
		box.TextSize = 14
		box.TextColor3 = Color3.new(1, 1, 1)
		box.BackgroundTransparency = 1
		box.BorderSizePixel = 0
		box.AutomaticSize = Enum.AutomaticSize.XY
		box.Size = UDim2.new(1, -52, 0, 0)
		box.Position = UDim2.new(0, 52, 0, 0)
		box.Parent = inst
	end
	if not box:FindFirstChild("SaveChangesTo") then
		local ov = Instance.new("ObjectValue")
		ov.Name = "SaveChangesTo"
		ov.Parent = box
	end
	box.Text = "" -- totalmente vazio
	return inst, box
end

getgenv().DexPP_InsertHook = function(className, parentObj)
	if pickers[className] then
		-- sem picker do Studio Lite: cria o script (com SL_CodeTextBox vazio) e abre o Notepad ligado a ele
		task.spawn(function()
			frS.Visible = false; frL.Visible = false; frM.Visible = false
			InsertFrame.Visible = false
			ViewScriptFrame.Visible = false
			local inst, box = makeBlank(className, parentObj)
			if not inst then return end
			selectObj(inst, true)
			local sv = getgenv().DexPP_ScriptViewer
			if sv and sv.ViewSL and box then pcall(sv.ViewSL, box) end
		end)
		return true
	end
	local ok, inst = pcall(Instance.new, className)
	if ok and inst and inst:IsA("BasePart") then
		NewPart(inst, parentObj)
		task.spawn(selectObj, inst)
		return true
	end
	if ok and inst then inst:Destroy() end
	return false
end
