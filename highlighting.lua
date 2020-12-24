
local addon, ns = ...;
local guildMembers,friends,numGuildMembers,numFriends,bnetFriends,normalizedRealmName = {},{},0;

function ns.IsKnown(name)
	return guildMembers[name] or bnetFriends[name] or friends[name];
end

function ns.GetHighlight(name)
	local label,color
	if name=="player" then
		return YOU,GREEN_FONT_COLOR;
	elseif guildMembers[name] then
		label,color = LFG_LIST_GUILD_MEMBER,GREEN_FONT_COLOR;
	elseif bnetFriends[name] then
		label,color = bnetFriends[name],BATTLENET_FONT_COLOR;
	elseif friends[name] then
		label,color = FRIEND,ORANGE_FONT_COLOR;
	else
		return name,NORMAL_FONT_COLOR;
	end
	return name.." ("..label..")",color;
end

function ns.UpdateGuildMembers()
	local tmp, fullName, name = {}
	local numMembers = GetNumGuildMembers();
	if numGuildMembers==numMembers then
		return;
	end
	numGuildMembers = numMembers;
	for i=1, numMembers do
		fullName = GetGuildRosterInfo(i);
		if fullName then
			tmp[fullName]=true;
		end
	end
	guildMembers = tmp;
end

function ns.UpdateFriends()
	if not normalizedRealmName then
		normalizedRealmName = GetNormalizedRealmName();
	end
	local tmp,num,friend = {},C_FriendList.GetNumFriends();
	if numFriends==num then
		return;
	end
	numFriends = num;
	for i=1, num do
		friend = C_FriendList.GetFriendInfoByIndex(i);
		if not friend.name:find("%-") then
			friend.name = friend.name.."-"..normalizedRealmName;
		end
		tmp[friend.name] = true;
	end
	friends = tmp;
end

function ns.UpdateBNetFriends()
	if not normalizedRealmName then
		normalizedRealmName = GetNormalizedRealmName()
	end

	if bnetFriends==nil then
		bnetFriends = AuctionSellersBNetFriendsDB;
	end

	-- blizzard could move BNGetNumFriends in near future... i think ^.^
	-- I'm surprised it hasn't happened yet.
	local num,accountInfo,name = (BNGetNumFriends or C_BattleNet.BNGetNumFriends or C_BattleNet.GetNumFriends)();
	local accounts = {};
	for i=1, num do
		accountInfo = C_BattleNet.GetFriendAccountInfo(i)
		if accountInfo and accountInfo.gameAccountInfo.isOnline and accountInfo.gameAccountInfo.clientProgram == BNET_CLIENT_WOW and accountInfo.gameAccountInfo.realmName then
			name = accountInfo.gameAccountInfo.characterName.."-"..accountInfo.gameAccountInfo.realmName;
			if not bnetFriends[name] then
				bnetFriends[name] = accountInfo.battleTag;
			end
			accounts[accountInfo.battleTag] = true;
		end
	end
	-- cleanup removed battlenet friendships
	for name,battleTag in pairs(AuctionSellersBNetFriendsDB) do
		if not accounts[battleTag] then
			bnetFriends[name] = nil;
		end
	end
end
