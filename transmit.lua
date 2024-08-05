local gemId = 201793;
local tokenId = 201836;
local keystoneId = 180653;

local Comm = LibStub:GetLibrary("AceComm-3.0")
local SharedVaultFrame = SharedVaultFrame;
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
		local start, finish, characterName = remaining:find("%[ShareVault: ([^%s]+)%'");
		if(characterName) then
			characterName = characterName:gsub("|c[Ff][Ff]......", ""):gsub("|r", "");
			newMsg = newMsg..remaining:sub(1, start-1);
			newMsg = newMsg.."|Hgarrmission:sharevault:|h|cFFFFFF00["..characterName.."'s Vault]|h|r";
			remaining = remaining:sub(finish + 1);
		else
			done = true;
		end
	until(done)
	if newMsg ~= "" then
		local trimmedPlayer = Ambiguate(player, "none")
		if event == "CHAT_MSG_WHISPER" and not UnitInRaid(trimmedPlayer) and not UnitInParty(trimmedPlayer) then -- XXX: Need a guild check
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

local function crossRealmSendCommMessage(prefix, text, target)
	local chattype = "WHISPER"
	if target and not UnitIsSameServer(target) then
		if UnitInRaid(target) then
			chattype = "RAID"
			-- text = ("%s:%s"):format(target, text)
		elseif UnitInParty(target) then
			chattype = "PARTY"
			-- text = ("%s:%s"):format(target, text)
		end
	end
	Comm:SendCommMessage(prefix, text, chattype, target)
end

local function GetRewards()
	local rewards = C_WeeklyRewards.GetActivities()
	local numRewards = 0;
	for i, rewardInfo in ipairs(rewards) do
		if #rewardInfo.rewards > 0 then
			for j, reward in ipairs(rewardInfo.rewards) do 
				if reward.id ~= 201793 and reward.id ~= 201836 and reward.id ~= 180653 then 
					reward["itemLink"] = C_WeeklyRewards.GetItemHyperlink(reward.itemDBID);
					numRewards = numRewards + 1;
				end 
			end
		end
	end

	if numRewards > 0 then
		for i, rewardInfo in ipairs(rewards) do
			if #rewardInfo.rewards == 0 then
				rewardInfo.progress = 0;
			end
		end
	end
	-- DevTools_Dump(rewards[1])
	return rewards;
end

Comm:RegisterComm("ShareVault", function(prefix, message, chattype, sender)
	local _, _, request = message:find("([^%s]+):request");
	local _, _, response = message:find("response:([^%s]+)");
	if chattype == "PARTY" or chattype == "RAID" then
		local _, _, requestTarget = message:find("([^%s]+):request");
		local _, _, responseTarget = message:find("([^%s]+):response");
		local yourName, realm = UnitFullName("player")
		if request and requestTarget == yourName.."-"..realm then
			local rewards = GetRewards();
			rewards.Owner = requestTarget;
			local serialized = LibSerialize:SerializeEx(configForLS, rewards);
			local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate);
			local encoded = LibDeflate:EncodeForPrint(compressed);
			crossRealmSendCommMessage("ShareVault", sender .. ":response:" .. encoded, sender)
		elseif response and responseTarget == yourName.."-"..realm then
			local decoded = LibDeflate:DecodeForPrint(response)
			local decompressed = LibDeflate:DecompressDeflate(decoded)
			local success, deserialized = LibSerialize:Deserialize(decompressed)

			-- DevTools_Dump(deserialized)
			TEST_TABLE = deserialized;
			SharedVaultFrame:Show();
		end
	else
		if request then
			local rewards = GetRewards();
			rewards.Owner = UnitName("player");
			local serialized = LibSerialize:SerializeEx(configForLS, rewards);
			local compressed = LibDeflate:CompressDeflate(serialized, configForDeflate);
			local encoded = LibDeflate:EncodeForPrint(compressed);
			Comm:SendCommMessage(prefix, "response:" .. encoded, "WHISPER", sender)
		elseif response then
			local decoded = LibDeflate:DecodeForPrint(response)
			local decompressed = LibDeflate:DecompressDeflate(decoded)
			local success, deserialized = LibSerialize:Deserialize(decompressed)

			-- DevTools_Dump(deserialized)
			TEST_TABLE = deserialized;
			SharedVaultFrame:Show();
		end
	end
end)

hooksecurefunc("SetItemRef", function(link, text)
	local linkType, addon, payload = strsplit(":", link)
	if linkType == "garrmission" and addon == "sharevault" then
		local _, _, characterName = text:find("|Hgarrmission:sharevault:|h|cFFFFFF00%[([^%s]+)%'");
		if(IsShiftKeyDown()) then
			local editbox = GetCurrentKeyBoardFocus();
			if(editbox) then
				editbox:Insert("[ShareVault: " .. characterName .. "'s Vault]");
			end
		else
			crossRealmSendCommMessage("ShareVault", characterName .. ":request", characterName)
		end
	end
end)