-- increment the index for each slash command
SLASH_SV1 = "/sv"

-- define the corresponding slash command handler
SlashCmdList.SV = function(msg, editBox)
	ShareVault();
end

function ShareVault()
	local characterName, realm = UnitFullName("player");
	-- ShareVaultFrame:Show();
	ChatFrame1:AddMessage("\124Hgarrmission:sharevault:\124h\124cFFFFFF00[".. characterName .. "-" .. realm .."'s Vault]\124h\124r");
end

local NUM_COLUMNS = 3;
local SELECTION_STATE_HIDDEN = 1;
local SELECTION_STATE_UNSELECTED = 2;
local SELECTION_STATE_SELECTED = 3;

ShareVaultMixin = { };

function ShareVaultMixin:SetUpConditionalActivities()
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

function ShareVaultMixin:OnLoad()
	self:SetMovable(true)
	self:EnableMouse(true)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", self.StartMoving)
    self:SetScript("OnDragStop", self.StopMovingOrSizing)

	if ShareVaultData == nil then
        ShareVaultData = {
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
	RegisterUIPanel(ShareVaultFrame, attributes);
end

function ShareVaultMixin:OnShow()
	PlaySound(SOUNDKIT.UI_WEEKLY_REWARD_OPEN_WINDOW);
	local checkCount = 0;
	local checkForData;
	checkForData = C_Timer.NewTicker(1, function()
		if self.activities then
			self:FullRefresh();
			checkForData:Cancel()
		else
			checkCount = checkCount + 1;
			if (checkCount == 3) then
				self.activities = ShareVaultData[self.owner]
				self:FullRefresh();
			end
		end
	end, 3)
end

function ShareVaultMixin:OnHide()
	PlaySound(SOUNDKIT.UI_WEEKLY_REWARD_CLOSE_WINDOW);
	self.activities = nil;
	self.selectedActivity = nil;
end

function ShareVaultMixin:SetUpActivity(activityTypeFrame, name, atlas, activityType)
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
			local frame = CreateFrame("FRAME", nil, self, "ShareVaultActivityTemplate");
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

function ShareVaultMixin:SetActivityShown(isShown, activityTypeFrame, activityType)
	activityTypeFrame:SetShown(isShown);
	for i = 1, NUM_COLUMNS do
		local alreadyCreatedFrame = self:GetActivityFrame(activityType, i);
		if alreadyCreatedFrame then
			alreadyCreatedFrame:SetShown(isShown);
		end
	end
end

function ShareVaultMixin:GetActivityFrame(activityType, index)
	for i, frame in ipairs(self.Activities) do
		if frame.type == activityType and frame.index == index then
			return frame;
		end
	end
end

function ShareVaultMixin:FullRefresh()
	-- for preview item tooltips
	C_MythicPlus.RequestMapInfo();
	self:Refresh(true);
end

function ShareVaultMixin:Refresh(playSheenAnims)
	-- local activities = self.activities
	local activities = self.activities or C_WeeklyRewards.GetActivities();

	self.HeaderFrame.Text:SetText(self.owner.."'s Vault");
	self.Blackout:SetShown(false);	
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

function ShareVaultMixin:UpdateSelection()
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

function ShareVaultMixin:GetSelectedActivityInfo()
	return self.selectedActivity and self.selectedActivity.info;
end

ShareVaultActivityMixin = { };

function ShareVaultActivityMixin:SetSelectionState(state)
	self.SelectedTexture:SetShown(state == SELECTION_STATE_SELECTED);
	self.SelectionGlow:SetShown(state == SELECTION_STATE_SELECTED);
	self.UnselectedFrame:SetShown(state == SELECTION_STATE_UNSELECTED);
end

function ShareVaultActivityMixin:MarkForPendingSheenAnim()
	self.hasPendingSheenAnim = true;
end

local GENERATED_REWARD_MODEL_SCENE_EFFECT = { effectID = 179, offsetX = -35, offsetY = -15};
local GENERATED_REWARD_MODEL_SCENE_EFFECT_DECAY = { effectID = 180, offsetX = -36, offsetY = -5};
function ShareVaultActivityMixin:Refresh(activityInfo)
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

function ShareVaultActivityMixin:SetActiveEffect(effectInfo)
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

function ShareVaultActivityMixin:ClearActiveEffect()
	self:SetActiveEffect(nil);
end

function ShareVaultActivityMixin:SetProgressText(text)
	local activityInfo = self.info;
	if text then
		self.Progress:SetText(text);
	else
		-- self.Progress:SetFormattedText(GENERIC_FRACTION_STRING, activityInfo.progress, activityInfo.threshold);
		self.Progress:SetText("");
	end
end

function ShareVaultActivityMixin:OnEnter()
	self:ShowPreviewItemTooltip();
end

function ShareVaultActivityMixin:ShowPreviewItemTooltip()
	if not self.info.rewards.itemLink then return end
	GameTooltip:SetOwner(self.ItemFrame, "ANCHOR_RIGHT", -3, -6);
	GameTooltip:SetHyperlink(self.info.rewards.itemLink);
	GameTooltip:Show();
end

function ShareVaultActivityMixin:OnLeave()
	self.UpdateTooltip = nil;
	GameTooltip:Hide();
end

function ShareVaultActivityMixin:OnHide()
	self.hasPendingSheenAnim = nil;
	self:ClearActiveEffect();
end

ShareVaultActivityItemMixin = { };

function ShareVaultActivityItemMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT", -3, -6);
	-- GameTooltip:SetOwner(self:GetParent(), "ANCHOR_RIGHT", -7, -11);
	GameTooltip:SetHyperlink(self.itemLink);
	self:SetScript("OnUpdate", self.OnUpdate);
end

function ShareVaultActivityItemMixin:OnLeave()
	GameTooltip:Hide();
	self:SetScript("OnUpdate", nil);
end

function ShareVaultActivityItemMixin:OnUpdate()
	if TooltipUtil.ShouldDoItemComparison() then
		GameTooltip_ShowCompareItem(GameTooltip);
	else
		GameTooltip_HideShoppingTooltips(GameTooltip);
	end
end

function ShareVaultActivityItemMixin:OnClick()
	local activityFrame = self:GetParent();
	if IsModifiedClick() then
		HandleModifiedItemClick(self.itemLink);
	end
end

function ShareVaultActivityItemMixin:SetDisplayedItem()
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

function ShareVaultActivityItemMixin:SetRewards(itemLink)
	local itemId = tonumber(itemLink:match("Hitem:(%d+):"));
	local continuableContainer = ContinuableContainer:Create();
	local item = Item:CreateFromItemID(itemId);
	continuableContainer:AddContinuable(item);
		
	continuableContainer:ContinueOnLoad(function()
		self:SetDisplayedItem();
	end);
end

ShareVaultConcessionMixin = { };

tinsert(UISpecialFrames, "ShareVaultFrame")
UIPanelWindows["ShareVaultFrame"] = nil