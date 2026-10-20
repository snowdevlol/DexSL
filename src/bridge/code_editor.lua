-- Code Editor (Notepad do Dex++): mesmo visual do Dex, botoes Copy / Paste,
-- realce de sintaxe, numeros de linha e salva no SL_CodeTextBox do Studio Lite.
local ctx = ...
local UIS, lp = ctx.UIS, ctx.lp

local function buildEditor()
	local rgb = Color3.fromRGB
	local env = getgenv()

	-- cores iguais as do tema do Dex
	local TH = {
		Main1 = rgb(52, 52, 52),
		Main2 = rgb(45, 45, 45),
		Outline1 = rgb(33, 33, 33),
		Button = rgb(60, 60, 60),
		ButtonHover = rgb(68, 68, 68),
		ButtonPress = rgb(40, 40, 40),
		Text = rgb(255, 255, 255),
		Dim = rgb(127, 127, 127),
		Back = rgb(36, 36, 36), -- Syntax.Background
		Gutter = rgb(33, 33, 33),
		LineNum = rgb(100, 100, 100),
		Code = rgb(204, 204, 204), -- Syntax.Text
		Important = rgb(255, 0, 0),
	}
	local C = {keyword = "#F86D7C", string = "#ADF195", number = "#FFC600", comment = "#666666",
		builtin = "#84D6F7", func = "#FDFBAC", const = "#FFC600"}
	local HL_MAX = 12000 -- acima disso o realce desliga sozinho (limite de texto do RichText)
	local BAR, ROW = 20, 20 -- barra de titulo e linha dos botoes (iguais ao Notepad do Dex)
	local MINW, MINH = 220, 140

	-- ---------- realce de sintaxe Lua ----------
	local KW, CONST, BUILTIN = {}, {}, {}
	for w in ("and break do else elseif end for function goto if in local not or repeat return then until while continue"):gmatch("[%w_]+") do KW[w] = true end
	for w in ("true false nil self"):gmatch("[%w_]+") do CONST[w] = true end
	for w in ("print warn error assert pcall xpcall select type typeof tostring tonumber ipairs pairs next unpack rawget rawset rawequal setmetatable getmetatable require loadstring tick time wait spawn delay task game workspace script shared Instance Vector2 Vector3 CFrame Color3 UDim UDim2 Enum Ray Region3 TweenInfo BrickColor Random math string table os coroutine utf8 bit32 debug getgenv getrenv getfenv setfenv"):gmatch("[%w_]+") do BUILTIN[w] = true end

	local ESC = {["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;", ["'"] = "&apos;"}
	local function esc(s) return (s:gsub("[&<>\"']", ESC)) end

	local function highlight(src)
		local out, n = {}, 0
		local len = #src
		local i, ps = 1, 1
		local afterFunction = false
		local function tok(color, s, e)
			if s - 1 >= ps then n = n + 1; out[n] = esc(src:sub(ps, s - 1)) end
			n = n + 1
			out[n] = '<font color="' .. color .. '">' .. esc(src:sub(s, e)) .. "</font>"
			ps = e + 1
			i = e + 1
		end
		while i <= len do
			local c = src:sub(i, i)
			if c == "-" and src:sub(i + 1, i + 1) == "-" then
				local lvl = src:match("^%-%-%[(=*)%[", i)
				local e
				if lvl then
					local _, ce = src:find("]" .. lvl .. "]", i + 4 + #lvl, true)
					e = ce or len
				else
					local nl = src:find("\n", i, true)
					e = nl and nl - 1 or len
				end
				if e < i then e = i end
				tok(C.comment, i, e)
				afterFunction = false
			elseif c == '"' or c == "'" then
				local j, e = i + 1, len
				while j <= len do
					local ch = src:sub(j, j)
					if ch == "\\" then j = j + 2
					elseif ch == c then e = j; break
					elseif ch == "\n" then e = j - 1; break
					else j = j + 1 end
				end
				tok(C.string, i, e)
				afterFunction = false
			elseif c == "[" and src:match("^%[=*%[", i) then
				local lvl = src:match("^%[(=*)%[", i)
				local _, ce = src:find("]" .. lvl .. "]", i + 2 + #lvl, true)
				tok(C.string, i, ce or len)
				afterFunction = false
			elseif c:match("%d") then
				local m = src:match("^0[xX][%x_]+", i)
					or src:match("^%d[%d_]*%.?[%d_]*[eE][%+%-]?%d+", i)
					or src:match("^%d[%d_]*%.?[%d_]*", i)
				tok(C.number, i, i + #m - 1)
				afterFunction = false
			elseif c:match("[%a_]") then
				local w = src:match("^[%a_][%w_]*", i)
				local e = i + #w - 1
				local color
				if KW[w] then
					color = C.keyword
					afterFunction = (w == "function") and (src:find("^%s*[%a_]", e + 1) ~= nil)
				else
					if CONST[w] then color = C.const
					elseif afterFunction then color = C.func
					elseif BUILTIN[w] then color = C.builtin
					elseif src:find("^%s*%(", e + 1) then color = C.func end
					afterFunction = false
				end
				if color then tok(color, i, e) else i = e + 1 end
			else
				i = src:find("[%a_%d\"'%-%[]", i + 1) or (len + 1)
			end
		end
		if len >= ps then n = n + 1; out[n] = esc(src:sub(ps, len)) end
		return table.concat(out)
	end

	-- ---------- interface (visual do Dex) ----------
	local function mk(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end
	local CODE_FONT = Font.fromEnum(Enum.Font.Code)

	local sg = mk("ScreenGui", {Name = "DexPP_CodeEditor", ResetOnSpawn = false, DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, lp:WaitForChild("PlayerGui"))
	pcall(function() sg.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)

	local main = mk("Frame", {Name = "Main", Active = true, BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = UDim2.fromOffset(40, 40), Size = UDim2.fromOffset(500, 400)}, sg)
	-- sombra/contorno igual ao das janelas do Dex
	mk("ImageLabel", {Name = "Outlines", BackgroundTransparency = 1, BorderSizePixel = 0, Image = "rbxassetid://1427967925",
		Position = UDim2.new(0, -5, 0, -5), Size = UDim2.new(1, 10, 1, 10), ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(6, 6, 25, 25)}, main)
	mk("UICorner", {CornerRadius = UDim.new(0, 4)}, main)

	local content = mk("Frame", {Name = "Content", BackgroundColor3 = TH.Main2, BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, BAR), Size = UDim2.new(1, 0, 1, -BAR), ClipsDescendants = true}, main)

	local topBar = mk("TextButton", {Name = "TopBar", AutoButtonColor = false, BackgroundColor3 = TH.Main1, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, BAR), Text = "", Selectable = false}, main)
	local titleLabel = mk("TextLabel", {Name = "Title", BackgroundTransparency = 1, Position = UDim2.new(0, 5, 0, 0),
		Size = UDim2.new(1, -28, 0, BAR), Text = "Notepad", TextColor3 = TH.Text, Font = Enum.Font.SourceSans, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, topBar)

	local closeBtn = mk("TextButton", {Name = "Close", AutoButtonColor = false, BackgroundColor3 = TH.Important, BackgroundTransparency = 1,
		BorderSizePixel = 0, Position = UDim2.new(1, -18, 0, 2), Size = UDim2.fromOffset(16, 16), Text = "", Selectable = false}, topBar)
	mk("ImageLabel", {BackgroundTransparency = 1, Image = "rbxassetid://5054663650", Position = UDim2.fromOffset(3, 3),
		Size = UDim2.fromOffset(10, 10)}, closeBtn)
	mk("UICorner", {CornerRadius = UDim.new(0, 4)}, closeBtn)
	closeBtn.MouseEnter:Connect(function() closeBtn.BackgroundTransparency = 0 end)
	closeBtn.MouseLeave:Connect(function() closeBtn.BackgroundTransparency = 1 end)

	-- linha dos botoes (Copy | Paste), transparentes como no Notepad do Dex
	local function flatButton(text, xScale, ok)
		local b = mk("TextButton", {BackgroundColor3 = TH.ButtonHover, BackgroundTransparency = 1, BorderSizePixel = 0,
			AutoButtonColor = false, Position = UDim2.new(xScale, 0, 0, 0), Size = UDim2.new(0.5, 0, 0, ROW), Text = text,
			TextColor3 = ok and TH.Text or TH.Dim, Font = Enum.Font.SourceSans, TextSize = 14, Selectable = false}, content)
		if ok then
			b.MouseEnter:Connect(function() b.BackgroundColor3 = TH.ButtonHover; b.BackgroundTransparency = 0 end)
			b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
			b.MouseButton1Down:Connect(function() b.BackgroundColor3 = TH.ButtonPress; b.BackgroundTransparency = 0 end)
			b.MouseButton1Up:Connect(function() b.BackgroundColor3 = TH.ButtonHover end)
			b.InputEnded:Connect(function(i)
				if i.UserInputType == Enum.UserInputType.Touch then b.BackgroundTransparency = 1 end
			end)
		else
			b.Interactable = false
		end
		return b
	end
	local hasCopy = (env.setclipboard or env.toclipboard or setclipboard or toclipboard) ~= nil
	local hasPaste = (env.getclipboard or getclipboard) ~= nil
	local bCopy = flatButton("Copy", 0, hasCopy)
	local bPaste = flatButton("Paste", 0.5, hasPaste)
	mk("Frame", {BackgroundColor3 = TH.Outline1, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, ROW), Size = UDim2.new(1, 0, 0, 1)}, content)

	-- area do codigo: numeros de linha + rolagem
	local area = mk("Frame", {Name = "Area", BackgroundColor3 = TH.Back, BorderSizePixel = 0, ClipsDescendants = true,
		Position = UDim2.new(0, 0, 0, ROW + 1), Size = UDim2.new(1, 0, 1, -(ROW + 1))}, content)
	local fontSize = 14
	local gutterW = 34
	local gutter = mk("Frame", {Size = UDim2.new(0, gutterW, 1, 0), BackgroundColor3 = TH.Gutter, BorderSizePixel = 0, ClipsDescendants = true}, area)
	local gutterLabel = mk("TextLabel", {Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, Text = "1", TextColor3 = TH.LineNum, FontFace = CODE_FONT, TextSize = fontSize,
		TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Top}, gutter)
	local scroller = mk("ScrollingFrame", {Position = UDim2.new(0, gutterW, 0, 0), Size = UDim2.new(1, -gutterW, 1, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollingDirection = Enum.ScrollingDirection.XY, ScrollBarThickness = 6, ScrollBarImageColor3 = rgb(90, 90, 90)}, area)
	local box = mk("TextBox", {Name = "Code", Position = UDim2.new(0, 6, 0, 4), Size = UDim2.fromOffset(100, 100), AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1, Text = "", TextColor3 = TH.Code, FontFace = CODE_FONT, TextSize = fontSize, MultiLine = true,
		ClearTextOnFocus = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = 1, PlaceholderText = ""}, scroller)
	local hlLabel = mk("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", RichText = true,
		TextColor3 = TH.Code, FontFace = CODE_FONT, TextSize = fontSize, TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Active = false}, box)
	pcall(function() hlLabel.Interactable = false end)

	-- cantinho para redimensionar (como as bordas das janelas do Dex)
	local grip = mk("TextButton", {Name = "Resize", AnchorPoint = Vector2.new(1, 1), BackgroundTransparency = 1, Text = "",
		Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(18, 18), ZIndex = 10, AutoButtonColor = false, Selectable = false}, content)

	-- ---------- estado ----------
	local cur = {box = nil}
	local prevText, applying = "", false
	local lastCursor, lnCount, lnCache = 1, 0, ""
	local rect = {x = 40, y = 40, w = 500, h = 400}
	local placed = false

	local function lineNumbers(count)
		if count ~= lnCount then
			local t = table.create(count)
			for k = 1, count do t[k] = k end
			lnCache, lnCount = table.concat(t, "\n"), count
		end
		return lnCache
	end

	local function setGutterWidth(count)
		local w = 14 + #tostring(count) * math.ceil(fontSize * 0.5 + 1)
		w = math.max(w, 30)
		if w == gutterW then return end
		gutterW = w
		gutter.Size = UDim2.new(0, w, 1, 0)
		scroller.Position = UDim2.new(0, w, 0, 0)
		scroller.Size = UDim2.new(1, -w, 1, 0)
	end

	local function render(text)
		local _, nl = text:gsub("\n", "")
		gutterLabel.Text = lineNumbers(nl + 1)
		setGutterWidth(nl + 1)
		local useHl = #text <= HL_MAX
		box.TextTransparency = useHl and 1 or 0
		hlLabel.Visible = useHl
		if useHl then hlLabel.Text = highlight(text) end
	end

	local hlToken = 0
	local function renderSoon(text)
		if #text < 6000 then return render(text) end
		hlToken = hlToken + 1
		local v = hlToken
		task.delay(0.1, function() if v == hlToken then render(prevText) end end)
	end

	-- ---------- salvar no script (igual ao Studio Lite) ----------
	local saveToken = 0
	local function flushSave()
		local sb = cur.box
		if not sb then return end
		if not sb.Parent then cur.box = nil; return end
		local t = prevText
		if sb.RichText then t = esc(t) end
		sb.Text = t
	end
	local function scheduleSave()
		if not cur.box then return end
		saveToken = saveToken + 1
		local v = saveToken
		task.delay(0.35, function() if v == saveToken then flushSave() end end)
	end

	-- ---------- seguir o cursor ----------
	local function followCaret()
		if not box:IsFocused() then return end
		local c = box.CursorPosition
		if c < 1 then return end
		local before = prevText:sub(1, c - 1)
		local _, nl = before:gsub("\n", "")
		local lineStart = before:match(".*\n()") or 1
		local lh = box.TextBounds.Y / math.max(lnCount, 1)
		if lh <= 0 then return end
		local y = nl * lh
		local x = (c - lineStart) * box.TextSize * 0.5
		local pos, view = scroller.CanvasPosition, scroller.AbsoluteWindowSize
		local ny, nx = pos.Y, pos.X
		if y < ny then ny = y
		elseif y + lh + 8 > ny + view.Y then ny = y + lh + 8 - view.Y end
		if x < nx then nx = math.max(0, x - 20)
		elseif x + 30 > nx + view.X then nx = x + 30 - view.X end
		if nx ~= pos.X or ny ~= pos.Y then scroller.CanvasPosition = Vector2.new(nx, ny) end
	end

	-- ---------- mudancas no texto (auto-indent, tab -> espacos, salvar) ----------
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if applying then return end
		local t = box.Text
		local newT, cur2 = t, nil

		-- Enter: mantem a indentacao da linha anterior (+4 depois de then/do/function/...)
		if #t == #prevText + 1 then
			local p, m = 1, #prevText
			while p <= m and t:byte(p) == prevText:byte(p) do p = p + 1 end
			if t:sub(p, p) == "\n" and t:sub(p + 1) == prevText:sub(p) then
				local ls = p - 1
				while ls >= 1 and t:sub(ls, ls) ~= "\n" do ls = ls - 1 end
				local prevLine = t:sub(ls + 1, p - 1)
				local indent = prevLine:match("^[ \t]*") or ""
				local trimmed = (prevLine:gsub("%-%-.*$", "")):gsub("%s+$", "")
				if trimmed:match("%f[%w_]then$") or trimmed:match("%f[%w_]do$") or trimmed:match("%f[%w_]else$")
					or trimmed:match("%f[%w_]repeat$") or trimmed:match("%f[%w_]function[%w_%.:%s]*%b()$")
					or trimmed:match("[{%(]$") then
					indent = indent .. "    "
				end
				if #indent > 0 then
					newT = t:sub(1, p) .. indent .. t:sub(p + 1)
					cur2 = p + 1 + #indent
				end
			end
		end

		-- tab/CR (colar texto de outros lugares): vira espacos / some
		if newT:find("[\t\r]") then
			local c = cur2 or box.CursorPosition
			if c and c >= 1 then
				local before = newT:sub(1, c - 1)
				local _, tabs = before:gsub("\t", "")
				local _, crs = before:gsub("\r", "")
				cur2 = c + tabs * 3 - crs
			end
			newT = (newT:gsub("\r", ""):gsub("\t", "    "))
		end

		if newT ~= t then
			applying = true
			box.Text = newT
			if cur2 then box.CursorPosition = cur2 end
			applying = false
		end
		prevText = newT
		if cur2 then lastCursor = cur2 end
		renderSoon(newT)
		scheduleSave()
		task.defer(followCaret)
	end)

	box:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		local c = box.CursorPosition
		if c ~= -1 then
			lastCursor = c
			task.defer(followCaret)
		end
	end)

	-- numeros de linha acompanham a rolagem; a caixa de texto preenche a area visivel
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		gutterLabel.Position = UDim2.new(0, 0, 0, 4 - scroller.CanvasPosition.Y)
	end)
	local function syncMin()
		local s = scroller.AbsoluteSize
		box.Size = UDim2.fromOffset(math.max(s.X - 12, 50), math.max(s.Y - 8, 50))
	end
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncMin)
	syncMin()

	-- ---------- janela: posicao, tamanho, teclado do celular ----------
	local function applyRect()
		local vs = sg.AbsoluteSize
		if vs.X <= 0 or vs.Y <= 0 then return end
		local w = math.clamp(rect.w, MINW, math.max(vs.X, MINW))
		local h = math.clamp(rect.h, MINH, math.max(vs.Y, MINH))
		local x = math.clamp(rect.x, -(w - 60), math.max(vs.X - 60, 0))
		local y = math.clamp(rect.y, 0, math.max(vs.Y - BAR, 0))
		local kb = false
		pcall(function() kb = UIS.OnScreenKeyboardVisible end)
		if kb then
			local ok, kbY = pcall(function() return UIS.OnScreenKeyboardPosition.Y end)
			if ok and kbY and kbY > 0 then
				local avail = kbY - sg.AbsolutePosition.Y - 6
				y = 2
				h = math.max(math.min(h, avail), 120)
			end
		end
		main.Position = UDim2.fromOffset(x, y)
		main.Size = UDim2.fromOffset(w, h)
	end
	pcall(function() UIS:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(applyRect) end)
	pcall(function() UIS:GetPropertyChangedSignal("OnScreenKeyboardPosition"):Connect(applyRect) end)
	pcall(function() UIS:GetPropertyChangedSignal("OnScreenKeyboardSize"):Connect(applyRect) end)
	sg:GetPropertyChangedSignal("AbsoluteSize"):Connect(applyRect)

	local function isPointer(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
	end
	local drag = nil -- {mode, input, start, r}
	local function beginDrag(mode, input)
		drag = {mode = mode, input = input, start = input.Position, x = rect.x, y = rect.y, w = rect.w, h = rect.h}
		-- se o teclado encolheu a janela, parte do tamanho que o usuario esta vendo
		drag.w, drag.h = main.AbsoluteSize.X, main.AbsoluteSize.Y
	end
	topBar.InputBegan:Connect(function(i)
		if isPointer(i) then beginDrag("move", i) end
	end)
	grip.InputBegan:Connect(function(i)
		if isPointer(i) then beginDrag("size", i) end
	end)
	UIS.InputChanged:Connect(function(i)
		if not drag then return end
		if i == drag.input or (i.UserInputType == Enum.UserInputType.MouseMovement and drag.input.UserInputType == Enum.UserInputType.MouseButton1) then
			local d = i.Position - drag.start
			if drag.mode == "move" then
				rect.x, rect.y = drag.x + d.X, drag.y + d.Y
			else
				rect.w, rect.h = math.max(drag.w + d.X, MINW), math.max(drag.h + d.Y, MINH)
			end
			applyRect()
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if drag and (i == drag.input or (i.UserInputType == Enum.UserInputType.MouseButton1 and drag.input.UserInputType == Enum.UserInputType.MouseButton1)) then
			drag = nil
		end
	end)

	-- ---------- botoes: Copy / Paste ----------
	local function insertAtCursor(str)
		local t = prevText
		local pos = math.clamp(lastCursor, 1, #t + 1)
		box.Text = t:sub(1, pos - 1) .. str .. t:sub(pos)
		local np = pos + #str
		lastCursor = np
		box:CaptureFocus()
		task.defer(function() box.CursorPosition = np end)
	end

	local flashTok = {}
	local function flash(btn, msg, base)
		flashTok[btn] = (flashTok[btn] or 0) + 1
		local v = flashTok[btn]
		btn.Text = msg
		task.delay(1, function() if flashTok[btn] == v then btn.Text = base end end)
	end

	bCopy.MouseButton1Click:Connect(function()
		local sc = env.setclipboard or env.toclipboard or setclipboard or toclipboard
		if not sc then return flash(bCopy, "Copy (indisponivel)", "Copy") end
		local ok = pcall(sc, prevText)
		flash(bCopy, ok and "Copied!" or "Copy (erro)", "Copy")
	end)
	bPaste.MouseButton1Click:Connect(function()
		local gc = env.getclipboard or getclipboard
		if not gc then return flash(bPaste, "Paste (indisponivel)", "Paste") end
		local ok, s = pcall(gc)
		if ok and type(s) == "string" and #s > 0 then
			insertAtCursor(s)
			flash(bPaste, "Pasted!", "Paste")
		else
			flash(bPaste, "Clipboard vazio", "Paste")
		end
	end)

	-- ---------- API ----------
	local function Close()
		if cur.box then flushSave() end
		pcall(function() box:ReleaseFocus() end)
		sg.Enabled = false
	end
	closeBtn.MouseButton1Click:Connect(Close)

	-- opts: Title, Text, Box (SL_CodeTextBox para salvar), Focus
	local function Open(opts)
		opts = opts or {}
		if cur.box then flushSave() end
		cur.box = opts.Box
		titleLabel.Text = opts.Title and ("Notepad - " .. opts.Title) or "Notepad"
		local text = (tostring(opts.Text or ""):gsub("\r", ""):gsub("\t", "    "))
		applying = true
		box.Text = text
		applying = false
		prevText = text
		lastCursor = #text + 1
		saveToken = saveToken + 1
		sg.Enabled = true
		if not placed then
			placed = true
			local vs = sg.AbsoluteSize
			rect.w = math.min(500, math.max(vs.X - 20, MINW))
			rect.h = math.min(400, math.max(vs.Y - 20, MINH))
			rect.x = math.floor((vs.X - rect.w) / 2)
			rect.y = math.floor((vs.Y - rect.h) / 2)
		end
		applyRect()
		scroller.CanvasPosition = Vector2.zero
		render(text)
		if text == "" or opts.Focus then task.defer(function() box:CaptureFocus() end) end
	end

	env.DexPP_CodeEditor = {Open = Open, Close = Close}
end
local okEd, errEd = pcall(buildEditor)
if not okEd then warn("[DexBridge] Code Editor:", errEd) end
