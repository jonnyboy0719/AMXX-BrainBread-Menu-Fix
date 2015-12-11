/* AMX Mod X
*   Maps Menu Plugin
*
* by the AMX Mod X Development Team
*  originally developed by OLO
*
* This file is part of AMX Mod X.
*
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation,
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
*  In addition, as a special exception, the author gives permission to
*  link the code of this program with the Half-Life Game Engine ("HL
*  Engine") and Modified Game Libraries ("MODs") developed by Valve,
*  L.L.C ("Valve"). You must obey the GNU General Public License in all
*  respects for all of the code used other than the HL Engine and MODs
*  from Valve. If you modify this file, you may extend this exception
*  to your version of the file, but you are not obligated to do so. If
*  you do not wish to do so, delete this exception statement from your
*  version.
*/

#include <amxmodx>
#include <amxmisc>

new Array:g_mapName;
new g_mapNums
new g_menuPosition[33]

new SelectedMap[33]

new g_voteSelectedNum[33]

public plugin_init()
{
	register_plugin("Maps Menu", AMXX_VERSION_STR, "AMXX Dev Team")
	register_dictionary("mapsmenu.txt")
	register_dictionary("common.txt")

	register_clcmd("say","hook_say")
	register_clcmd("say_team","hook_say")

	register_menucmd(register_menuid("Votemap Menu"), 1023, "actionVoteMapMenu")

	g_mapName=ArrayCreate(32);
	
	new maps_ini_file[64];
	get_configsdir(maps_ini_file, 63);
	format(maps_ini_file, 63, "%s/maps.ini", maps_ini_file);

	if (!file_exists(maps_ini_file))
		get_cvar_string("mapcyclefile", maps_ini_file, sizeof(maps_ini_file) - 1);
		
	if (!file_exists(maps_ini_file))
		format(maps_ini_file, 63, "mapcycle.txt")
	
	load_settings(maps_ini_file)
}

//------------------
//	hook_say()
//------------------

public hook_say(id)
{
	new said[32]
	read_argv(1, said, 31)
	remove_quotes(said)

	if (equali(said[0], "/vote"))
	{
		if (get_cvar_float("amx_last_voting") > get_gametime())
		{
			client_print(id, print_chat, "%L", id, "ALREADY_VOT")
			return PLUGIN_HANDLED
		}

		g_voteSelectedNum[id] = 0

		if (g_mapNums)
		{
			displayVoteMapsMenu(id, g_menuPosition[id] = 0)
		} else {
			console_print(id, "%L", id, "NO_MAPS_MENU")
			client_print(id, print_chat, "%L", id, "NO_MAPS_MENU")
		}
	}

	return PLUGIN_CONTINUE
}

displayVoteMapsMenu(id, pos)
{
	if (pos < 0)
		return

	new menuBody[512], b = 0, start = pos * 7

	if (start >= g_mapNums)
		start = pos = g_menuPosition[id] = 0

	new len = format(menuBody, 511, "\y%L %d/%d^n\w^n", id, "VOTEMAP_MENU", pos + 1, (g_mapNums / 7 + ((g_mapNums % 7) ? 1 : 0)))
	new end = start + 7, keys = MENU_KEY_0

	if (end > g_mapNums)
		end = g_mapNums

	new tempMap[32];
	for (new a = start; a < end; ++a)
	{
		ArrayGetString(g_mapName, a, tempMap, charsmax(tempMap));
		keys |= (1<<b)
		len += format(menuBody[len], 511-len, "\w%d. %s^n", ++b, tempMap)
	}

	if (end != g_mapNums)
	{
		len += format(menuBody[len], 511-len, "\y9. MORE^n")
		keys |= MENU_KEY_9
	}
	else
		len += format(menuBody[len], 511-len, "\y9. EXIT^n")

	new menuName[64]
	format(menuName, 63, "%L", "en", "VOTEMAP_MENU")

	show_menu(id, keys, menuBody, -1, menuName)
}

public actionVoteMapMenu(id, key)
{
	new tempMap[32];
	switch (key)
	{
		case 8: displayVoteMapsMenu(id, ++g_menuPosition[id])
		case 9: displayVoteMapsMenu(id, --g_menuPosition[id])
		default:
		{
			SelectedMap[id] = g_menuPosition[id] * 7 + key
			ArrayGetString(g_mapName, SelectedMap[id], tempMap, charsmax(tempMap));
			client_cmd(id, "votemap %s", tempMap);
		}
	}

	return PLUGIN_HANDLED
}

stock bool:ValidMap(mapname[])
{
	if ( is_map_valid(mapname) )
	{
		return true;
	}
	// If the is_map_valid check failed, check the end of the string
	new len = strlen(mapname) - 4;
	
	// The mapname was too short to possibly house the .bsp extension
	if (len < 0)
	{
		return false;
	}
	if ( equali(mapname[len], ".bsp") )
	{
		// If the ending was .bsp, then cut it off.
		// the string is byref'ed, so this copies back to the loaded text.
		mapname[len] = '^0';
		
		// recheck
		if ( is_map_valid(mapname) )
		{
			return true;
		}
	}
	
	return false;
}

load_settings(filename[])
{
	new fp = fopen(filename, "r");
	
	if (!fp)
	{
		return 0;
	}
		

	new text[256];
	new tempMap[32];
	
	while (!feof(fp))
	{
		fgets(fp, text, charsmax(text));
		
		if (text[0] == ';')
		{
			continue;
		}
		if (parse(text, tempMap, charsmax(tempMap)) < 1)
		{
			continue;
		}
		if (!ValidMap(tempMap))
		{
			continue;
		}
		
		ArrayPushString(g_mapName, tempMap);
		g_mapNums++;
	}

	fclose(fp);

	return 1;
}
