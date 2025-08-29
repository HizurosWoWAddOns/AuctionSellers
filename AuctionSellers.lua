
local addon, ns = ...;
local L,normalizedRealmName = ns.L;
ns.debugMode = "@project-version@"=="@".."project-version".."@";
LibStub("HizurosSharedTools").RegisterPrint(ns,addon,"AS");

local function AddOwners(owners)
	if not normalizedRealmName then
		normalizedRealmName = GetNormalizedRealmName();
	end
	for i=1, #owners do
		local name,color = owners[i],NORMAL_FONT_COLOR;
		if name~="player" and not name:find("%-") then
			name = name.."-"..normalizedRealmName;
		end
		GameTooltip_AddColoredLine(GameTooltip, ns.GetHighlight(name));
	end
end

local isShown = false;
local function lineOnEnter(line)
	local rowData = line:GetRowData();
	if not (rowData and rowData.owners and #rowData.owners>0) then
		return;
	end
	if line.rowData.containsOwnerItem or line.rowData.containsAccountItem then
		GameTooltip_AddColoredLine(GameTooltip, HOT_ITEM_SELLER, HIGHLIGHT_FONT_COLOR);
		AddOwners(line.rowData.owners);
		GameTooltip:Show();
	elseif GameTooltip:GetOwner()==line then
		--ns:debug(addon,"<lineOnEnter>","<line is already owner>","by?")
	else
		GameTooltip:SetOwner(line, "ANCHOR_RIGHT");
		GameTooltip_SetTitle(GameTooltip,HOT_ITEM_SELLER);
		AddOwners(line.rowData.owners);
		GameTooltip:Show();
		isShown = true;
	end
end

local function lineOnLeave(line)
	if isShown then
		GameTooltip:Hide();
	end
end

local hookedButtons = {};

local function hookListButtons()
	local view = AuctionHouseFrame.CommoditiesBuyFrame.ItemList.ScrollBox:GetView();
	if not (view and view:GetFrameCount()>0) then return; end
	local buttons = view:GetFrames();
	for i=1, #buttons do
		if not hookedButtons[buttons[i]] then
			buttons[i]:HookScript("OnEnter",lineOnEnter);
			buttons[i]:HookScript("OnLeave",lineOnLeave);
			hookedButtons[buttons[i]] = true;
		end
	end
end

local frame = CreateFrame("Frame");
local bnetEvents = {
	BN_CONNECTED=true,
	BN_DISCONNECTED=true,
	BN_FRIEND_ACCOUNT_OFFLINE=true,
	BN_FRIEND_ACCOUNT_ONLINE=true,
	BN_FRIEND_INFO_CHANGED=true,
	BN_INFO_CHANGED=true,
};
frame:SetScript("OnEvent",function(self,event,...)
	if event=="ADDON_LOADED" and addon==... then
		if type(AuctionSellersBNetFriendsDB)~="table" then
			AuctionSellersBNetFriendsDB = {};
		end
		normalizedRealmName = GetNormalizedRealmName();
		ns:print(L["AddOnLoaded"]);
		return;
	elseif event=="ADDON_LOADED" and ...=="Blizzard_AuctionHouseUI" then
		hooksecurefunc(AuctionHouseFrame.CommoditiesBuyFrame.ItemList.ScrollBox,"Update",hookListButtons);
		return;
	end

	-- update guild members
	if (event=="GUILD_ROSTER_UPDATE" or event=="PLAYER_LOGIN") and IsInGuild() then
		C_GuildInfo.GuildRoster();
		ns.UpdateGuildMembers();
	end

	-- update friends
	if (event=="" or event=="PLAYER_LOGIN") then
		ns.UpdateFriends();
	end

	-- update bnet friends
	if (bnetEvents[event] or event=="PLAYER_LOGIN") and BNConnected() then
		ns.UpdateBNetFriends();
	end
end);

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_LOGIN");
-- guild
frame:RegisterEvent("GUILD_ROSTER_UPDATE");
-- friends
frame:RegisterEvent("FRIENDLIST_UPDATE");
-- bnet friends
frame:RegisterEvent("BN_CONNECTED");
frame:RegisterEvent("BN_DISCONNECTED");
frame:RegisterEvent("BN_FRIEND_ACCOUNT_OFFLINE");
frame:RegisterEvent("BN_FRIEND_ACCOUNT_ONLINE");
frame:RegisterEvent("BN_FRIEND_INFO_CHANGED");
frame:RegisterEvent("BN_INFO_CHANGED");
