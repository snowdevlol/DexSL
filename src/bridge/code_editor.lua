-- Code Editor no estilo do Dex++ (Notepad): janela com barra de titulo, botoes planos em cima/embaixo,
-- realce de sintaxe com as cores do tema do Dex, linha atual destacada e autosave no SL_CodeTextBox.
-- API: getgenv().DexPP_CodeEditor = {Open = function(opts), Close = function()}
--      opts: Title, Text, Box (SL_CodeTextBox para salvar), Focus
local ctx = ...
local UIS, lp = ctx.UIS, ctx.lp

local function buildEditor()
	local rgb = Color3.fromRGB

	-- ---------- tema (mesmos valores de Settings.Theme do Dex++) ----------
	local T = {
		main1 = rgb(52, 52, 52),     -- barra de titulo
		main2 = rgb(45, 45, 45),     -- corpo da janela
		outline = rgb(33, 33, 33),
		button = rgb(60, 60, 60),
		hover = rgb(68, 68, 68),
		press = rgb(40, 40, 40),
		select = rgb(11, 90, 175),
		text = rgb(255, 255, 255),
		dim = rgb(150, 150, 150),
		bg = rgb(36, 36, 36),        -- fundo do codigo
		code = rgb(204, 204, 204),
		curLine = rgb(45, 50, 65),
		ok = rgb(110, 220, 140),
		bad = rgb(255, 110, 110),
	}
	-- cores do realce (Settings.Theme.Syntax)
	local C = {keyword = "#F86D7C", string = "#ADF195", number = "#FFC600", comment = "#666666",
		builtin = "#84D6F7", func = "#FDFBAC", const = "#FFC600", prop = "#61A1F1"}

	local HL_MAX = 12000 -- acima disso o realce desliga sozinho (limite de texto do RichText)
	local TOP, MENU, SYM, BOT = 24, 24, 28, 24
	local MIN_W, MIN_H, MIN_H_KB = 300, 200, 120
	local UIFONT = Enum.Font.SourceSans
	local CODE_FONT = Font.new("rbxasset://fonts/families/Inconsolata.json")

	-- ---------- realce de sintaxe Lua ----------
	local KW, CONST, BUILTIN = {}, {}, {}
	for w in ("and break do else elseif end for function goto if in local not or repeat return then until while continue"):gmatch("[%w_]+") do KW[w] = true end
	for w in ("true false nil"):gmatch("[%w_]+") do CONST[w] = true end
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
					local prev = src:sub(i - 1, i - 1)
					local isField = (prev == "." and src:sub(i - 2, i - 2) ~= ".") or prev == ":"
					local called = src:find("^%s*%(", e + 1) ~= nil
					if w == "self" then color = C.keyword
					elseif CONST[w] then color = C.const
					elseif afterFunction then color = C.func
					elseif isField then color = called and C.func or C.prop
					elseif BUILTIN[w] then color = C.builtin
					elseif called then color = C.func end
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

	-- ---------- helpers de interface ----------
	local function mk(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end
	local function isPress(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
	end

	-- botao "plano" do Dex: transparente, acende no hover, escurece ao apertar
	local function flat(parent, text, props)
		local b = mk("TextButton", {Text = text, BackgroundColor3 = T.hover, BackgroundTransparency = 1, BorderSizePixel = 0,
			TextColor3 = T.text, Font = UIFONT, TextSize = 16, AutoButtonColor = false, Selectable = false}, parent)
		for k, v in pairs(props or {}) do b[k] = v end
		local down = false
		b.MouseEnter:Connect(function() if not down then b.BackgroundColor3 = T.hover; b.BackgroundTransparency = 0 end end)
		b.MouseLeave:Connect(function() down = false; b.BackgroundTransparency = 1 end)
		b.InputBegan:Connect(function(i) if isPress(i) then down = true; b.BackgroundColor3 = T.press; b.BackgroundTransparency = 0 end end)
		b.InputEnded:Connect(function(i) if isPress(i) then down = false; b.BackgroundTransparency = 1 end end)
		return b
	end

	-- arrasta/redimensiona (mouse e toque)
	local function dragHandle(handle, onStart, onMove)
		handle.InputBegan:Connect(function(input)
			if not isPress(input) then return end
			local origin = input.Position
			onStart()
			local conn, chg
			conn = UIS.InputChanged:Connect(function(i)
				if i == input or i.UserInputType == Enum.UserInputType.MouseMovement then
					local d = i.Position - origin
					onMove(d.X, d.Y)
				end
			end)
			chg = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					conn:Disconnect(); chg:Disconnect()
				end
			end)
		end)
	end

	-- ---------- janela ----------
	local sg = mk("ScreenGui", {Name = "DexPP_CodeEditor", ResetOnSpawn = false, DisplayOrder = 1000,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false}, lp:WaitForChild("PlayerGui"))
	pcall(function() sg.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)

	local main = mk("Frame", {Name = "Main", Position = UDim2.fromOffset(20, 20), Size = UDim2.fromOffset(500, 360),
		BackgroundColor3 = T.main2, BorderSizePixel = 0, Active = true}, sg)
	mk("UICorner", {CornerRadius = UDim.new(0, 4)}, main)
	mk("UIStroke", {Color = T.outline, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, main)

	-- barra de titulo (arrasta a janela)
	local topBar = mk("TextButton", {Name = "TopBar", Size = UDim2.new(1, 0, 0, TOP), BackgroundColor3 = T.main1, BorderSizePixel = 0,
		AutoButtonColor = false, Text = "", Selectable = false}, main)
	mk("UICorner", {CornerRadius = UDim.new(0, 4)}, topBar)
	mk("Frame", {Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = T.main1, BorderSizePixel = 0}, topBar)
	local titleLabel = mk("TextLabel", {Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0.5, -8, 1, 0), BackgroundTransparency = 1,
		Text = "Notepad", TextColor3 = T.text, Font = UIFONT, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd}, topBar)
	local statusLabel = mk("TextLabel", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -56, 0, 0), Size = UDim2.new(0.5, -60, 1, 0),
		BackgroundTransparency = 1, Text = "", TextColor3 = T.dim, Font = UIFONT, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd}, topBar)

	local function topButton(x, image, hoverColor)
		local b = mk("TextButton", {Position = UDim2.new(1, x, 0, 2), Size = UDim2.new(0, 22, 0, TOP - 4), BackgroundColor3 = hoverColor,
			BackgroundTransparency = 1, BorderSizePixel = 0, AutoButtonColor = false, Text = "", Selectable = false}, topBar)
		mk("UICorner", {CornerRadius = UDim.new(0, 4)}, b)
		mk("ImageLabel", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(10, 10),
			BackgroundTransparency = 1, Image = image}, b)
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		return b
	end
	local closeBtn = topButton(-26, "rbxassetid://5054663650", rgb(196, 43, 28))
	local minBtn = topButton(-50, "rbxassetid://5034768003", rgb(75, 75, 75))

	-- corpo (tudo abaixo da barra de titulo)
	local body = mk("Frame", {Name = "Body", Position = UDim2.new(0, 0, 0, TOP), Size = UDim2.new(1, 0, 1, -TOP),
		BackgroundTransparency = 1, ClipsDescendants = true}, main)
	mk("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.outline, BorderSizePixel = 0, ZIndex = 5}, body)

	-- linha de botoes do topo (estilo Notepad)
	local menu = mk("ScrollingFrame", {Position = UDim2.new(0, 0, 0, 1), Size = UDim2.new(1, 0, 0, MENU), BackgroundTransparency = 1,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0}, body)
	mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, menu)
	local function menuButton(text, order)
		local b = flat(menu, text, {Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, LayoutOrder = order})
		mk("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, b)
		return b
	end

	-- area do codigo: linha atual + numeros de linha + rolagem
	local area = mk("Frame", {Position = UDim2.new(0, 0, 0, MENU + 1), Size = UDim2.new(1, 0, 1, -(MENU + 1 + SYM + BOT)),
		BackgroundColor3 = T.bg, BorderSizePixel = 0, ClipsDescendants = true}, body)
	local curLine = mk("Frame", {BackgroundColor3 = T.curLine, BorderSizePixel = 0, Visible = false}, area)
	local gutterW = 34
	local gutter = mk("Frame", {Size = UDim2.new(0, gutterW, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true}, area)
	local gutterLabel = mk("TextLabel", {Position = UDim2.new(0, 0, 0, 4), Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1, Text = "1", TextColor3 = T.code, FontFace = CODE_FONT, TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Top}, gutter)
	local gutterLine = mk("Frame", {Position = UDim2.new(0, gutterW, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.main1, BorderSizePixel = 0}, area)
	local scroller = mk("ScrollingFrame", {Position = UDim2.new(0, gutterW + 1, 0, 0), Size = UDim2.new(1, -(gutterW + 1), 1, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.XY,
		ScrollingDirection = Enum.ScrollingDirection.XY, ScrollBarThickness = 8,
		ScrollBarImageColor3 = rgb(90, 90, 90)}, area)
	local box = mk("TextBox", {Name = "Code", Position = UDim2.new(0, 6, 0, 4), Size = UDim2.fromOffset(100, 100), AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1, Text = "", TextColor3 = T.code, FontFace = CODE_FONT, TextSize = 16, MultiLine = true,
		ClearTextOnFocus = false, TextWrapped = false, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = 1, PlaceholderText = ""}, scroller)
	local hlLabel = mk("TextLabel", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", RichText = true,
		TextColor3 = T.code, FontFace = CODE_FONT, TextSize = 16, TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Active = false}, box)
	pcall(function() hlLabel.Interactable = false end)

	-- barra de simbolos (ajuda no teclado do celular)
	local symBar = mk("ScrollingFrame", {Position = UDim2.new(0, 0, 1, -(SYM + BOT)), Size = UDim2.new(1, 0, 0, SYM), BackgroundColor3 = T.main2,
		BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.X,
		ScrollingDirection = Enum.ScrollingDirection.X, ScrollBarThickness = 0}, body)
	mk("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3),
		VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}, symBar)
	mk("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4)}, symBar)
	mk("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.outline, BorderSizePixel = 0, ZIndex = 5}, symBar)

	-- barra de baixo: Execute | Clear (igual ao Notepad) + posicao do cursor
	local bottomBar = mk("Frame", {Position = UDim2.new(0, 0, 1, -BOT), Size = UDim2.new(1, 0, 0, BOT), BackgroundColor3 = T.main2, BorderSizePixel = 0}, body)
	mk("Frame", {Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.outline, BorderSizePixel = 0}, bottomBar)
	local bExec = flat(bottomBar, "Execute", {Position = UDim2.new(0, 0, 0, 1), Size = UDim2.new(0.3, 0, 1, -1)})
	local bClear = flat(bottomBar, "Clear", {Position = UDim2.new(0.3, 0, 0, 1), Size = UDim2.new(0.3, 0, 1, -1)})
	local infoLabel = mk("TextLabel", {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 1), Size = UDim2.new(0.4, -24, 1, -1),
		BackgroundTransparency = 1, Text = "", TextColor3 = T.dim, Font = UIFONT, TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Right}, bottomBar)

	-- cantinho para redimensionar
	local grip = mk("TextButton", {AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Selectable = false, ZIndex = 10}, main)
	for k = 0, 1 do
		mk("Frame", {AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 3 + k * 4, 0.5, 3 + k * 4), Size = UDim2.fromOffset(2, 12 - k * 6),
			BackgroundColor3 = T.dim, BorderSizePixel = 0, Rotation = 45, ZIndex = 10}, grip)
	end

	local function setStatus(msg, color)
		statusLabel.Text = msg
		statusLabel.TextColor3 = color or T.dim
	end

	-- ---------- estado ----------
	local cur = {box = nil}
	local prevText, applying = "", false
	local hlEnabled, fontSize = true, 16
	local lastCursor, lnCount, lnCache = 1, 0, ""
	local curLineNo = 1
	local hist, hi, lastPush = {""}, 1, 0
	local win = {x = 20, y = 20, w = 500, h = 360, init = false}
	local minimized, kbVisible = false, false
	local bExecKb -- botao Execute do menu (so com o teclado aberto)

	local function lineNumbers(count)
		if count ~= lnCount then
			local t = table.create(count)
			for k = 1, count do t[k] = k end
			lnCache, lnCount = table.concat(t, "\n"), count
		end
		return lnCache
	end

	local function lineH()
		local h = gutterLabel.TextBounds.Y / math.max(lnCount, 1)
		if h <= 0 then h = fontSize * 1.2 end
		return h
	end

	-- destaque da linha atual (como o CurrentLine do Dex)
	local function updateCurLine()
		local focused = false
		pcall(function() focused = box:IsFocused() end)
		if not focused or lnCount == 0 then curLine.Visible = false return end
		local lh = lineH()
		curLine.Size = UDim2.new(1, -gutterW, 0, lh)
		curLine.Position = UDim2.new(0, gutterW, 0, 4 - scroller.CanvasPosition.Y + (curLineNo - 1) * lh)
		curLine.Visible = true
	end

	local function updateInfo()
		local line, col = 1, 1
		if #prevText <= 60000 and lastCursor > 1 then
			local before = prevText:sub(1, lastCursor - 1)
			local _, nl = before:gsub("\n", "")
			line = nl + 1
			col = lastCursor - (before:match(".*\n()") or 1) + 1
		end
		curLineNo = line
		infoLabel.Text = ("Ln %d/%d  Col %d  (%d chars)"):format(line, lnCount, col, #prevText)
		updateCurLine()
	end

	-- largura da coluna de numeros acompanha a quantidade de digitos
	local function layoutGutter()
		gutter.Size = UDim2.new(0, gutterW, 1, 0)
		gutterLine.Position = UDim2.new(0, gutterW, 0, 0)
		scroller.Position = UDim2.new(0, gutterW + 1, 0, 0)
		scroller.Size = UDim2.new(1, -(gutterW + 1), 1, 0)
	end

	local function render(text)
		local _, nl = text:gsub("\n", "")
		gutterLabel.Text = lineNumbers(nl + 1)
		local w = math.max(34, 14 + #tostring(nl + 1) * math.floor(fontSize * 0.56 + 0.5))
		if w ~= gutterW then gutterW = w; layoutGutter() end
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
			return setStatus("Script removed; nothing linked", T.bad)
		end
		local t = prevText
		if sb.RichText then t = esc(t) end
		sb.Text = t
		setStatus("Saved to script", T.ok)
	end
	local function scheduleSave()
		if not cur.box then return end
		saveToken = saveToken + 1
		local v = saveToken
		setStatus("Saving...", T.dim)
		task.delay(0.35, function() if v == saveToken then flushSave() end end)
	end

	-- ---------- historico (undo/redo) ----------
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
	box.Focused:Connect(function() updateInfo() end)
	box.FocusLost:Connect(function() updateCurLine() end)

	-- numeros de linha acompanham a rolagem vertical; caixa de texto preenche a area visivel
	local function syncGutter()
		gutterLabel.Position = UDim2.new(0, 0, 0, 4 - scroller.CanvasPosition.Y)
		updateCurLine()
	end
	scroller:GetPropertyChangedSignal("CanvasPosition"):Connect(syncGutter)
	local function syncMin()
		local s = scroller.AbsoluteSize
		box.Size = UDim2.fromOffset(math.max(s.X - 12, 50), math.max(s.Y - 8, 50))
	end
	scroller:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncMin)
	syncMin()

	-- ---------- layout: janela arrastavel/redimensionavel e teclado do celular ----------
	local function screenSize()
		local s = sg.AbsoluteSize
		if s.X < 50 or s.Y < 50 then
			local cam = workspace.CurrentCamera
			s = cam and cam.ViewportSize or Vector2.new(800, 600)
		end
		return s
	end

	local function layout()
		kbVisible = false
		pcall(function() kbVisible = UIS.OnScreenKeyboardVisible end)
		local s = screenSize()
		local w = math.clamp(win.w, MIN_W, math.max(s.X - 4, MIN_W))
		local h = math.clamp(win.h, MIN_H, math.max(s.Y - 4, MIN_H))
		local y
		if minimized then
			h = TOP
		elseif kbVisible then
			local ok, kbY = pcall(function() return UIS.OnScreenKeyboardPosition.Y end)
			if ok then
				y = 2
				h = math.clamp(kbY - sg.AbsolutePosition.Y - 4, MIN_H_KB, s.Y)
			end
		end
		local x = math.clamp(win.x, 0, math.max(s.X - w, 0))
		y = y or math.clamp(win.y, 0, math.max(s.Y - h, 0))
		main.Position = UDim2.fromOffset(x, y)
		main.Size = UDim2.fromOffset(w, h)

		body.Visible = not minimized
		grip.Visible = not minimized and not kbVisible
		bottomBar.Visible = not kbVisible
		if bExecKb then bExecKb.Visible = kbVisible end
		local bot = kbVisible and 0 or BOT
		area.Size = UDim2.new(1, 0, 1, -(MENU + 1 + SYM + bot))
		symBar.Position = UDim2.new(0, 0, 1, -(SYM + bot))
	end
	pcall(function() UIS:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(layout) end)
	pcall(function() UIS:GetPropertyChangedSignal("OnScreenKeyboardPosition"):Connect(layout) end)
	pcall(function() UIS:GetPropertyChangedSignal("OnScreenKeyboardSize"):Connect(layout) end)

	local d0, r0
	dragHandle(topBar, function() d0 = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset) end, function(dx, dy)
		win.x, win.y = d0.X + dx, d0.Y + dy
		layout()
	end)
	dragHandle(grip, function() r0 = Vector2.new(main.Size.X.Offset, main.Size.Y.Offset) end, function(dx, dy)
		local s = screenSize()
		win.w = math.clamp(r0.X + dx, MIN_W, math.max(s.X - win.x, MIN_W))
		win.h = math.clamp(r0.Y + dy, MIN_H, math.max(s.Y - win.y, MIN_H))
		layout()
	end)

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

	local function runCode()
		local ls = (getgenv and getgenv().loadstring) or loadstring
		if not ls then return setStatus("loadstring unavailable in this executor", T.bad) end
		local ok, f, err = pcall(ls, prevText)
		if not ok or not f then
			local msg = tostring(ok and err or f)
			warn("[CodeEditor] " .. msg)
			return setStatus("Error: " .. msg:sub(1, 140), T.bad)
		end
		task.spawn(f)
		setStatus("Executed", T.ok)
	end

	local function clearText()
		box.Text = ""
		lastCursor = 1
		setStatus("Cleared (use Undo to restore)", T.dim)
	end

	-- menu do topo (Notepad: Copy to Clipboard | Save to File | ...)
	bExecKb = menuButton("Execute", 0) -- so aparece com o teclado aberto (a barra de baixo some)
	bExecKb.Visible = false
	local bCopy = menuButton("Copy to Clipboard", 1)
	local bPaste = menuButton("Paste", 2)
	local bSave = menuButton("Save to File", 3)
	local bUndo = menuButton("Undo", 4)
	local bRedo = menuButton("Redo", 5)
	local bPlus = menuButton("A+", 6)
	local bMinus = menuButton("A-", 7)
	local bHl = menuButton("Highlight: ON", 8)

	-- botoes sem suporte ficam cinza, como no Dex
	local envf = (getgenv and getgenv()) or {}
	local setclip = envf.setclipboard or envf.toclipboard or setclipboard or toclipboard
	local getclip = envf.getclipboard or getclipboard
	local writef = envf.writefile or writefile
	if not setclip then bCopy.TextColor3 = rgb(128, 128, 128) end
	if not getclip then bPaste.TextColor3 = rgb(128, 128, 128) end
	if not writef then bSave.TextColor3 = rgb(128, 128, 128) end

	bExec.Activated:Connect(runCode)
	bExecKb.Activated:Connect(runCode)
	bClear.Activated:Connect(clearText)
	bCopy.Activated:Connect(function()
		if not setclip then return setStatus("No clipboard support (hold the text to copy)", T.bad) end
		pcall(setclip, prevText)
		setStatus("Copied to clipboard", T.ok)
	end)
	bPaste.Activated:Connect(function()
		if not getclip then return setStatus("No getclipboard: hold the text and use the keyboard's Paste", T.bad) end
		local ok, s = pcall(getclip)
		if ok and type(s) == "string" and #s > 0 then insertAtCursor(s) end
	end)
	bSave.Activated:Connect(function()
		if not writef then return setStatus("writefile unavailable", T.bad) end
		local name = ("Place_%s_Script_%d.txt"):format(tostring(game.PlaceId), os.time())
		local ok, err = pcall(writef, name, prevText)
		if ok then setStatus("Saved " .. name, T.ok) else setStatus("Error: " .. tostring(err):sub(1, 120), T.bad) end
	end)
	bUndo.Activated:Connect(function()
		if hi > 1 then hi = hi - 1; lastPush = 0; setTextSilent(hist[hi]); lastCursor = #prevText + 1 end
	end)
	bRedo.Activated:Connect(function()
		if hi < #hist then hi = hi + 1; lastPush = 0; setTextSilent(hist[hi]); lastCursor = #prevText + 1 end
	end)
	bPlus.Activated:Connect(function() fontSize = math.min(fontSize + 1, 26); applySize() end)
	bMinus.Activated:Connect(function() fontSize = math.max(fontSize - 1, 10); applySize() end)
	bHl.Activated:Connect(function()
		hlEnabled = not hlEnabled
		bHl.Text = hlEnabled and "Highlight: ON" or "Highlight: OFF"
		render(prevText)
	end)

	local symbols = {"Tab", "(", ")", "[", "]", "{", "}", '"', "'", "=", "==", "~=", ".", ",", ":", ";", "#", "+", "-", "*", "/", "%", "<", ">", "_",
		"local", "function", "end", "then", "do", "if", "return"}
	for idx, s in ipairs(symbols) do
		local b = flat(symBar, s, {BackgroundColor3 = T.button, BackgroundTransparency = 0, Size = UDim2.new(0, (#s > 2) and 52 or 34, 1, -8),
			LayoutOrder = idx, TextSize = 16})
		mk("UICorner", {CornerRadius = UDim.new(0, 3)}, b)
		b.MouseLeave:Connect(function() b.BackgroundColor3 = T.button; b.BackgroundTransparency = 0 end)
		b.InputEnded:Connect(function(i) if isPress(i) then b.BackgroundColor3 = T.button; b.BackgroundTransparency = 0 end end)
		b.MouseEnter:Connect(function() b.BackgroundColor3 = T.hover end)
		b.InputBegan:Connect(function(i) if isPress(i) then b.BackgroundColor3 = T.press end end)
		b.Activated:Connect(function() insertAtCursor(s == "Tab" and "    " or s) end)
	end

	-- ---------- API ----------
	local function Close()
		if cur.box then flushSave() end
		pcall(function() box:ReleaseFocus() end)
		sg.Enabled = false
	end
	closeBtn.Activated:Connect(Close)
	minBtn.Activated:Connect(function()
		minimized = not minimized
		if minimized then pcall(function() box:ReleaseFocus() end) end
		layout()
	end)

	-- opts: Title, Text, Box (SL_CodeTextBox para salvar), Focus
	local function Open(opts)
		opts = opts or {}
		if cur.box then flushSave() end
		cur.box = opts.Box
		titleLabel.Text = "Notepad - " .. tostring(opts.Title or "Script")
		local text = (tostring(opts.Text or ""):gsub("\r", ""):gsub("\t", "    "))
		applying = true
		box.Text = text
		applying = false
		prevText = text
		hist, hi, lastPush = {text}, 1, 0
		lastCursor = #text + 1
		saveToken = saveToken + 1
		minimized = false
		sg.Enabled = true
		if not win.init then
			win.init = true
			local s = screenSize()
			win.w = math.min(s.X * 0.94, 680)
			win.h = math.min(s.Y * 0.82, 480)
			win.x = (s.X - win.w) / 2
			win.y = (s.Y - win.h) / 2
		end
		layout()
		scroller.CanvasPosition = Vector2.zero
		render(text)
		if cur.box then
			setStatus("Linked to script: autosaves", T.dim)
		else
			setStatus("No script linked: use Execute or Copy", T.dim)
		end
		if text == "" or opts.Focus then task.defer(function() box:CaptureFocus() end) end
	end

	applySize()
	getgenv().DexPP_CodeEditor = {Open = Open, Close = Close}
end
local okEd, errEd = pcall(buildEditor)
if not okEd then warn("[DexBridge] Code Editor:", errEd) end
