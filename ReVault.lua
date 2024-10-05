C_AddOns.LoadAddOn("Blizzard_WeeklyRewards");

SLASH_RV1 = "/rv"

SlashCmdList.RV = function(msg, editBox)
	ReVault();
end

local selectRewardButton = WeeklyRewardsFrame.SelectRewardButton;
local point, relativeTo, relativePoint, x, y = selectRewardButton:GetPoint();
selectRewardButton:SetPoint(point, relativeTo, relativePoint, x - 108, y)

local reVaultShareButton = CreateFrame("Button", "ReVaultShareButton", WeeklyRewardsFrame, "UIPanelButtonTemplate");
reVaultShareButton:SetSize(182, 23);
reVaultShareButton:SetPoint("TOPLEFT", selectRewardButton, "TOPRIGHT", 30, 0);
reVaultShareButton:SetFrameLevel(6000);
reVaultShareButton:SetText("Share with ReVault");
reVaultShareButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetText("Share this Great Vault with other players.", nil, nil, nil, nil, true);
    GameTooltip:Show();
end)

reVaultShareButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide();
end)

reVaultShareButton:SetScript("OnClick", function(self)
    ReVault(true);
end)

hooksecurefunc(selectRewardButton, "SetShown", function(self)
	if self:IsShown() then
		reVaultShareButton:SetPoint("TOPLEFT", selectRewardButton, "TOPRIGHT", 30, 0);
	else
		reVaultShareButton:SetPoint("TOPLEFT", selectRewardButton, "TOPRIGHT", -73, 0);
	end
end)

local reVaultShareButtonBackground = reVaultShareButton:CreateTexture("$parentBackground", "BACKGROUND", nil, -1);
reVaultShareButtonBackground:SetAtlas("evergreen-weeklyrewards-frame-selectbutton", true);
reVaultShareButtonBackground:SetPoint("CENTER", 0, 0);

function ReVault(insertToEditbox)
	local characterName, realm = UnitFullName("player");
	if (insertToEditbox) then
		ChatFrame1EditBox:Show();
		ChatFrame1EditBox:SetText("[ReVault: " .. characterName .. "-" .. realm .."'s Vault]");
		ChatFrame1EditBox:SetFocus();
	else
		ChatFrame1:AddMessage("\124Hgarrmission:revault:\124h\124cFFFFFF00[".. characterName .. "-" .. realm .."'s Vault]\124h\124r");
	end
end

local NUM_COLUMNS = 3;
local SELECTION_STATE_HIDDEN = 1;
local SELECTION_STATE_UNSELECTED = 2;
local SELECTION_STATE_SELECTED = 3;

ReVaultMixin = { };

local function ShowRewards(self, showRewards)
	if showRewards then
		self.ViewingRewards = true;
		self.ToggleVaultProgressButton:SetText("Show Progress");
		self.HeaderFrame.Text:SetText("Viewing "..self.owner.."'s Last Vault");
	else
		self.ViewingRewards = false;
		self.ToggleVaultProgressButton:SetText("Show Rewards");
		self.HeaderFrame.Text:SetText("Viewing "..self.owner.."'s Current Vault");
	end
end

function ReVaultMixin:ToggleVaultProgress()
	ShowRewards(self, not self.ViewingRewards);
	self:FullRefresh();
end

function ReVaultMixin:OnLoad()
	self:SetMovable(true);
	self:EnableMouse(true);
    self:RegisterForDrag("LeftButton");
    self:SetScript("OnDragStart", self.StartMoving);
    self:SetScript("OnDragStop", self.StopMovingOrSizing);
	self.ViewingRewards = false;
	self.ToggleVaultProgressButton:SetScript("OnClick", function()
        self:ToggleVaultProgress()
    end)

	if ReVaultData == nil then
        ReVaultData = {
        }
    end

	self:SetUpActivity(self.RaidFrame, RAIDS, "evergreen-weeklyrewards-category-raids", Enum.WeeklyRewardChestThresholdType.Raid);
	self:SetUpActivity(self.MythicFrame, DUNGEONS, "evergreen-weeklyrewards-category-dungeons", Enum.WeeklyRewardChestThresholdType.Activities);

	self:SetActivityShown(true, self.WorldFrame, Enum.WeeklyRewardChestThresholdType.World);
	self:SetUpActivity(self.WorldFrame, WORLD, "evergreen-weeklyrewards-category-world", Enum.WeeklyRewardChestThresholdType.World);

	WeeklyRewardsFrame:SetActivityShown(false, WeeklyRewardsFrame.PVPFrame, Enum.WeeklyRewardChestThresholdType.RankedPvP);
	WeeklyRewardsFrame:SetActivityShown(true, WeeklyRewardsFrame.WorldFrame, Enum.WeeklyRewardChestThresholdType.World);
	WeeklyRewardsFrame:SetUpActivity(WeeklyRewardsFrame.WorldFrame, WORLD, "evergreen-weeklyrewards-category-world", Enum.WeeklyRewardChestThresholdType.World);

	local attributes =
	{
		area = "center",
		pushable = 0,
		allowOtherPanels = 1,
		checkFit = 1,		
	};
	RegisterUIPanel(ReVaultFrame, attributes);
end

function ReVaultMixin:OnShow()
	PlaySound(SOUNDKIT.UI_WEEKLY_REWARD_OPEN_WINDOW);
	local checkForData;
	local checkCount = 0;
	local check = true;
	self.Blackout:SetShown(true);
	self:GetOrCreateOverlay():Show();
	
	checkForData = C_Timer.NewTicker(1, function()
		if not check then checkForData:Cancel(); return end

		if self.activities then
			-- Player is online
			-- Data has been passed from transmit
			check = false;

			if self.activities.weeklyRewardsActivities and self.activities.progress then
				self.ToggleVaultProgressButton:Show();
			end

			ShowRewards(self, self.activities.hasRewards);
			self.Blackout:SetShown(false);
			self.Overlay:Hide();
			self:FullRefresh();
		else
			-- Player is offline
			checkCount = checkCount + 1;
			if (checkCount == 3) then
				check = false;

				if ReVaultData[self.owner] then
					self.activities = ReVaultData[self.owner]
					if self.activities.weeklyRewardsActivities and self.activities.progress then
						self.ToggleVaultProgressButton:Show();
					end

					ShowRewards(self, self.activities.hasRewards);
					self.Blackout:SetShown(false);
					self.Overlay:Hide();
					self:FullRefresh();
				else
					ReVaultFrame:Hide();
					UIErrorsFrame:AddMessage("No vault data found for "..self.owner, 1.0, 0.1, 0.1, 1.0);
				end
			end
		end
	end, 3)
end

function ReVaultMixin:OnHide()
	PlaySound(SOUNDKIT.UI_WEEKLY_REWARD_CLOSE_WINDOW);
	self.activities = nil;
	self.ViewingRewards = false;
	self.ToggleVaultProgressButton:SetText("Show Rewards");
	self.selectedActivity = nil;
	self.ToggleVaultProgressButton:Hide();
end

function ReVaultMixin:SetUpActivity(activityTypeFrame, name, atlas, activityType)
	activityTypeFrame.Name:SetText(name);
	local useAtlasSize = true;
	activityTypeFrame.Background:SetAtlas(atlas, useAtlasSize);

	local prevFrame;
	for i = 1, NUM_COLUMNS do
		local alreadyCreatedFrame = self:GetActivityFrame(activityType, i);
		if alreadyCreatedFrame then
			alreadyCreatedFrame:Show();
			prevFrame = alreadyCreatedFrame;
		else
			local frame = CreateFrame("FRAME", nil, self, "ReVaultActivityTemplate");
			if prevFrame then
				frame:SetPoint("LEFT", prevFrame, "RIGHT", 9, 0);
			else
				frame:SetPoint("LEFT", activityTypeFrame, "RIGHT", 44, 3);
			end

			frame.type = activityType;
			frame.index = i;
			prevFrame = frame;
		end
	end
end

function ReVaultMixin:SetActivityShown(isShown, activityTypeFrame, activityType)
	activityTypeFrame:SetShown(isShown);
	for i = 1, NUM_COLUMNS do
		local alreadyCreatedFrame = self:GetActivityFrame(activityType, i);
		if alreadyCreatedFrame then
			alreadyCreatedFrame:SetShown(isShown);
		end
	end
end

function ReVaultMixin:GetActivityFrame(activityType, index)
	for i, frame in ipairs(self.Activities) do
		if frame.type == activityType and frame.index == index then
			return frame;
		end
	end
end

function ReVaultMixin:FullRefresh()
	-- for preview item tooltips
	C_MythicPlus.RequestMapInfo();
	self:Refresh();
end

function ReVaultMixin:Refresh(playSheenAnims)
	local activities = (((self.activities.hasRewards and self.ViewingRewards) and self.activities.weeklyRewardsActivities) or ((not self.activities.hasRewards and self.ViewingRewards) and self.activities.weeklyRewardsActivities) or self.activities.progress or {}) or C_WeeklyRewards.GetActivities();
	self.ConcessionFrame:Hide();
	self:UpdateSelection();

	for i, activityInfo in ipairs(activities) do
		if i == 10 then break end		
		local frame = self:GetActivityFrame(activityInfo.type, activityInfo.index);

		if frame then
			frame:Refresh(activityInfo);
		end
	end
	
	self:SetHeight(657);
end

function ReVaultMixin:GetOrCreateOverlay()
	if self.Overlay then
		self.Overlay.Title:SetText("Loading "..self.owner.."'s Great Vault");
		return self.Overlay;
	end

	self.Overlay = CreateFrame("Frame", nil, self, "ReVaultOverlayTemplate");
	self.Overlay:SetPoint("TOP", self, "TOP", 0, -142);
	RaiseFrameLevel(self.Overlay);
	self.Overlay.Title:SetText("Loading "..self.owner.."'s Great Vault");
	self.Overlay.Text:SetText("");
	return self.Overlay;
end

function ReVaultMixin:UpdateSelection()
    local selectedActivity = self.selectedActivity;

    for i, frame in ipairs(self.Activities) do
        if frame and frame.SetSelectionState then
            local selectionState = SELECTION_STATE_HIDDEN;
            if selectedActivity and frame.hasRewards then
                if frame == selectedActivity then
                    selectionState = SELECTION_STATE_SELECTED;
                else
                    selectionState = SELECTION_STATE_UNSELECTED;
                end
            end
            frame:SetSelectionState(selectionState);
        end
    end
end

function ReVaultMixin:GetSelectedActivityInfo()
	return self.selectedActivity and self.selectedActivity.info;
end

ReVaultOverlayMixin = {};

local EVERGREEN_WEEKLY_REWARD_OVERLAY_EFFECT = { effectID = 179, offsetX = 3, offsetY = -20 };

function ReVaultOverlayMixin:OnShow()
	self.activeEffect = self.ModelScene:AddDynamicEffect(EVERGREEN_WEEKLY_REWARD_OVERLAY_EFFECT, self);
	NineSliceUtil.ApplyLayoutByName(self.NineSlice, "Dialog");
end

function ReVaultOverlayMixin:OnHide()
	if self.activeEffect then
		self.activeEffect:CancelEffect();
		self.activeEffect = nil;
	end
end

ReVaultActivityMixin = { };

function ReVaultActivityMixin:SetSelectionState(state)
	self.SelectedTexture:SetShown(state == SELECTION_STATE_SELECTED);
	self.SelectionGlow:SetShown(state == SELECTION_STATE_SELECTED);
	self.UnselectedFrame:SetShown(state == SELECTION_STATE_UNSELECTED);
end

function ReVaultActivityMixin:MarkForPendingSheenAnim()
	self.hasPendingSheenAnim = true;
end

local GENERATED_REWARD_MODEL_SCENE_EFFECT = { effectID = 179, offsetX = -35, offsetY = -15};
local GENERATED_REWARD_MODEL_SCENE_EFFECT_DECAY = { effectID = 180, offsetX = -36, offsetY = -5};

function ReVaultActivityMixin:Refresh(activityInfo)
	local thresholdString;
	if activityInfo.type == Enum.WeeklyRewardChestThresholdType.Raid then
		thresholdString = activityInfo.raidString;
	elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.Activities then
		thresholdString = WEEKLY_REWARDS_THRESHOLD_DUNGEONS;
	elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.RankedPvP then
		thresholdString = WEEKLY_REWARDS_THRESHOLD_PVP;
	elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.World then
		thresholdString = WEEKLY_REWARDS_THRESHOLD_WORLD;
	end

	self.Threshold:SetFormattedText(thresholdString, activityInfo.threshold);
	if (not self:GetParent().ViewingRewards) then
		self.unlocked = activityInfo.progress >= activityInfo.threshold;
		self.hasRewards = #activityInfo.rewards > 0;
		self.info = activityInfo;
		self:SetProgressText();
	else
		self.unlocked = activityInfo.rewards.itemLink;
		self.hasRewards = activityInfo.rewards.itemLink
		self.info = activityInfo;
		self:SetProgressText("");
	end

	local useAtlasSize = true;

	if self.unlocked or self.hasRewards then
		if self.Background then 
			self.Background:SetAtlas("evergreen-weeklyrewards-reward-unlocked", useAtlasSize);
		end
		self.Threshold:SetTextColor(NORMAL_FONT_COLOR:GetRGB());
		self.Progress:SetTextColor(GREEN_FONT_COLOR:GetRGB());
		self.CompletedIcon:Show();
		self.CompletedActivityFlipbook:Show();
		self.CompletedActivityAnim:Play();
		self.ItemFrame:Hide();
		if self.hasRewards then
			self.ItemFrame:SetRewards(activityInfo.rewards.itemLink);
			self.ItemGlow:Show();
			self.UncollectedGlow:Hide();
			self:ClearActiveEffect();
			self:SetActiveEffect(GENERATED_REWARD_MODEL_SCENE_EFFECT_DECAY);
		else
			if not self.activeEffectInfo or self.activeEffectInfo.effectID ~= GENERATED_REWARD_MODEL_SCENE_EFFECT.effectID then 
				self.UncollectedGlow:Show();
				self.UncollectedGlow.FadeAnim:Play();
				self:ClearActiveEffect();
				self:SetActiveEffect(GENERATED_REWARD_MODEL_SCENE_EFFECT);
			end 
			self.ItemGlow:Hide();
		end

		if self.hasPendingSheenAnim then
			self.hasPendingSheenAnim = nil;
			self.RewardGenerated:Show();
		end
	else
		self.Background:SetAtlas("evergreen-weeklyrewards-reward-locked", useAtlasSize);
		self.Threshold:SetTextColor(DISABLED_FONT_COLOR:GetRGB());
		self.Progress:SetTextColor(DISABLED_FONT_COLOR:GetRGB());
		self.CompletedIcon:Hide();
		self.CompletedActivityFlipbook:Hide();
		self.CompletedActivityAnim:Stop();
		self.ItemFrame:Hide();
		self.ItemGlow:Hide();
		self.RewardGenerated:Hide();
		self.UncollectedGlow:Hide();
		self.UncollectedGlow.FadeAnim:Stop();
		self:ClearActiveEffect();
	end
end

function ReVaultActivityMixin:SetActiveEffect(effectInfo)
	if effectInfo == self.activeEffectInfo then
		return;
	end

	self.activeEffectInfo = effectInfo;
	if self.activeEffect then
		self.activeEffect:CancelEffect();
		self.activeEffect = nil;
	end

	if effectInfo then
		local modelScene = self:GetParent().ModelScene;
		self.activeEffect = modelScene:AddDynamicEffect(effectInfo, self);
	end
end

function ReVaultActivityMixin:ClearActiveEffect()
	self:SetActiveEffect(nil);
end

function ReVaultActivityMixin:IsCompletedAtHeroicLevel()
	local difficultyID = C_WeeklyRewards.GetDifficultyIDForActivityTier(self.info.activityTierID);
	return difficultyID == DifficultyUtil.ID.DungeonHeroic;
end

function ReVaultActivityMixin:SetProgressText(text)
	local activityInfo = self.info;
	DevTool:AddData(self:GetParent().activities, 1)
	DevTool:AddData(activityInfo, 2)
	if text then
		self.Progress:SetText(text);
	elseif not self:GetParent().ViewingRewards and self.unlocked then
		if activityInfo.type == Enum.WeeklyRewardChestThresholdType.Raid then
			local name = DifficultyUtil.GetDifficultyName(activityInfo.level);
			self.Progress:SetText(name);
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.Activities then
			if self:IsCompletedAtHeroicLevel() then
				self.Progress:SetText(WEEKLY_REWARDS_HEROIC);
			else
				self.Progress:SetFormattedText(WEEKLY_REWARDS_MYTHIC, activityInfo.level);
			end
		elseif activityInfo.type == Enum.WeeklyRewardChestThresholdType.World then
			self.Progress:SetText(GREAT_VAULT_WORLD_TIER:format(activityInfo.level));
		end
	else
		self.Progress:SetFormattedText(GENERIC_FRACTION_STRING, activityInfo.progress, activityInfo.threshold);
		-- self.Progress:SetText("");
	end
end

local function FormatNumberWithCommas(number)
	local k;
    local formatted = tostring(number)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
            break
        end
    end
    return formatted
end

local function GetItemStats(itemLink)
    local stats = C_Item.GetItemStats(itemLink)
	if not stats then return end
    return {
        ["Damage Per Second"] = stats["ITEM_MOD_DAMAGE_PER_SECOND_SHORT"] or 0,
        ["Armor"] = stats["ITEM_MOD_ARMOR_SHORT"] or 0,
        ["Strength"] = stats["ITEM_MOD_STRENGTH_SHORT"] or 0,
        ["Agility"] = stats["ITEM_MOD_AGILITY_SHORT"] or 0,
        ["Intellect"] = stats["ITEM_MOD_INTELLECT_SHORT"] or 0,
        ["Stamina"] = stats["ITEM_MOD_STAMINA_SHORT"] or 0,
        ["Critical Strike"] = stats["ITEM_MOD_CRIT_RATING_SHORT"] or 0,
        ["Haste"] = stats["ITEM_MOD_HASTE_RATING_SHORT"] or 0,
        ["Versatility"] = stats["ITEM_MOD_VERSATILITY"] or 0,
        ["Mastery"] = stats["ITEM_MOD_MASTERY_RATING_SHORT"] or 0,
        ["Prismatic Socket"] = stats["EMPTY_SOCKET_PRISMATIC"] or 0
    }
end

local function AddItemComparison(tooltip, rewardItemLink, equippedItemLink)
    local statOrder = {
        "Damage Per Second",
        "Armor",
        "Strength",
        "Agility",
        "Intellect",
        "Stamina",
        "Critical Strike",
        "Haste",
        "Versatility",
        "Mastery",
        "Prismatic Socket"
    }
    
    local socketIcon = "|TInterface\\ItemSocketingFrame\\UI-EmptySocket-Prismatic:13|t  "
    local rewardItemStats = GetItemStats(rewardItemLink)
    local equippedItemStats = GetItemStats(equippedItemLink)
	local charName = string.match(ReVaultFrame.owner, "([^%-]+)");
    
	if not equippedItemStats then return end
    local statDifference = {}
    for _, stat in ipairs(statOrder) do
		if rewardItemStats then
			local statString = string.format("%.1f", rewardItemStats[stat] - equippedItemStats[stat]);
			statDifference[stat] = tonumber(statString);
		end
    end
    
    tooltip:AddLine("\nIf ".. charName .. " replaces this item, the following stat changes will occur:\n", 1, 0.87, 0, true)
    local _, _, _, equipSlot = C_Item.GetItemInfoInstant(rewardItemLink)
    
    for _, stat in ipairs(statOrder) do
        local value = statDifference[stat]
        local isSocket = stat == "Prismatic Socket"
        local prefix = value > 0 and "+" or ""
        local color = value < 0 and RED_FONT_COLOR or (value > 0 and GREEN_FONT_COLOR or WHITE_FONT_COLOR)

        if value ~= 0 then
		tooltip:AddLine(color:GenerateHexColorMarkup() .. prefix .. FormatNumberWithCommas(value) .. "|r " ..
                            (isSocket and socketIcon or "") .. WHITE_FONT_COLOR:GenerateHexColorMarkup() .. stat .. "|r");
        end
    end
end

function ReVaultActivityMixin:ShowPreviewItemTooltip()
    if not (self.info or self.info.rewards.itemLink) then return end
	local rewardItemLink = self.info.rewards.itemLink;
    if not rewardItemLink then return end

	local equippedItems = self.info.rewards.equippedItems;

	GameTooltip:SetOwner(self.ItemFrame, "ANCHOR_RIGHT", -3, -6);
	GameTooltip:SetHyperlink(self.info.rewards.itemLink);
	GameTooltip:Show();

	for i, equippedItemLink in ipairs(equippedItems) do
        if i == 1 then
            ShoppingTooltip1:SetOwner(GameTooltip, "ANCHOR_NONE");
            ShoppingTooltip1:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 0, -10);
			ShoppingTooltip1:SetWidth(GameTooltip:GetWidth());
            ShoppingTooltip1:SetHyperlink(equippedItemLink);
			AddItemComparison(ShoppingTooltip1, rewardItemLink, equippedItemLink);
            ShoppingTooltip1:Show();
        elseif i == 2 then
            ShoppingTooltip2:SetOwner(GameTooltip, "ANCHOR_NONE");
            ShoppingTooltip2:SetPoint("TOPLEFT", ShoppingTooltip1, "TOPRIGHT", 0, 0);
			ShoppingTooltip2:SetWidth(GameTooltip:GetWidth());
            ShoppingTooltip2:SetHyperlink(equippedItemLink);
			AddItemComparison(ShoppingTooltip2, rewardItemLink, equippedItemLink);
            ShoppingTooltip2:Show();
        end
    end
end

function ReVaultActivityMixin:HidePreviewItemTooltip()
    if not (self.info or self.info.rewards.itemLink) then return end

	local equippedItems = self.info and self.info.rewards.equippedItems;
	if not equippedItems then 
		return 
	end
	
	for i, _ in ipairs(equippedItems) do
		local equippedItemTooltip = _G["ShoppingTooltip"..i]
		equippedItemTooltip:Hide();
	end
	GameTooltip:Hide();
end


function ReVaultActivityMixin:OnEnter()
	self:ShowPreviewItemTooltip();
end

function ReVaultActivityMixin:OnLeave()
	self:HidePreviewItemTooltip();
end


function ReVaultActivityMixin:OnHide()
	self.hasPendingSheenAnim = nil;
	self:ClearActiveEffect();
end

ReVaultActivityItemMixin = { };

function ReVaultActivityItemMixin:OnEnter()
    self:GetParent():ShowPreviewItemTooltip();
end

function ReVaultActivityItemMixin:OnLeave()
    self:GetParent():HidePreviewItemTooltip();
end

function ReVaultActivityItemMixin:OnUpdate()
	-- if TooltipUtil.ShouldDoItemComparison() then
	-- 	GameTooltip_ShowCompareItem(GameTooltip);
	-- else
	-- 	GameTooltip_HideShoppingTooltips(GameTooltip);
	-- end
end

function ReVaultActivityItemMixin:OnClick()
	local activityFrame = self:GetParent();
	if IsModifiedClick() then
		HandleModifiedItemClick(self.itemLink);
	end
end

function ReVaultActivityItemMixin:SetDisplayedItem()
	self.itemLink = self:GetParent().info.rewards.itemLink;
	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemIcon = C_Item.GetItemInfo(self.itemLink);
	self.Name:SetText(itemName);
	self.Icon:SetTexture(itemIcon);
	SetItemButtonOverlay(self, self.itemLink);
	local itemLevel = C_Item.GetDetailedItemLevelInfo(self.itemLink);
	local progressText = string.format(ITEM_LEVEL, itemLevel);
	self:GetParent():SetProgressText(progressText);
	self:SetShown(true);
end

function ReVaultActivityItemMixin:SetRewards(itemLink)
	local itemId = tonumber(itemLink:match("Hitem:(%d+):"));
	local continuableContainer = ContinuableContainer:Create();
	local item = Item:CreateFromItemID(itemId);
	continuableContainer:AddContinuable(item);
		
	continuableContainer:ContinueOnLoad(function()
		self:SetDisplayedItem();
	end);
end

ReVaultConcessionMixin = { };

tinsert(UISpecialFrames, "ReVaultFrame")
UIPanelWindows["ReVaultFrame"] = nil