-- Code Editor (substitui o Notepad do Dex): mobile, realce de sintaxe, salva no SL_CodeTextBox.
local ctx = ...
local UIS, lp = ctx.UIS, ctx.lp

-- 3b) Code Editor (substitui o Notepad do Dex): feito para mobile e ligado ao SL_CodeTextBox
local function buildEditor()
	local UIS_ = UIS
	local THEME = {
		bg = Color3.fromRGB(24, 25, 29),
		bar = Color3.fromRGB(31, 33, 38),
		gutter = Color3.fromRGB(27, 29, 33),
		btn = Color3.fromRGB(43, 46, 53),
		text = Color3.fromRGB(232, 234, 238),
		dim = Color3.fromRGB(139, 145, 156),
		accent = Color3.fromRGB(67, 133, 235),
		ok = Color3.fromRGB(111, 205, 145),
		bad = Color3.fromRGB(231, 92, 92),
	}
	local C = {keyword = "#F86D7C", string = "#ADF195", number = "#FFC600", comment = "#7B8394",
		builtin = "#84D6F7", func = "#FDFBAC", const = "#FFC600"}
	local HL_MAX = 12000 -- acima disso o realce desliga sozinho (limite de texto do RichText)
	local TOP, SYM, STAT = 40, 32, 18

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

	-- ---------- interface ----------
	local function mk(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end
	local CODE_FONT = Font.new("rbxasset://fonts/families/Inconsolata.json")

	local sg = mk("ScreenGui", {Name = "DexPP_CodeEditor", ResetOnSpawn = false, DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, lp:WaitForChild("PlayerGui"))
	pcall(function() sg.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)

	local main = mk("Frame", {Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.96, 0.94), BackgroundColor3 = THEME.bg, BorderSizePixel = 0}, sg)
	mk("UISizeConstraint", {MaxSize = Vector2.new(1100, 760), MinSize = Vector2.new(260, 150)}, main)
	mk("UICorner", {CornerRadius = UDim.new(0, 8)}, main)

	-- barra de cima: titulo + ferramentas rolaveis + fechar
	local topBar = mk("Frame", {Size = UDim2.new(1, 0, 0, TOP), BackgroundColor3 = THEME.bar, BorderSizePixel = 0}, main)
	mk("UICorner", {CornerRadius = UDim.new(0, 8)}, topBar)
	mk("Frame", {Name = "AccentLine", Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = THEME.accent, BackgroundTransparency = 0.35, BorderSizePixel = 0}, topBar)
	local titleLabel = mk("TextLabel", {Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0, 112, 1, 0), BackgroundTransparency = 1,
		Text = "Dex | Notepad", TextColor3 = THEME.text, Font = Enum.Font.GothamBold, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd}, topBar)
	local closeBtn = mk("TextButton", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.new(0, 36, 1, -8),
		BackgroundColor3 = THEME.bad, Text = "X", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14,
		Selectable = false}, topBar)
	mk("UICorner", {CornerRadius = UDim.new(0, 5)}, closeBtn)
	local toolbar = mk("ScrollingFrame", {Position = UDim2.new(0, 124, 0, 0), Size = UDim2.new(1, -168, 1, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0}, topBar)
	mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, toolbar)

	local function barButton(parent, text, order, minW, color)
		local b = mk("TextButton", {Text = text, Size = UDim2.new(0, minW or 0, 1, -8), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = color or THEME.btn, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
			LayoutOrder = order, Selectable = false, AutoButtonColor = true}, parent)
		mk("UICorner", {CornerRadius = UDim.new(0, 5)}, b)
		mk("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, b)
		return b
	end

	-- area do codigo: numeros de linha + rolagem
	local area = mk("Frame", {Position = UDim2.new(0, 0, 0, TOP), Size = UDim2.new(1, 0, 1, -(TOP + SYM + STAT)),
		BackgroundTransparency = 1, ClipsDescendants = true}, main)
	local gutter = mk("Frame", {Size = UDim2.new(0, 42, 1, 0), BackgroundColor3 = THEME.gutter, BorderSizePixel = 0, ClipsDescendants = true}, area)
	local gutterLabel = mk("TextLabel", {Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, Text = "1", TextColor3 = THEME.dim, FontFace = CODE_FONT, TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Top}, gutter)
	local scroller = mk("ScrollingFrame", {Position = UDim2.new(0, 42, 0, 0), Size = UDim2.new(1, -42, 1, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollingDirection = Enum.ScrollingDirection.XY, ScrollBarThickness = 6}, area)
	local box = mk("TextBox", {Name = "Code", Position = UDim2.new(0, 6, 0, 4), Size = UDim2.fromOffset(100, 100), AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1, Text = "", TextColor3 = THEME.text, FontFace = CODE_FONT, TextSize = 15, MultiLine = true,
		ClearTextOnFocus = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = 1, PlaceholderText = ""}, scroller)
	local hlLabel = mk("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", RichText = true,
		TextColor3 = THEME.text, FontFace = CODE_FONT, TextSize = 15, TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Active = false}, box)
	pcall(function() hlLabel.Interactable = false end)

	-- barra de simbolos (teclado mobile ajuda)
	local symBar = mk("ScrollingFrame", {Position = UDim2.new(0, 0, 1, -(SYM + STAT)), Size = UDim2.new(1, 0, 0, SYM), BackgroundColor3 = THEME.bar,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0}, main)
	mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, symBar)
	mk("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6)}, symBar)

	local statBar = mk("Frame", {Position = UDim2.new(0, 0, 1, -STAT), Size = UDim2.new(1, 0, 0, STAT), BackgroundColor3 = THEME.bar, BorderSizePixel = 0}, main)
	mk("UICorner", {CornerRadius = UDim.new(0, 8)}, statBar)
	local statusLabel = mk("TextLabel", {Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(0.62, -10, 1, 0), BackgroundTransparency = 1,
		Text = "", TextColor3 = THEME.dim, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd}, statBar)
	local infoLabel = mk("TextLabel", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.38, 0, 1, 0),
		BackgroundTransparency = 1, Text = "", TextColor3 = THEME.dim, Font = Enum.Font.Gotham, TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right}, statBar)

	local function setStatus(msg, color)
		statusLabel.Text = msg
		statusLabel.TextColor3 = color or THEME.dim
	end

	-- ---------- estado ----------
	local cur = {box = nil}
	local prevText, applying = "", false
	local hlEnabled, fontSize = true, 15
	local lastCursor, lnCount, lnCache = 1, 0, ""
	local hist, hi, lastPush = {""}, 1, 0

	local function lineNumbers(count)
		if count ~= lnCount then
			local t = table.create(count)
			for k = 1, count do t[k] = k end
			lnCache, lnCount = table.concat(t, "\n"), count
		end
		return lnCache
	end

	local function updateInfo()
		local line = 1
		if #prevText <= 60000 and lastCursor > 1 then
			local _, nl = prevText:sub(1, lastCursor - 1):gsub("\n", "")
			line = nl + 1
		end
		infoLabel.Text = ("Ln %d/%d | %d car"):format(line, lnCount, #prevText)
	end

	local function render(text)
		local _, nl = text:gsub("\n", "")
		gutterLabel.Text = lineNumbers(nl + 1)
		local useHl = hlEnabled and #text <= HL_MAX
		box.TextTransparency = useHl and 1 or 0
		hlLabel.Visible = useHl
		if useHl then hlLabel.Text = highlight(text) end
		updateInfo()
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
		if not sb.Parent then
			cur.box = nil
			return setStatus("Script removido; nada ligado", THEME.bad)
		end
		local t = prevText
		if sb.RichText then t = esc(t) end
		sb.Text = t
		setStatus("Salvo no script", THEME.ok)
	end
	local function scheduleSave()
		if not cur.box then return end
		saveToken = saveToken + 1
		local v = saveToken
		setStatus("Salvando...", THEME.dim)
		task.delay(0.35, function() if v == saveToken then flushSave() end end)
	end

	-- ---------- historico (desfazer/refazer) ----------
	local function pushHistory(t)
		if hist[hi] == t then return end
		for k = #hist, hi + 1, -1 do hist[k] = nil end
		if os.clock() - lastPush < 0.7 and hi > 1 then
			hist[hi] = t
		else
			hist[#hist + 1] = t
			hi = #hist
		end
		lastPush = os.clock()
		local maxN = #t > 100000 and 10 or 80
		while #hist > maxN do table.remove(hist, 1); hi = hi - 1 end
	end

	local function setTextSilent(t)
		applying = true
		box.Text = t
		applying = false
		prevText = t
		render(t)
		scheduleSave()
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

	-- ---------- mudancas no texto (auto-indent, tab -> espacos, historico, salvar) ----------
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
		pushHistory(newT)
		scheduleSave()
		task.defer(followCaret)
	end)

	box:GetPropertyChangedSignal("CursorPosition"):Connect(function()
		local c = box.CursorPosition
		if c ~= -1 then
			lastCursor = c
			updateInfo()
			task.defer(followCaret)
		end
	end)

	-- numeros de linha acompanham a rolagem vertical; caixa de texto preenche a area visivel
	local function syncGutter()
		gutterLabel.Position = UDim2.new(0, 0, 0, 4 - scroller.CanvasPosition.Y)
	end
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(syncGutter)
	local function syncMin()
		local s = scroller.AbsoluteSize
		box.Size = UDim2.fromOffset(math.max(s.X - 12, 50), math.max(s.Y - 8, 50))
	end
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncMin)
	syncMin()

	-- ---------- botoes ----------
	local function insertAtCursor(str)
		local t = prevText
		local pos = math.clamp(lastCursor, 1, #t + 1)
		box.Text = t:sub(1, pos - 1) .. str .. t:sub(pos)
		local np = pos + #str
		lastCursor = np
		box:CaptureFocus()
		task.defer(function() box.CursorPosition = np end)
	end

	local function applySize()
		box.TextSize, hlLabel.TextSize, gutterLabel.TextSize = fontSize, fontSize, fontSize
		task.defer(function() render(prevText) end)
	end

	local bRun = barButton(toolbar, "Executar", 1, 0, THEME.accent)
	local bUndo = barButton(toolbar, "Desfazer", 2)
	local bRedo = barButton(toolbar, "Refazer", 3)
	local bCopy = barButton(toolbar, "Copiar", 4)
	local bPaste = barButton(toolbar, "Colar", 5)
	local bClear = barButton(toolbar, "Limpar", 6)
	local bPlus = barButton(toolbar, "A+", 7, 36)
	local bMinus = barButton(toolbar, "A-", 8, 36)
	local bHl = barButton(toolbar, "Realce: ON", 9)

	bRun.Activated:Connect(function()
		local ls = (getgenv and getgenv().loadstring) or loadstring
		if not ls then return setStatus("loadstring indisponivel neste executor", THEME.bad) end
		local ok, f, err = pcall(ls, prevText)
		if not ok or not f then
			local msg = tostring(ok and err or f)
			warn("[CodeEditor] " .. msg)
			return setStatus("Erro: " .. msg:sub(1, 140), THEME.bad)
		end
		task.spawn(f)
		setStatus("Executado", THEME.ok)
	end)
	bUndo.Activated:Connect(function()
		if hi > 1 then hi = hi - 1; lastPush = 0; setTextSilent(hist[hi]); lastCursor = #prevText + 1 end
	end)
	bRedo.Activated:Connect(function()
		if hi < #hist then hi = hi + 1; lastPush = 0; setTextSilent(hist[hi]); lastCursor = #prevText + 1 end
	end)
	bCopy.Activated:Connect(function()
		local sc = (getgenv and (getgenv().setclipboard or getgenv().toclipboard)) or setclipboard or toclipboard
		if not sc then return setStatus("Sem suporte a clipboard (segure no texto para copiar)", THEME.bad) end
		pcall(sc, prevText)
		setStatus("Codigo copiado", THEME.ok)
	end)
	bPaste.Activated:Connect(function()
		local gc = (getgenv and getgenv().getclipboard) or getclipboard
		if not gc then return setStatus("Sem getclipboard: segure no texto e use Colar do teclado", THEME.bad) end
		local ok, s = pcall(gc)
		if ok and type(s) == "string" and #s > 0 then insertAtCursor(s) end
	end)
	bClear.Activated:Connect(function()
		box.Text = ""
		lastCursor = 1
		setStatus("Limpo (use Desfazer para voltar)", THEME.dim)
	end)
	bPlus.Activated:Connect(function() fontSize = math.min(fontSize + 1, 26); applySize() end)
	bMinus.Activated:Connect(function() fontSize = math.max(fontSize - 1, 10); applySize() end)
	bHl.Activated:Connect(function()
		hlEnabled = not hlEnabled
		bHl.Text = hlEnabled and "Realce: ON" or "Realce: OFF"
		render(prevText)
	end)

	local symbols = {"Tab", "(", ")", "[", "]", "{", "}", '"', "'", "=", "==", "~=", ".", ",", ":", ";", "#", "+", "-", "*", "/", "%", "<", ">", "_",
		"local", "function", "end", "then", "do", "if", "return"}
	for idx, s in ipairs(symbols) do
		local b = barButton(symBar, s, idx, 34)
		b.Size = UDim2.new(0, 34, 1, -8)
		b.TextSize = 14
		b.Activated:Connect(function() insertAtCursor(s == "Tab" and "    " or s) end)
	end

	-- ---------- layout: acompanha o teclado do celular ----------
	local function layout()
		local kb = false
		pcall(function() kb = UIS_.OnScreenKeyboardVisible end)
		statBar.Visible = not kb
		local bottom = kb and SYM or (SYM + STAT)
		area.Size = UDim2.new(1, 0, 1, -(TOP + bottom))
		symBar.Position = UDim2.new(0, 0, 1, -bottom)
		if kb then
			local ok, kbY = pcall(function() return UIS_.OnScreenKeyboardPosition.Y end)
			if ok then
				local avail = kbY - sg.AbsolutePosition.Y - 8
				main.AnchorPoint = Vector2.new(0.5, 0)
				main.Position = UDim2.new(0.5, 0, 0, 4)
				main.Size = UDim2.new(0.98, 0, 0, math.max(avail, 150))
				return
			end
		end
		main.AnchorPoint = Vector2.new(0.5, 0.5)
		main.Position = UDim2.fromScale(0.5, 0.5)
		main.Size = UDim2.fromScale(0.96, 0.94)
	end
	pcall(function() UIS_:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(layout) end)
	pcall(function() UIS_:GetPropertyChangedSignal("OnScreenKeyboardPosition"):Connect(layout) end)
	pcall(function() UIS_:GetPropertyChangedSignal("OnScreenKeyboardSize"):Connect(layout) end)

	-- ---------- API ----------
	local function Close()
		if cur.box then flushSave() end
		pcall(function() box:ReleaseFocus() end)
		sg.Enabled = false
	end
	closeBtn.Activated:Connect(Close)

	-- opts: Title, Text, Box (SL_CodeTextBox para salvar), Focus
	local function Open(opts)
		opts = opts or {}
		if cur.box then flushSave() end
		cur.box = opts.Box
		titleLabel.Text = opts.Title or "Dex | Notepad"
		local text = (tostring(opts.Text or ""):gsub("\r", ""):gsub("\t", "    "))
		applying = true
		box.Text = text
		applying = false
		prevText = text
		hist, hi, lastPush = {text}, 1, 0
		lastCursor = #text + 1
		saveToken = saveToken + 1
		sg.Enabled = true
		layout()
		scroller.CanvasPosition = Vector2.zero
		render(text)
		if cur.box then
			setStatus("Ligado ao script: salva sozinho", THEME.dim)
		else
			setStatus("Sem script ligado: use Executar ou Copiar", THEME.dim)
		end
		if text == "" or opts.Focus then task.defer(function() box:CaptureFocus() end) end
	end

	applySize()
	getgenv().DexPP_CodeEditor = {Open = Open, Close = Close}
end
local okEd, errEd = pcall(buildEditor)
if not okEd then warn("[DexBridge] Code Editor:", errEd) end
