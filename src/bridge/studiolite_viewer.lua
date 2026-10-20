-- Studio Lite: editor de scripts original (ShowScript), teclado mobile e NewPart.
-- Codigo do Studio Lite mantido como estava.
local ctx = ...
local Players, RS, UIS, lp, gui, panel = ctx.Players, ctx.RS, ctx.UIS, ctx.lp, ctx.gui, ctx.panel
local getSel, setSel, evA, evB = ctx.getSel, ctx.setSel, ctx.evA, ctx.evB
local Explorer, Properties, selection = ctx.Explorer, ctx.Properties, ctx.selection
local SLF, GetScriptSource, ServerFunctions = ctx.SLF, ctx.GetScriptSource, ctx.ServerFunctions
local ColorizeSource, GG = ctx.ColorizeSource, ctx.GG
local InsertFrame, frS, frL, frM, ViewScriptFrame = ctx.InsertFrame, ctx.frS, ctx.frL, ctx.frM, ctx.ViewScriptFrame
local State = ctx.State
	local ShowScript, MobileAddKeyboard, NewPart
	do
		-- (codigo original do Studio Lite: editor de scripts + teclado mobile)
		local v_u_4, v_u_198, v_u_7 = UIS, panel, GetScriptSource
		local v_u_11, v_u_12, v_u_13 = frS, frL, frM
		local v_u_464 = ColorizeSource
		local v_u_465 = Vector2.new(0, 0)
local v_u_466 = {}
MobileAddKeyboard = function()
	-- upvalues: (ref) v_u_466, (copy) v_u_198, (copy) v_u_4, (copy) v_u_464, (ref) v_u_465
	for v467 = 1, #v_u_466 do
		if v_u_466[v467] then
			v_u_466[v467]:disconnect()
		end
	end
	v_u_466 = {}
	local v_u_468 = v_u_198.Parent:WaitForChild("ViewScriptFrame")
	local v_u_469 = v_u_468:WaitForChild("ScrollingFrame")
	local v_u_470 = nil
	local v_u_471 = nil
	local v_u_472 = 1
	local v_u_473 = 1
	local v_u_474 = nil
	local v_u_475 = nil
	local v_u_476 = nil
	for _, v477 in pairs(v_u_469:GetChildren()) do
		if v477.Name == "SL_CodeTextBox" and not v477.Parent:FindFirstChild("MobileCursorTextButton") then
			v477.Active = false
			v477.Selectable = false
			v477.TextEditable = false
			v_u_474 = Instance.new("TextButton")
			v_u_474.Name = "MobileCursorTextButton"
			if GG.GamepadService then
				v_u_474.Active = true
			else
				v_u_474.Active = false
			end
			v_u_474.Size = UDim2.new(1, 0, 0, 1600)
			v_u_474.Position = UDim2.new(0, 50, 0, 0)
			v_u_474.ZIndex = 5
			v_u_474.BackgroundTransparency = 1
			v_u_474.BorderSizePixel = 0
			v_u_474.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json", Enum.FontWeight.Bold)
			v_u_474.TextSize = 14
			v_u_474.TextColor3 = Color3.new(0, 1, 1)
			v_u_474.AutomaticSize = Enum.AutomaticSize.XY
			v_u_474.Text = ""
			v_u_474.TextXAlignment = Enum.TextXAlignment.Left
			v_u_474.TextYAlignment = Enum.TextYAlignment.Top
			v_u_474.Parent = v477.Parent
			local v_u_478 = v477
			v_u_466[#v_u_466 + 1] = v_u_474.MouseButton1Click:Connect(function()
				-- upvalues: (ref) v_u_471, (ref) v_u_4, (ref) v_u_472, (copy) v_u_474, (ref) v_u_473, (ref) v_u_198, (ref) v_u_470, (ref) v_u_478
				v_u_471 = v_u_4:GetMouseLocation()
				v_u_472 = v_u_471.X - v_u_474.AbsolutePosition.X
				v_u_473 = v_u_471.y - v_u_474.AbsolutePosition.Y + v_u_198.Parent.AbsolutePosition.Y
				local v479 = v_u_472
				local v480 = v_u_474.AbsoluteSize.X
				v_u_472 = math.clamp(v479, 0, v480)
				local v481 = v_u_473
				local v482 = v_u_474.AbsoluteSize.Y
				v_u_473 = math.clamp(v481, 0, v482)
				local v483 = v_u_472 / 7
				v_u_472 = math.floor(v483) + 1
				local v484 = v_u_473 / 14
				v_u_473 = math.floor(v484) + 1
				v_u_470 = v_u_478.ContentText:split("\n")
				if v_u_473 > #v_u_470 then
					v_u_473 = #v_u_470
				end
				if v_u_472 > #v_u_470[v_u_473] then
					v_u_472 = #v_u_470[v_u_473] + 1
				end
			end)
			v_u_475 = v_u_478
		end
	end
	spawn(function()
		-- upvalues: (copy) v_u_468, (ref) v_u_474, (ref) v_u_472, (ref) v_u_473, (ref) v_u_475, (ref) v_u_464, (ref) v_u_476, (ref) v_u_465, (copy) v_u_469
		local v485 = 0
		while v_u_468.Visible do
			if v_u_474 and (v_u_472 >= 1 and v_u_473 >= 1) then
				v485 = v485 - 1
				if v485 <= 0 then
					local v486 = v_u_475
					local v487, v488 = v_u_464:ColorizeSource(v_u_475.ContentText, false, true, v_u_473)
					v486.Text = v487
					v_u_472 = v_u_472 + v488
					v_u_475:WaitForChild("SaveChangesTo").Value.Text = v_u_475.ContentText
					v485 = 3
				end
				v_u_476 = ("\n"):rep(v_u_473 - 1) .. (" "):rep(v_u_472 - 1) .. "|"
				v_u_474.Text = v_u_476
				task.wait(0.5)
				v_u_474.Text = ""
				task.wait(0.5)
				v_u_465 = v_u_469.CanvasPosition
			else
				task.wait(0.5)
			end
		end
	end)
	local v489 = v_u_468:WaitForChild("KeyboardFrame")
	local v_u_490 = v_u_468:WaitForChild("AltKeyboardTextBoxFrame")
	local v_u_491 = v_u_490:WaitForChild("AltKeyboardTextBox")
	local v_u_492 = v489:WaitForChild("KeyboardRow1Frame")
	local v_u_493 = v489:WaitForChild("KeyboardRow2Frame")
	local v_u_494 = v489:WaitForChild("KeyboardRow3Frame")
	local v_u_495 = v489:WaitForChild("KeyboardRow4Frame")
	v_u_466[#v_u_466 + 1] = v_u_491.FocusLost:Connect(function()
		-- upvalues: (ref) v_u_475, (copy) v_u_491, (copy) v_u_490, (copy) v_u_469
		v_u_475.Text = v_u_491.ContentText
		v_u_490.Visible = false
		task.wait(0.2)
		v_u_469.CanvasPosition = Vector2.new(0, 0)
	end)
	for _, v496 in pairs(v489:GetChildren()) do
		for _, v_u_497 in pairs(v496:GetChildren()) do
			if v_u_497.ClassName:sub(-6) == "Button" then
				v_u_466[#v_u_466 + 1] = v_u_497.MouseButton1Click:Connect(function()
					-- upvalues: (ref) v_u_474, (ref) v_u_472, (ref) v_u_473, (copy) v_u_469, (ref) v_u_465, (ref) v_u_475, (copy) v_u_497, (copy) v_u_495, (copy) v_u_493, (copy) v_u_494, (copy) v_u_492, (copy) v_u_491, (copy) v_u_490, (copy) v_u_468
					if v_u_474 and (v_u_472 >= 0 and v_u_473 >= 0) then
						v_u_474.Text = ""
						v_u_469.CanvasPosition = v_u_465
						local v498 = v_u_475.ContentText:split("\n")
						local v499 = v498[v_u_473]
						if #v_u_497.Text == 1 then
							v498[v_u_473] = v499:sub(1, v_u_472 - 1) .. v_u_497.Text .. v499:sub(v_u_472)
							v_u_475.Text = table.concat(v498, "\n")
							v_u_472 = v_u_472 + 1
							if v_u_497.Text >= "A" and (v_u_497.Text <= "Z" and v_u_495:WaitForChild("Col01KeyShiftButton").Text == "Shift") then
								v_u_495:WaitForChild("Col01KeyShiftButton").Text = "shift"
								for _, v500 in pairs(v_u_493:GetChildren()) do
									if v500.ClassName == "TextButton" and (#v500.Text == 1 and (v500.Text >= "A" and v500.Text <= "Z")) then
										v500.Text = v500.Text:lower()
									end
								end
								for _, v501 in pairs(v_u_494:GetChildren()) do
									if v501.ClassName == "TextButton" and (#v501.Text == 1 and (v501.Text >= "A" and v501.Text <= "Z")) then
										v501.Text = v501.Text:lower()
									end
								end
								for _, v502 in pairs(v_u_495:GetChildren()) do
									if v502.ClassName == "TextButton" and (#v502.Text == 1 and (v502.Text >= "A" and v502.Text <= "Z")) then
										v502.Text = v502.Text:lower()
									end
								end
								return
							end
						elseif v_u_497.Text == "\226\134\145" and v_u_473 > 1 then
							v_u_473 = v_u_473 - 1
							if v_u_472 > #v498[v_u_473] then
								v_u_472 = #v498[v_u_473] + 1
								return
							end
						elseif v_u_497.Text == "\226\134\147" and v_u_473 + 1 <= #v498 then
							v_u_473 = v_u_473 + 1
							if v_u_472 > #v498[v_u_473] then
								v_u_472 = #v498[v_u_473] + 1
								return
							end
						else
							if v_u_497.Text == "\226\134\146" and v_u_473 + 1 <= #v498 then
								if v_u_472 >= #v499 then
									v_u_473 = v_u_473 + 1
									v_u_472 = 1
								else
									v_u_472 = v_u_472 + 1
								end
							end
							if v_u_497.Text == "\226\134\144" and (v_u_472 > 1 or v_u_473 > 1) then
								if v_u_472 > 1 then
									v_u_472 = v_u_472 - 1
								else
									v_u_473 = v_u_473 - 1
									v_u_472 = #v498[v_u_473] + 1
								end
							end
							if v_u_497.Text == "Space" then
								v498[v_u_473] = v499:sub(1, v_u_472 - 1) .. " " .. v499:sub(v_u_472)
								v_u_475.Text = table.concat(v498, "\n")
								v_u_472 = v_u_472 + 1
								return
							end
							if v_u_497.Text == "\226\134\144Backspace" then
								if v_u_472 > 1 then
									if v_u_472 >= #v499 then
										v498[v_u_473] = v499:sub(1, v_u_472 - 2)
									else
										v498[v_u_473] = v499:sub(1, v_u_472 - 2) .. v499:sub(v_u_472)
									end
									v_u_475.Text = table.concat(v498, "\n")
									v_u_472 = v_u_472 - 1
									return
								end
								if v_u_473 > 1 then
									v498[v_u_473] = v498[v_u_473 - 1] .. v499
									if v498[v_u_473 - 1] == " " then
										v_u_472 = #v498[v_u_473 - 1]
									else
										v_u_472 = #v498[v_u_473 - 1] + 1
									end
									table.remove(v498, v_u_473 - 1)
									v_u_475.Text = table.concat(v498, "\n")
									v_u_473 = v_u_473 - 1
									return
								end
							else
								if v_u_497.Text == "Delete\226\134\146" then
									if v_u_472 >= #v499 and v_u_473 < #v498 then
										v498[v_u_473] = v499 .. v498[v_u_473 + 1]
										table.remove(v498, v_u_473 + 1)
									elseif v_u_472 == 1 then
										v498[v_u_473] = v499:sub(2)
									else
										v498[v_u_473] = v499:sub(1, v_u_472 - 1) .. v499:sub(v_u_472 + 1)
									end
									v_u_475.Text = table.concat(v498, "\n")
									return
								end
								if v_u_497.Text == "Enter" then
									if v_u_472 == #v499 then
										local v503 = v_u_473 + 1
										table.insert(v498, v503, " ")
									elseif v_u_472 == 1 then
										local v504 = v_u_473
										table.insert(v498, v504, " ")
									else
										v498[v_u_473] = v499:sub(1, v_u_472 - 1)
										local v505 = v_u_473 + 1
										local v506 = v_u_472
										table.insert(v498, v505, v499:sub(v506))
									end
									v_u_475.Text = table.concat(v498, "\n")
									v_u_472 = 1
									v_u_473 = v_u_473 + 1
									return
								end
								if v_u_497.Text == "shift" then
									v_u_497.Text = "Shift"
									for _, v507 in pairs(v_u_493:GetChildren()) do
										if v507.ClassName == "TextButton" and (#v507.Text == 1 and (v507.Text >= "a" and v507.Text <= "z")) then
											v507.Text = v507.Text:upper()
										end
									end
									for _, v508 in pairs(v_u_494:GetChildren()) do
										if v508.ClassName == "TextButton" and (#v508.Text == 1 and (v508.Text >= "a" and v508.Text <= "z")) then
											v508.Text = v508.Text:upper()
										end
									end
									for _, v509 in pairs(v_u_495:GetChildren()) do
										if v509.ClassName == "TextButton" and (#v509.Text == 1 and (v509.Text >= "a" and v509.Text <= "z")) then
											v509.Text = v509.Text:upper()
										end
									end
									return
								end
								if v_u_497.Text == "SHIFT" then
									v_u_497.Text = "shift"
									for _, v510 in pairs(v_u_493:GetChildren()) do
										if v510.ClassName == "TextButton" and (#v510.Text == 1 and (v510.Text >= "A" and v510.Text <= "Z")) then
											v510.Text = v510.Text:lower()
										end
									end
									for _, v511 in pairs(v_u_494:GetChildren()) do
										if v511.ClassName == "TextButton" and (#v511.Text == 1 and (v511.Text >= "A" and v511.Text <= "Z")) then
											v511.Text = v511.Text:lower()
										end
									end
									for _, v512 in pairs(v_u_495:GetChildren()) do
										if v512.ClassName == "TextButton" and (#v512.Text == 1 and (v512.Text >= "A" and v512.Text <= "Z")) then
											v512.Text = v512.Text:lower()
										end
									end
									return
								end
								if v_u_497.Text == "Shift" then
									v_u_497.Text = "SHIFT"
									return
								end
								if v_u_497.Text == "+/*" then
									v_u_497.Text = "abc"
									v_u_492:WaitForChild("Col11KeyTildeButton").Text = "-"
									v_u_493:WaitForChild("Col01KeyqButton").Text = "!"
									v_u_493:WaitForChild("Col02KeywButton").Text = "@"
									v_u_493:WaitForChild("Col03KeyeButton").Text = "#"
									v_u_493:WaitForChild("Col04KeyrButton").Text = "$"
									v_u_493:WaitForChild("Col05KeytButton").Text = "%"
									v_u_493:WaitForChild("Col06KeyyButton").Text = "^"
									v_u_493:WaitForChild("Col07KeyuButton").Text = "&"
									v_u_493:WaitForChild("Col08KeyiButton").Text = "*"
									v_u_493:WaitForChild("Col09KeyoButton").Text = "_"
									v_u_493:WaitForChild("Col10KeypButton").Text = "+"
									v_u_494:WaitForChild("Col01KeyaButton").Text = "`"
									v_u_494:WaitForChild("Col02KeysButton").Text = "{"
									v_u_494:WaitForChild("Col03KeydButton").Text = "}"
									v_u_494:WaitForChild("Col04KeyfButton").Text = "["
									v_u_494:WaitForChild("Col05KeygButton").Text = "]"
									v_u_494:WaitForChild("Col06KeyhButton").Text = "|"
									v_u_494:WaitForChild("Col07KeyjButton").Text = "\\"
									v_u_494:WaitForChild("Col08KeykButton").Text = ";"
									v_u_494:WaitForChild("Col09KeylButton").Text = "\'"
									v_u_495:WaitForChild("Col02KeyzButton").Text = "+"
									v_u_495:WaitForChild("Col03KeyxButton").Text = "-"
									v_u_495:WaitForChild("Col04KeycButton").Text = "*"
									v_u_495:WaitForChild("Col05KeyvButton").Text = "/"
									v_u_495:WaitForChild("Col06KeybButton").Text = "?"
									v_u_495:WaitForChild("Col07KeynButton").Text = "<"
									v_u_495:WaitForChild("Col08KeymButton").Text = ">"
									return
								end
								if v_u_497.Text == "abc" then
									v_u_497.Text = "+/*"
									v_u_492:WaitForChild("Col11KeyTildeButton").Text = "~"
									v_u_495:WaitForChild("Col01KeyShiftButton").Text = "shift"
									v_u_493:WaitForChild("Col01KeyqButton").Text = "q"
									v_u_493:WaitForChild("Col02KeywButton").Text = "w"
									v_u_493:WaitForChild("Col03KeyeButton").Text = "e"
									v_u_493:WaitForChild("Col04KeyrButton").Text = "r"
									v_u_493:WaitForChild("Col05KeytButton").Text = "t"
									v_u_493:WaitForChild("Col06KeyyButton").Text = "y"
									v_u_493:WaitForChild("Col07KeyuButton").Text = "u"
									v_u_493:WaitForChild("Col08KeyiButton").Text = "i"
									v_u_493:WaitForChild("Col09KeyoButton").Text = "o"
									v_u_493:WaitForChild("Col10KeypButton").Text = "p"
									v_u_494:WaitForChild("Col01KeyaButton").Text = "a"
									v_u_494:WaitForChild("Col02KeysButton").Text = "s"
									v_u_494:WaitForChild("Col03KeydButton").Text = "d"
									v_u_494:WaitForChild("Col04KeyfButton").Text = "f"
									v_u_494:WaitForChild("Col05KeygButton").Text = "g"
									v_u_494:WaitForChild("Col06KeyhButton").Text = "h"
									v_u_494:WaitForChild("Col07KeyjButton").Text = "j"
									v_u_494:WaitForChild("Col08KeykButton").Text = "k"
									v_u_494:WaitForChild("Col09KeylButton").Text = "l"
									v_u_495:WaitForChild("Col02KeyzButton").Text = "z"
									v_u_495:WaitForChild("Col03KeyxButton").Text = "x"
									v_u_495:WaitForChild("Col04KeycButton").Text = "c"
									v_u_495:WaitForChild("Col05KeyvButton").Text = "v"
									v_u_495:WaitForChild("Col06KeybButton").Text = "b"
									v_u_495:WaitForChild("Col07KeynButton").Text = "n"
									v_u_495:WaitForChild("Col08KeymButton").Text = "m"
									return
								end
								if v_u_497.Text == "Alt Keyboard" then
									v_u_491.Text = v_u_475.ContentText
									v_u_490.Visible = true
									task.wait()
									v_u_491:CaptureFocus()
									return
								end
							end
						end
					elseif v_u_468.Parent.WarningText.Visible == false then
						spawn(function()
							-- upvalues: (ref) v_u_468
							v_u_468.Parent:WaitForChild("WarningText").Text = "Tap to place cursor."
							v_u_468.Parent.WarningText.Visible = true
							task.wait(3)
							v_u_468.Parent.WarningText.Visible = false
						end)
					end
				end)
			end
		end
	end
end
ShowScript = function(p513)
	-- upvalues: (copy) v_u_11, (copy) v_u_12, (copy) v_u_13, (copy) v_u_198, (copy) v_u_7, (copy) v_u_464
	v_u_11.Visible = false
	v_u_12.Visible = false
	v_u_13.Visible = false
	local v514 = v_u_198.Parent:WaitForChild("ViewScriptFrame")
	local v515 = v514:WaitForChild("ScrollingFrame")
	local v516 = v514:WaitForChild("ViewScriptTextLabelTemplate")
	local v517 = v514:WaitForChild("KeyboardFrame")
	v515:ClearAllChildren()
	local v518 = p513.Name
	local v519 = false
	for _, v520 in pairs(p513:GetChildren()) do
		if v520.Name:sub(1, 3) == "SL_" then
			local v521 = v520:Clone()
			v521.Parent = v514.ScrollingFrame
			if v521:FindFirstChild("SaveChangesTo") then
				v521.SaveChangesTo.Value = v520
			end
			if v520.Name == "SL_CodeTextBox" then
				v520.Position = UDim2.new(0, 52, 0, 0)
				v519 = true
			elseif v520.Name == "SL_1ReadOnly" then
				v518 = v520.ContentText:match("[%s%-]*(%w+)")
			end
		end
	end
	v515.Size = UDim2.new(1, 0, 1, -55)
	v517.Visible = false
	if v519 then
		v514.LineNumbersTextLabel:Clone().Parent = v515
		v515.LineNumbersTextLabel.Visible = true
		v514:WaitForChild("TextLabel").Text = p513.Name
		if GG.DynamicThumb then
			v517.Visible = true
			v515.Size = UDim2.new(1, 0, 1, -165)
			MobileAddKeyboard()
		else
			v514:WaitForChild("DummyIndentColorizeButton").Visible = true
		end
	else
		v514:WaitForChild("TextLabel").Text = p513.Name .. "  (read only)"
		local v522 = v_u_7:InvokeServer(p513.ClassName .. v518)
		local v523 = not v522 and "Not found." or v_u_464:ColorizeSource(v522, true, false)
		local v524 = 0
		for _, v525 in pairs(v523:split("\n")) do
			local v526 = v516:Clone()
			v526.Text = v525
			v526.Position = UDim2.new(v526.Position.X.Scale, v526.Position.X.Offset, v526.Position.Y.Scale, v524)
			v526.Visible = true
			v526.Parent = v514.ScrollingFrame
			v524 = v524 + 16
		end
	end
	v514.Visible = true
	v514.Parent:WaitForChild("ToolboxFrame").Visible = false
	v_u_11.Visible = false
	v_u_12.Visible = false
	v_u_13.Visible = false
end
		NewPart = function(p444, p445)
	p444.Anchored = true
	p444.CanCollide = false
	p444:SetAttribute("SL_Anchored", false)
	p444:SetAttribute("SL_CanCollide", true)
	p444.TopSurface = Enum.SurfaceType.Smooth
	p444.BottomSurface = Enum.SurfaceType.Smooth
	p444.Parent = p445
	local v446 = workspace.CurrentCamera.CFrame
	local v447 = (v446.X + v446.lookVector.X * 30) * 2
	local v448 = math.floor(v447) / 2
	local v449 = p444.Size.Y / 2
	local v450 = (v446.Z + v446.lookVector.Z * 30) * 2
	local v451 = math.floor(v450) / 2
	local v452 = Vector3.new(v448, v449, v451)
	local v453 = workspace
	local v454 = v452.X
	local v455 = v446.Y
	local v456 = v452.Z
	local v457 = Vector3.new(v454, v455, v456)
	local v458 = -v446.Y
	local v459 = v453:Raycast(v457, (Vector3.new(0, v458, 0)))
	if v459 then
		local v460 = v452.X
		local v461 = v459.Instance.Position.Y + v459.Instance.Size.Y / 2 + p444.Size.Y / 2
		local v462 = v452.Z
		v452 = Vector3.new(v460, v461, v462)
	end
	p444.Position = v452
end
	end

return {ShowScript = ShowScript, MobileAddKeyboard = MobileAddKeyboard, NewPart = NewPart}
