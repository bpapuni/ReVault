-- increment the index for each slash command
SLASH_SV1 = "/sv"

-- define the corresponding slash command handler
SlashCmdList.RV = function(msg, editBox)
	ReVault();
end

function ReVault()
	local characterName, realm = UnitFullName("player");
	-- ReVaultFrame:Show();
	ChatFrame1:AddMessage("\124Hgarrmission:revault:\124h\124cFFFFFF00[".. characterName .. "-" .. realm .."'s Vault]\124h\124r");
end

local NUM_COLUMNS = 3;
local SELECTION_STATE_HIDDEN = 1;
local SELECTION_STATE_UNSELECTED = 2;
local SELECTION_STATE_SELECTED = 3;

ReVaultMixin = { };

function ReVaultMixin:SetUpConditionalActivities()
	self.showWorldRow = false;
	local activities = C_WeeklyRewards.GetActivities();
	for i, activityInfo in ipairs(activities) do
		if activityInfo.type == Enum.WeeklyRewardChestThresholdType.World then
			self.showWorldRow = true;
			break;
		end
	end

	self.showPVPRow = not self.showWorldRow;

	self:SetActivityShown(self.showPVPRow, self.PVPFrame, Enum.WeeklyRewardChestThresholdType.RankedPvP);
	if self.showPVPRow then
		self:SetUpActivity(self.PVPFrame, PVP, "evergreen-weeklyrewards-category-pvp", Enum.WeeklyRewardChestThresholdType.RankedPvP);
	end

	self:SetActivityShown(self.showWorldRow, self.WorldFrame, Enum.WeeklyRewardChestThresholdType.World);
	if self.showWorldRow then
		self:SetUpActivity(self.WorldFrame, WORLD, "evergreen-weeklyrewards-category-world", Enum.WeeklyRewardChestThresholdType.World);
	end
end

function ReVaultMixin:OnLoad()
	self:SetMovable(true)
	self:EnableMouse(true)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", self.StartMoving)
    self:SetScript("OnDragStop", self.StopMovingOrSizing)

	if ReVaultData == nil then
        ReVaultData = {
        }
    end

	self:SetUpActivity(self.RaidFrame, RAIDS, "evergreen-weeklyrewards-category-raids", Enum.WeeklyRewardChestThresholdType.Raid);
	self:SetUpActivity(self.MythicFrame, DUNGEONS, "evergreen-weeklyrewards-category-dungeons", Enum.WeeklyRewardChestThresholdType.Activities);

	self:SetUpConditionalActivities();

	local attributes =
	{
		area = "center",
		pushable = 0,
		allowOtherPanels = 1,
		checkFit = 1,		
	};
	RegisterUIPanel(ReVaultFrame, attributes);
end

local function GetServerTime(timestamp)
    local localTime = date("%a %b %d %H:%M %Y", timestamp)

    return localTime;
end

function ReVaultMixin:OnShow()
	PlaySound(SOUNDKIT.UI_WEEKLY_REWARD_OPEN_WINDOW);
	local checkCount = 0;
	local checkForData;
	self.Blackout:SetShown(true);
	self:GetOrCreateOverlay():Show();
	checkForData = C_Timer.NewTicker(1, function()
		if self.activities then
			self.HeaderFrame.Text:SetText(self.owner.."'s Vault");
			self.Blackout:SetShown(false);
			self.Overlay:Hide();
			self:FullRefresh();
			checkForData:Cancel()
		else
			checkCount = checkCount + 1;
			if (checkCount == 3) then
				self.activities = ReVaultData[self.owner];
				self.timestamp = GetServerTime(self.activities.timestamp);
				self.HeaderFrame.Text:SetText(self.owner.."'s Vault\nCurrent as of "..self.timestamp);
				self.Blackout:SetShown(false);
				self.Overlay:Hide();
				self:FullRefresh();
			end
		end
	end, 3)
end

function ReVaultMixin:OnHide()
	PlaySound(SOUNDKIT.UI_WEEKLY_REWARD_CLOSE_WINDOW);
	self.activities = nil;
	self.selectedActivity = nil;
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
	self:Refresh(true);
end

function ReVaultMixin:Refresh(playSheenAnims)
	local activities = self.activities or C_WeeklyRewards.GetActivities();
	self.ConcessionFrame:Hide();
	self:UpdateSelection();

	for i, activityInfo in ipairs(activities) do
		if i == 10 then break end
		-- local activityType = { 1, 6, 3 };
		-- local activityTypeIndex = math.floor((i - 1) / 3) + 1;
		
		-- activityInfo.type = activityType[activityTypeIndex];
		-- activityInfo.index = ((i - 1) % 3) + 1;
		-- activityInfo.threshold = weeklyRewardsActivities[i].threshold
		
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
	if (not self:GetParent().activities) then
		self.unlocked = false;
		self.hasRewards = false
		self.info = activityInfo;
	else
		self.unlocked = activityInfo.progress >= activityInfo.threshold;
		self.hasRewards = activityInfo.rewards.itemLink
		self.info = activityInfo;
	end

	self:SetProgressText();

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

function ReVaultActivityMixin:SetProgressText(text)
	local activityInfo = self.info;
	if text then
		self.Progress:SetText(text);
	else
		-- self.Progress:SetFormattedText(GENERIC_FRACTION_STRING, activityInfo.progress, activityInfo.threshold);
		self.Progress:SetText("");
	end
end

function ReVaultActivityMixin:ShowPreviewItemTooltip()
    if not self.info.rewards.itemLink then return end

	local equippedItems = self.info.rewards.equippedItems;

	GameTooltip:SetOwner(self.ItemFrame, "ANCHOR_RIGHT", -3, -6);
	GameTooltip:SetHyperlink(self.info.rewards.itemLink);
	GameTooltip:Show();

	for i, itemLink in ipairs(equippedItems) do
        -- Use built-in ShoppingTooltip1 and ShoppingTooltip2 for comparisons
        if i == 1 then
            ShoppingTooltip1:SetOwner(GameTooltip, "ANCHOR_NONE");
            ShoppingTooltip1:SetPoint("TOPLEFT", GameTooltip, "TOPRIGHT", 0, 0);
            ShoppingTooltip1:SetHyperlink(itemLink);
            ShoppingTooltip1:Show();
        elseif i == 2 then
            ShoppingTooltip2:SetOwner(GameTooltip, "ANCHOR_NONE");
            ShoppingTooltip2:SetPoint("TOPLEFT", ShoppingTooltip1, "TOPRIGHT", 0, 0);
            ShoppingTooltip2:SetHyperlink(itemLink);
            ShoppingTooltip2:Show();
        end
    end
end

function ReVaultActivityMixin:HidePreviewItemTooltip()
    if not self.info.rewards.itemLink then return end

	local equippedItems = self.info.rewards.equippedItems;
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