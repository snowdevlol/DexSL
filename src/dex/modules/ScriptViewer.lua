-- Modulo do Dex++: ScriptViewer
-- (carregado pelo main.lua via DexPP_Load; antes vivia dentro de EmbeddedModules)
local oldgame = getgenv().DexPP_oldgame or game
local game = getgenv().DexPP_game or game
--[[
	Script Viewer App Module
	
	A script viewer that is basically a notepad
]]
-- Common Locals
local Main,Lib,Apps,Settings -- Main Containers
local Explorer, Properties, ScriptViewer, Notebook -- Major Apps
local API,RMD,env,service,plr,create,createSimple -- Main Locals

local function initDeps(data)
	Main = data.Main
	Lib = data.Lib
	Apps = data.Apps
	Settings = data.Settings

	API = data.API
	RMD = data.RMD
	env = data.env
	service = data.service
	plr = data.plr
	create = data.create
	createSimple = data.createSimple
end

local function initAfterMain()
	Explorer = Apps.Explorer
	Properties = Apps.Properties
	ScriptViewer = Apps.ScriptViewer
	Notebook = Apps.Notebook
end

local executorName = "Unknown"
local executorVersion = "???"
if identifyexecutor then
	local name,ver = identifyexecutor()
	executorName = name
	executorVersion = ver
elseif game:GetService("RunService"):IsStudio() then
	executorName = "Studio"
	executorVersion = version()
end

local function getPath(obj)
	if obj.Parent == nil then
		return "Nil parented"
	else
		return Explorer.GetInstancePath(obj)
	end
end

local function main()
	local ScriptViewer = {}
	local window, codeFrame
	
	local execute, clear, dumpbtn
	
	local PreviousScr = nil
	local boundBox, lastSaved -- [StudioLite bridge] SL_CodeTextBox ligado ao Notepad
	
	ScriptViewer.DumpFunctions = function(scr)
		-- thanks King.Kevin#6025 you'll obviously be credited (no discord tag since that can easily be impersonated)
		local getgc = getgc or get_gc_objects
		local getupvalues = (debug and debug.getupvalues) or getupvalues or getupvals
		local getconstants = (debug and debug.getconstants) or getconstants or getconsts
		local getinfo = (debug and (debug.getinfo or debug.info)) or getinfo
		local original = ("\n-- // Function Dumper made by King.Kevin\n-- // Script Path: %s\n\n--[["):format(getPath(scr))
		local dump = original
		local functions, function_count, data_base = {}, 0, {}
		function functions:add_to_dump(str, indentation, new_line)
			local new_line = new_line or true
			dump = dump .. ("%s%s%s"):format(string.rep("		", indentation), tostring(str), new_line and "\n" or "")
		end
		function functions:get_function_name(func)
			local n = getinfo(func).name
			return n ~= "" and n or "Unknown Name"
		end
		function functions:dump_table(input, indent, index)
			local indent = indent < 0 and 0 or indent
			functions:add_to_dump(("%s [%s] %s"):format(tostring(index), tostring(typeof(input)), tostring(input)), indent - 1)
			local count = 0
			for index, value in pairs(input) do
				count = count + 1
				if type(value) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(count, functions:get_function_name(value)), indent)
				elseif type(value) == "table" then
					if not data_base[value] then
						data_base[value] = true
						functions:add_to_dump(("%d [table]:"):format(count), indent)
						functions:dump_table(value, indent + 1, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(count), indent)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(count, tostring(typeof(value)), tostring(value)), indent)
				end
			end
		end
		function functions:dump_function(input, indent)
			functions:add_to_dump(("\nFunction Dump: %s"):format(functions:get_function_name(input)), indent)
			functions:add_to_dump(("\nFunction Upvalues: %s"):format(functions:get_function_name(input)), indent)
			for index, upvalue in pairs(getupvalues(input)) do
				if type(upvalue) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(upvalue)), indent + 1)
				elseif type(upvalue) == "table" then
					if not data_base[upvalue] then
						data_base[upvalue] = true
						functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
						functions:dump_table(upvalue, indent + 2, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(upvalue)), tostring(upvalue)), indent + 1)
				end
			end
			functions:add_to_dump(("\nFunction Constants: %s"):format(functions:get_function_name(input)), indent)
			for index, constant in pairs(getconstants(input)) do
				if type(constant) == "function" then
					functions:add_to_dump(("%d [function] = %s"):format(index, functions:get_function_name(constant)), indent + 1)
				elseif type(constant) == "table" then
					if not data_base[constant] then
						data_base[constant] = true
						functions:add_to_dump(("%d [table]:"):format(index), indent + 1)
						functions:dump_table(constant, indent + 2, index)
					else
						functions:add_to_dump(("%d [table] (Recursive table detected)"):format(index), indent + 1)
					end
				else
					functions:add_to_dump(("%d [%s] = %s"):format(index, tostring(typeof(constant)), tostring(constant)), indent + 1)
				end
			end
		end
		for _, _function in pairs(env.getgc()) do
			if typeof(_function) == "function" and getfenv(_function).script and getfenv(_function).script == scr then
				functions:dump_function(_function, 0)
				functions:add_to_dump("\n" .. ("="):rep(100), 0, false)
			end
		end
		local source = codeFrame:GetText()

		if dump ~= original then source = source .. dump .. "]]" end
		codeFrame:SetText(source)
		
		window:Show()
	end

	ScriptViewer.Init = function()
		window = Lib.Window.new()
		window:SetTitle("Notepad")
		window:Resize(500,400)
		ScriptViewer.Window = window
		pcall(function() getgenv().DexPP_ScriptViewer = ScriptViewer end) -- [StudioLite bridge]

		codeFrame = Lib.CodeFrame.new()
		codeFrame.Frame.Position = UDim2.new(0,0,0,20)
		codeFrame.Frame.Size = UDim2.new(1,0,1,-40)
		codeFrame.Frame.Parent = window.GuiElems.Content
		
		local copy = Instance.new("TextButton",window.GuiElems.Content)
		copy.BackgroundTransparency = 1
		copy.Size = UDim2.new(0.33,0,0,20)
		copy.Position = UDim2.new(0,0,0,0)
		copy.Text = "Copy to Clipboard"
		
		if env.setclipboard then
			copy.TextColor3 = Color3.new(1,1,1)
			copy.Interactable = true
		else
			copy.TextColor3 = Color3.new(0.5,0.5,0.5)
			copy.Interactable = false
		end

		copy.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			env.setclipboard(source)
		end)

		local save = Instance.new("TextButton",window.GuiElems.Content)
		save.BackgroundTransparency = 1
		save.Size = UDim2.new(0.33,0,0,20)
		save.Position = UDim2.new(0.33,0,0,0)
		save.Text = "Save to File"
		save.TextColor3 = Color3.new(1,1,1)
		
		if env.writefile then
			save.TextColor3 = Color3.new(1,1,1)
			save.Interactable = true
		else
			save.TextColor3 = Color3.new(0.5,0.5,0.5)
			--save.Interactable = false
		end

		save.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			local filename = "Place_"..game.PlaceId.."_Script_"..os.time()..".txt"

			Lib.SaveAsPrompt(filename,source)
			--env.writefile(filename,source)
		end)
		
		dumpbtn = Instance.new("TextButton",window.GuiElems.Content)
		dumpbtn.BackgroundTransparency = 1
		dumpbtn.Position = UDim2.new(0.7,0,0,0)
		dumpbtn.Size = UDim2.new(0.3,0,0,20)
		dumpbtn.Text = "Dump Functions"
		dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
		
		if env.getgc then
			dumpbtn.TextColor3 = Color3.new(1,1,1)
			dumpbtn.Interactable = true
		else
			dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
			dumpbtn.Interactable = false
		end

		dumpbtn.MouseButton1Click:Connect(function()
			if PreviousScr ~= nil then
				pcall(ScriptViewer.DumpFunctions, PreviousScr)
			end
		end)
		
		-- Buttons below the editor
		
		
		execute = Instance.new("TextButton",window.GuiElems.Content)
		execute.BackgroundTransparency = 1
		execute.Size = UDim2.new(0.5,0,0,20)
		execute.Position = UDim2.new(0,0,1,-20)
		execute.Text = "Execute"
		execute.TextColor3 = Color3.new(1,1,1)
		
		if env.loadstring then
			execute.TextColor3 = Color3.new(1,1,1)
			execute.Interactable = true
		else
			execute.TextColor3 = Color3.new(0.5,0.5,0.5)
			execute.Interactable = false
		end

		execute.MouseButton1Click:Connect(function()
			local source = codeFrame:GetText()
			env.loadstring(source)()
		end)

		clear = Instance.new("TextButton",window.GuiElems.Content)
		clear.BackgroundTransparency = 1
		clear.Size = UDim2.new(0.5,0,0,20)
		clear.Position = UDim2.new(0.5,0,1,-20)
		clear.Text = "Clear"
		clear.TextColor3 = Color3.new(1,1,1)

		clear.MouseButton1Click:Connect(function()
			codeFrame:SetText("")
		end)

		-- [StudioLite bridge] autosave: copia o texto do Notepad para o SL_CodeTextBox
		task.spawn(function()
			while true do
				task.wait(0.4)
				local box = boundBox
				if box then
					if not box.Parent then
						boundBox = nil
					else
						local ok, t = pcall(codeFrame.GetText, codeFrame)
						if ok and t ~= lastSaved then
							lastSaved = t
							if box.RichText then
								t = t:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"):gsub("'", "&apos;")
							end
							box.Text = t
						end
					end
				end
			end
		end)
	end
	
	-- [StudioLite bridge] abre o Notepad ligado ao SL_CodeTextBox de um script do Studio Lite
	-- (le e salva no mesmo lugar onde o editor do Studio Lite guarda o codigo)
	ScriptViewer.ViewSL = function(box)
		local ed = getgenv().DexPP_CodeEditor
		if ed then
			local okEd, errEd = pcall(ed.Open, {Title = box.Parent and box.Parent.Name or "Script", Text = box.ContentText or "", Box = box})
			if okEd then boundBox = nil return end
			warn("[DexBridge] Code Editor:", errEd)
		end
		PreviousScr = nil
		boundBox = box
		pcall(function() dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5) end)
		local txt = box.ContentText or ""
		codeFrame:SetText(txt)
		lastSaved = codeFrame:GetText()
		pcall(function() window:SetTitle("Notepad - " .. (box.Parent and box.Parent.Name or "Script")) end)
		window:Show()
	end

	ScriptViewer.ViewScript = function(scr)
		local slbox = scr:FindFirstChild("SL_CodeTextBox")
		if slbox and slbox:IsA("TextBox") then
			return ScriptViewer.ViewSL(slbox)
		end
		boundBox = nil
		pcall(function() window:SetTitle("Notepad") end)
		local oldtick = tick()
		local s,source = pcall(env.decompile or function() end,scr)

		if not s or not source then
			PreviousScr = nil
			dumpbtn.TextColor3 = Color3.new(0.5,0.5,0.5)
			source = "-- Unable to view source.\n"
			
			if Settings.ScriptViewer.ShowMoreInfo then
				source = source .. "-- Script Path: "..getPath(scr).."\n"
				if (scr.ClassName == "Script" and (scr.RunContext == Enum.RunContext.Legacy or scr.RunContext == Enum.RunContext.Server)) or not scr:IsA("LocalScript") then
					source = source .. "-- Reason: The script is not running on client. (attempt to decompile ServerScript or 'Script' with RunContext Server)\n"
				elseif not env.isdecompile() then
					source = source .. "-- Reason: Your executor does not support decompiler. (missing 'decompile' function and 'getscriptbytecode' function as fallback)\n"
				else
					source = source .. "-- Reason: Unknown Error.\n"
				end
				source = source .. "-- Executor: "..executorName.." ("..executorVersion..")"
			end
		else
			PreviousScr = scr
			dumpbtn.TextColor3 = Color3.new(1,1,1)

			local decompiled = source

			source = "-- Script Path: "..getPath(scr).."\n"
			
			if Settings.ScriptViewer.ShowMoreInfo then
				source = source .. "-- Took "..tostring(math.floor( (tick() - oldtick) * 100) / 100).."s to decompile.\n"
				source = source .. "-- Executor: "..executorName.." ("..executorVersion..")\n\n"
			end
			
			source = source .. decompiled

			oldtick = nil
			decompiled = nil
		end

		local ed = getgenv().DexPP_CodeEditor
		if ed and pcall(ed.Open, {Title = scr.Name, Text = source}) then return end
		codeFrame:SetText(source)
		window:Show()
	end

	return ScriptViewer
end

-- TODO: Remove when open source
if gethsfuncs then
	_G.moduleData = {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
else
	return {InitDeps = initDeps, InitAfterMain = initAfterMain, Main = main}
end
