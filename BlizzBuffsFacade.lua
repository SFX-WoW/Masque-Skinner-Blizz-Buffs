
local LMB = LibStub("Masque", true)
if not LMB then return end

local Buffs = LMB:Group("Blizzard Buffs", "Buffs")
local Debuffs = LMB:Group("Blizzard Buffs", "Debuffs")

if AuraButtonMixin then
	-- Dragonflight+
	local skinned = {}

	local function makeHook(group, container)
		local function updateFrames(frames)
			for i = 1, #frames do
				local frame = frames[i]
				if not skinned[frame] then
					skinned[frame] = 1

					-- We have to make a wrapper to hold the skinnable components of the Icon
					-- because the aura frames are not square (and so if we skinned them directly
					-- with Masque, they'd get all distorted and weird).
					local skinWrapper = CreateFrame("Frame")
					skinWrapper:SetParent(frame)
					skinWrapper:SetSize(30, 30)
					skinWrapper:SetPoint("TOP")

					-- Blizzard's code constantly tries to reposition the icon,
					-- so we have to make our own icon that it won't try to move.
					frame.Icon:Hide()
					frame.SkinnedIcon = skinWrapper:CreateTexture(nil, "BACKGROUND")
					frame.SkinnedIcon:SetSize(30, 30)
					frame.SkinnedIcon:SetPoint("CENTER")
					frame.SkinnedIcon:SetTexture(frame.Icon:GetTexture())
					hooksecurefunc(frame.Icon, "SetTexture", function(_, tex)
						frame.SkinnedIcon:SetTexture(tex)
					end)

					if frame.Count then
						-- edit mode versions don't have stack text
						frame.Count:SetParent(skinWrapper);
					end
					if frame.DebuffBorder then
						frame.DebuffBorder:SetParent(skinWrapper);
					end
					if frame.TempEnchantBorder then
						frame.TempEnchantBorder:SetParent(skinWrapper);
						frame.TempEnchantBorder:SetVertexColor(.75, 0, 1)
					end
					if frame.Symbol then
						-- Shows debuff types as text in colorblind mode (except it currently doesnt work)
						frame.Symbol:SetParent(skinWrapper);
					end

					local bType = frame.auraType or "Aura"

					if bType == "DeadlyDebuff" then
						bType = "Debuff"
					end

					group:AddButton(skinWrapper, {
						Icon = frame.SkinnedIcon,
						DebuffBorder = frame.DebuffBorder,
						EnchantBorder = frame.TempEnchantBorder,
						Count = frame.Count,
						HotKey = frame.Symbol
					}, bType)
				end
			end
		end

		return function(self)
			updateFrames(self.auraFrames, group)
			if self.exampleAuraFrames then
				updateFrames(self.exampleAuraFrames, group)
			end
		end
	end

	hooksecurefunc(BuffFrame, "UpdateAuraButtons", makeHook(Buffs, BuffFrame))
	hooksecurefunc(BuffFrame, "OnEditModeEnter", makeHook(Buffs, BuffFrame))
	hooksecurefunc(DebuffFrame, "UpdateAuraButtons", makeHook(Debuffs, DebuffFrame))
	hooksecurefunc(DebuffFrame, "OnEditModeEnter", makeHook(Debuffs, DebuffFrame))
else
	local f = CreateFrame("Frame")
	local TempEnchant = LMB:Group("Blizzard Buffs", "TempEnchant")

	local function NULL()
	end

	local function OnEvent(self, event, addon)
		for i=1, BUFF_MAX_DISPLAY do
			local buff = _G["BuffButton"..i]
			if buff then
				Buffs:AddButton(buff, nil, "Buff")
			end
			if not buff then break end
		end

		for i=1, BUFF_MAX_DISPLAY do
			local debuff = _G["DebuffButton"..i]
			if debuff then
				Debuffs:AddButton(debuff, nil, "Debuff")
			end
			if not debuff then break end
		end

		for i=1, (NUM_TEMP_ENCHANT_FRAMES or 3) do
			local f = _G["TempEnchant"..i]
			--_G["TempEnchant"..i.."Border"].SetTexture = NULL
			if TempEnchant then
				TempEnchant:AddButton(f, nil, "Enchant")
			end
			_G["TempEnchant"..i.."Border"]:SetVertexColor(.75, 0, 1)
		end

		f:SetScript("OnEvent", nil)
	end

	hooksecurefunc("CreateFrame", function (_, name, parent) --dont need to do this for TempEnchant enchant frames because they are hard created in xml
		if parent ~= BuffFrame or type(name) ~= "string" then return end
		if strfind(name, "^DebuffButton%d+$") then
			Debuffs:AddButton(_G[name], nil, "Debuff")
			Debuffs:ReSkin() -- Needed to prevent issues with stack text appearing under the frame.
		elseif strfind(name, "^BuffButton%d+$") then
			Buffs:AddButton(_G[name], nil, "Buff")
			Buffs:ReSkin() -- Needed to prevent issues with stack text appearing under the frame.
		end
	end
	)

	f:SetScript("OnEvent", OnEvent)
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
end
