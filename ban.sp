#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <emitsoundany>
#pragma semicolon 1

#define PLUGIN_VERSION "1.6"

public Plugin:myinfo = 
{
	name = "[NEVERGO] Ban [File]",
	author = "Lawyn",
	description = "Original plugin",
	version = PLUGIN_VERSION,
	url = ""
}

#define WHITELIST_MAX 255

new String:whitelist[WHITELIST_MAX][64];
new listlen;

public OnPluginStart()
{
	AutoExecConfig(true, "banlawyn");
	RegAdminCmd("sm_banreload", CommandReload, ADMFLAG_ROOT, "Reincarca banurile");
	RegAdminCmd("sm_banlist", CommandList, ADMFLAG_BAN, "Listeaza banurile");
	RegAdminCmd("sm_ban", CommandAdd, ADMFLAG_BAN, "Adauga ban");
	//RegAdminCmd("sm_addban", CommandAddBan, ADMFLAG_BAN, "Adauga ban");
	LoadList();
}

public OnClientPostAdminCheck(client)
{
	if(!IsFakeClient(client))
	{
		new String:auth[64];
		GetClientAuthString(client, auth, sizeof(auth));
		new bool:allow = false;
		for(new i; i < listlen; i++)
		{
			if(strcmp(auth, whitelist[i]) == 0)
			{
				allow = false;
				KickClient(client, "Ai fost banat permanent pe acest server (%s)", auth);
			}
		}
	}
}

public Action:CommandReload(client, args)
{
	LoadList();
	ReplyToCommand(client, " \x0f[ NGO ] \x01Ban-urile au fost reimprospatate (\x0C%d\x01)", listlen);
	return Plugin_Handled;
}

public Action:CommandList(client, args)
{
	PrintToChat(client," \x0f[ NGO ] \x01Banurile s-au generat in consola \x01(\x0C%d\x01)", listlen);
	for(new i; i < listlen; i++)
	{
		PrintToConsole(client, " > %s", whitelist[i]);
	}
	return Plugin_Handled;
}

public Action:CommandAdd(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, " \x0f[ NGO ] \x01Foloseste: \x0Csm_ban <nume> <motiv>");
		return Plugin_Handled;
	}
	new String:steamid[64];
	char arg1[64];
	char motiv[256];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, motiv, sizeof(motiv));
	new target = FindTarget(client, arg1, true, true);
	GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(PathType:Path_SM, path, sizeof(path), "bans/ban_list.txt");
	
	new Handle:file = OpenFile(path, "a");
	if(file != INVALID_HANDLE)
	{
		if(IsClientConnected(target))
		{
			WriteFileLine(file, steamid);
			whitelist[listlen] = steamid;
			listlen++;
			char kickreason[256];
			Format(kickreason, sizeof(kickreason), "Ai fost banat permanent pe acest server\nSteamID: %s\nAdmin: %N\nDurata: Permanent\nMotiv: %s", steamid, client, motiv);
			KickClient(target, kickreason);
			ReplyToCommand(client, " \x0f[ NGO ] \x01Adminul \x0C%N \x01i-a dat ban permanent lui \x0C%s \x01pe motivul: \x0C%s", client, target, motiv);
		}
		else
		{
			PrintToChat(client, " \x0f[ NGO ] \x01Jucatorul nu a putut fi gasit!");
		}
	}
	else
	{
		ReplyToCommand(client, " \x0f[ NGO ] \x01Nu s-a putut scrie fisierul: \x0C%s", path);
	}
	CloseHandle(file);
	
	return Plugin_Handled;
}

public Action:CommandAddBan(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, " \x0f[ NGO ] \x01Foloseste: \x0Csm_addban <steamid> ");
		return Plugin_Handled;
	}
	char steamid[64];
	
	GetCmdArg(1, steamid, sizeof(steamid));
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(PathType:Path_SM, path, sizeof(path), "bans/ban_list.txt");
	
	new Handle:file = OpenFile(path, "a");
	if(file != INVALID_HANDLE)
	{
		WriteFileLine(file, steamid);
		whitelist[listlen] = steamid;
		listlen++;
		ReplyToCommand(client, " \x0f[ NGO ] \x01Adminul \x0C%N \x01i-a dat ban steamid-ului: \x0f%s", client, steamid);
	}
	else
	{
		ReplyToCommand(client, " \x0f[ NGO ] \x01Nu s-a putut scrie fisierul: \x0C%s", path);
	}
	CloseHandle(file);
	
	return Plugin_Handled;
}

public LoadList()
{
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(PathType:Path_SM, path, sizeof(path), "bans/ban_list.txt");
	
	new Handle:file = OpenFile(path, "r");
	if(file == INVALID_HANDLE)
	{
		SetFailState("[ NGO ] Nu se poate citi fisierul: %s", path);
	}
	
	listlen = 0;
	new String:steamid[64];
	while(!IsEndOfFile(file) && ReadFileLine(file, steamid, sizeof(steamid)))
	{
		if (steamid[0] == ';' || !IsCharAlpha(steamid[0]))
		{
			continue;
		}
		new len = strlen(steamid);
		for (new i; i < len; i++)
		{
			if (IsCharSpace(steamid[i]) || steamid[i] == ';')
			{
				steamid[i] = '\0';
				break;
			}
		}
		whitelist[listlen] = steamid;
		listlen++;
	}
	
	CloseHandle(file);
}

public IsImmune(client)
{
	new bool:immune = false;
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		immune = true;
	}
	return immune;
}
