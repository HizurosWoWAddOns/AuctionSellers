
local addon, ns = ...;
local L,normalizedRealmName = ns.L;

do
	local addon_short = "AS" --L[addon.."_Shortcut"];
	local colors = {"0099ff","00ff00","ff6060","44ffff","ffff00","ff8800","ff44ff","ffffff"};
	ns.debugMode = "@project-version@" == "@".."project-version".."@";
	local function colorize(...)
		local t,c,a1 = {tostringall(...)},1,...;
		if type(a1)=="boolean" then tremove(t,1); end
		if a1~=false then
			tinsert(t,1,"|cff0099ff"..((a1==true and addon_short) or (a1=="||" and "||") or addon).."|r"..(a1~="||" and HEADER_COLON or ""));
			c=2;
		end
		for i=c, #t do
			if not t[i]:find("\124c") then
				t[i],c = "|cff"..colors[c]..t[i].."|r", c<#colors and c+1 or 1;
			end
		end
		return unpack(t);
	end
	function ns.print(...)
		print(colorize(...));
	end
	function ns.debug(name,...)
		ConsolePrint(date("|cff999999%X|r"),colorize("<debug::"..name..">",...));
	end
	function ns.debugPrint(name,...)
		if not ns.debugMode then return end
		print(colorize("<debug::"..name..">",...))
	end
	if ns.debugMode then
		_G[addon.."_GetNamespace"] = function()
			return ns;
		end
	end
end

local bnetFriends = {}
local function collectBnetFriends()
end

local friends = {}
local function collectFriends()
end

local guildMembers = {};
local function collectGuildMembers()
	local fullName
	if not normalizedRealmName then
		normalizedRealmName = GetNormalizedRealmName(); -- fail save
	end
	for i=1, (GetNumGuildMembers()) do
		fullName = GetGuildRosterInfo(i);
		if fullName then
			guildMembers[fullName]=true;
			fullName = fullName:gsub("%-"..normalizedRealmName,"");
			guildMembers[fullName]=true;
		end
	end
end

local function AddOwners(owners)
	for i=1, #owners do
		local name,color = owners[i],NORMAL_FONT_COLOR;
		if name=="player" then
			name,color = YOU,GREEN_FONT_COLOR;
		elseif guildMembers[name] then
			name,color = name.." ("..LFG_LIST_GUILD_MEMBER..")",GREEN_FONT_COLOR;
		elseif bnetFriends[name] then
			name,color = name.." ("..FRIEND..")",ORANGE_FONT_COLOR;
		elseif friends[name] then
			name,color = name.." ("..FRIEND..")",BATTLENET_FONT_COLOR;
		end
		GameTooltip_AddColoredLine(GameTooltip, name, color);
	end
end

local isShown = false;
local function lineOnEnter(line)
	if line.rowData.containsOwnerItem or line.rowData.containsAccountItem then
		GameTooltip_AddColoredLine(GameTooltip, HOT_ITEM_SELLER, HIGHLIGHT_FONT_COLOR);
		AddOwners(line.rowData.owners);
		GameTooltip:Show();
	elseif GameTooltip:GetOwner()==line then
		ConsolePrint(addon,"<lineOnEnter>","<line is already owner>","by?")
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

do
	local isInitialized = false;
	local function hookCreateTableBuilder(buttons)
		if not AuctionHouseFrame.CommoditiesBuyFrame.ItemList.tableBuilder then return end
		for i=1, #buttons do
			buttons[i]:HookScript("OnEnter",lineOnEnter);
			buttons[i]:HookScript("OnLeave",lineOnLeave);
		end
		isInitialized = true;
	end
	hooksecurefunc(_G,"CreateTableBuilder",function(buttons,TableBuilderMixin)
		if isInitialized then return end
		if TableBuilderMixin~=AuctionHouseTableBuilderMixin then return end
		C_Timer.After(0.1,function()
			hookCreateTableBuilder(buttons);
		end);
	end);
end

local frame = CreateFrame("Frame");
frame:SetScript("OnEvent",function(self,event,...)
	if event=="ADDON_LOADED" and addon==(...) then
		ns.print(L["AddOnLoaded"]);
	elseif IsInGuild() and (event=="GUILD_ROSTER_UPDATE" or event=="PLAYER_LOGIN") then
		if not normalizedRealmName then
			normalizedRealmName = GetNormalizedRealmName();
		end
		C_GuildInfo.GuildRoster();
		collectGuildMembers();
	end
	-- friends event
	-- bnet friends event
end);

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("PLAYER_LOGIN");
frame:RegisterEvent("GUILD_ROSTER_UPDATE");
