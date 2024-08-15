--[[
This code includes a modified version of the transmission functions originally authored by the creators and contributors of WeakAuras.
All credits go to those amazing developers for the base implementation.
The original code can be found at https://github.com/WeakAuras/WeakAuras2/blob/main/WeakAuras/Transmission.lua. 
]]

local ReVaultFrame = _G["ReVaultFrame"];
local Comm = LibStub:GetLibrary("AceComm-3.0")
local LibSerialize = LibStub("LibSerialize");
local LibDeflate = LibStub("LibDeflate");
local configForDeflate = {level = 1}
local configForLS = {
  errorOnUnserializableType =  false
}

local function filterFunc(_, event, msg, player, l, cs, t, flag, channelId, ...)
	if flag == "GM" or flag == "DEV" or (event == "CHAT_MSG_CHANNEL" and type(channelId) == "number" and channelId > 0) then
	  	return
	end
  
	local newMsg = "";
	local remaining = msg;
	local done;
	repeat
		local start, finish, characterName = remaining:find("%[ReVault: ([^%s]+)%'");
		if(characterName) then
			characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
			newMsg = newMsg..remaining:sub(1, start-1);
			newMsg = newMsg.."|Hgarrmission:revault:|h|cFFFFFF00["..characterName.."'s Vault]|h|r";
			remaining = remaining:sub(finish + 1);
		else
			done = true;
		end
	until(done)
	if newMsg ~= "" then
		local trimmedPlayer = Ambiguate(player, "none")
		local guid = select(5, ...)
		if event == "CHAT_MSG_WHISPER" and not UnitInRaid(trimmedPlayer) and not UnitInParty(trimmedPlayer) and not (IsGuildMember and IsGuildMember(guid)) then
			local _, num = BNGetNumFriends()
			for i=1, num do
				if C_BattleNet then -- introduced in 8.2.5 PTR
					local toon = C_BattleNet.GetFriendNumGameAccounts(i)
					for j=1, toon do
						local gameAccountInfo = C_BattleNet.GetFriendGameAccountInfo(i, j);
						if gameAccountInfo.characterName == trimmedPlayer and gameAccountInfo.clientProgram == "WoW" then
							return false, newMsg, player, l, cs, t, flag, channelId, ...; -- Player is a real id friend, allow it
						end
					end
				else -- keep old method for 8.2 and Classic
					local toon = BNGetNumFriendGameAccounts(i)
					for j=1, toon do
						local _, rName, rGame = BNGetFriendGameAccountInfo(i, j)
						if rName == trimmedPlayer and rGame == "WoW" then
							return false, newMsg, player, l, cs, t, flag, channelId, ...; -- Player is a real id friend, allow it
						end
					end
				end
			end
			return true -- Filter strangers
		else
			return false, newMsg, player, l, cs, t, flag, channelId, ...;
		end
	end
end
  
ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_OFFICER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID_LEADER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT", filterFunc)
ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE_CHAT_LEADER", filterFunc)

local function GetEquippedItemsForSlot(itemLink)
    local equippedItems = {}
    local _, _, _, equipSlot = C_Item.GetItemInfoInstant(itemLink);

    if not equipSlot then
        return equippedItems
    end
	
    local function AddItemFromSlot(slot)
        local equippedItemLink = GetInventoryItemLink("player", slot);
        if equippedItemLink then
            table.insert(equippedItems, equippedItemLink);
        end
    end
	
    if equipSlot == "INVTYPE_FINGER" then
        AddItemFromSlot(11);
        AddItemFromSlot(12);
    elseif equipSlot == "INVTYPE_TRINKET" then
        AddItemFromSlot(13);
        AddItemFromSlot(14);
    elseif equipSlot == "INVTYPE_WEAPON" or equipSlot == "INVTYPE_WEAPONMAINHAND" then
        AddItemFromSlot(16);
        AddItemFromSlot(17);
    elseif equipSlot == "INVTYPE_SHIELD" or equipSlot == "INVTYPE_WEAPONOFFHAND" or equipSlot == "INVTYPE_HOLDABLE" then
        AddItemFromSlot(17);
    else
		local slotNameMap = {
			["INVTYPE_HEAD"] = "HEADSLOT",
			["INVTYPE_NECK"] = "NECKSLOT",
			["INVTYPE_SHOULDER"] = "SHOULDERSLOT",
			["INVTYPE_CHEST"] = "CHESTSLOT",
			["INVTYPE_WAIST"] = "WAISTSLOT",
			["INVTYPE_LEGS"] = "LEGSSLOT",
			["INVTYPE_FEET"] = "FEETSLOT",
			["INVTYPE_WRIST"] = "WRISTSLOT",
			["INVTYPE_HAND"] = "HANDSSLOT",
		}
        local slotId = GetInventorySlotInfo(slotNameMap[equipSlot])
        if slotId then
            AddItemFromSlot(slotId)
        end
    end

    return equippedItems
end

local function GetRewards()
	local weeklyRewardsActivities = C_WeeklyRewards.GetActivities();
	local hasRewards = C_WeeklyRewards.HasGeneratedRewards();

	if hasRewards then
		for i, activity in ipairs(weeklyRewardsActivities) do
			if activity.rewards and #activity.rewards > 0 then
				local itemDBID;
				for j, reward in ipairs(activity.rewards) do
					local _, _, _, itemSubType = C_Item.GetItemInfoInstant(reward.id);
					itemDBID = itemSubType ~= "INVTYPE_NON_EQUIP_IGNORE" and reward.itemDBID or itemDBID;
				end
				local rewardItemLink = itemDBID ~= nil and C_WeeklyRewards.GetItemHyperlink(itemDBID);
				activity.rewards = rewardItemLink and { 
					itemLink = rewardItemLink,
					equippedItems = GetEquippedItemsForSlot(rewardItemLink)
				} or {}
				itemDBID = nil;
			else
				activity.rewards =  {}
			end
		end		
	end

	weeklyRewardsActivities["timestamp"] = time();
	weeklyRewardsActivities["hasRewards"] = hasRewards;
	return weeklyRewardsActivities;
end

Comm:RegisterComm("ReVault", function(prefix, message, chattype, sender)
	local _, _, request = message:find("([^%s]+):request");
	local _, _, response = message:find("response:([^%s]+)");
	if request then
		local rewards = GetRewards();
		local yourName, realm = UnitFullName("player");
		local serialized = LibSerialize:SerializeEx(configForLS, rewards);
		local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate);
		local encoded = LibDeflate:EncodeForPrint(compressed);
		Comm:SendCommMessage(prefix, "response:" .. encoded, "WHISPER", sender)
	elseif response then
		local decoded = LibDeflate:DecodeForPrint(response)
		local decompressed = LibDeflate:DecompressDeflate(decoded)
		local success, deserialized = LibSerialize:Deserialize(decompressed)

		ReVaultFrame.activities = deserialized;
		ReVaultData[ReVaultFrame.owner] = deserialized;
	end
end)

hooksecurefunc("SetItemRef", function(link, text)
	local linkType, addon, payload = strsplit(":", link)
	if linkType == "garrmission" and addon == "revault" then
		local _, _, characterName = text:find("|Hgarrmission:revault:|h|cFFFFFF00%[([^%s]+)%'");
		if(IsShiftKeyDown()) then
			local editbox = GetCurrentKeyBoardFocus();
			if(editbox) then
				editbox:Insert("[ReVault: " .. characterName .. "'s Vault]");
			end
		else
			ReVaultFrame.owner = characterName;
			ReVaultFrame:Hide();
			ReVaultFrame:Show();
			Comm:SendCommMessage("ReVault", characterName .. ":request", "WHISPER", characterName);
		end
	end
end)