name = "Player Status"
description = "View the stats of other players, including some other properties.\n"
.."By default, press \"\\\" to toggle the list.\n"
.."This mod also adds a few console commands. "
.."ChangeScale(*number*) will manually change the font size.\n"
.."--The following admin commands use the player number from the stat list.--\n"
.."RevivePlayer(*playerNumber*) will revive players in either shard.\n"
.."RefillStats(*playerNumber*) will refill the stats of players in either shard.\n"
.."Godmode(*playerNumber*) will make a player enter godmode in either shard.\n"
author = "rawii22 & lord_of_les_ralph"
version = "3.0.1"
icon = "modicon.tex"
icon_atlas = "modicon.xml"

forumthread = ""

api_version = 10

priority = - 1
dst_compatible = true
all_clients_require_mod = true
client_only_mod = false

configuration_options =
{
	{
		name = "HOSTONLY",
		label = "Show only for host",
		hover = "Lets you chose if you want others to see the player stats list.",
		default = true,
		options = {
			{ description = "No", data = false},
			{ description = "Yes", data = true},
		},
	},
	{
		name = "TOGGLEKEY",
		label = "Toggle Player Stats",
		default = "\\",
		options = {
			{description = "A", data = "A"},
			{description = "B", data = "B"},
			{description = "C", data = "C"},
			{description = "D", data = "D"},
			{description = "E", data = "E"},
			{description = "F", data = "F"},
			{description = "G", data = "G"},
			{description = "H", data = "H"},
			{description = "I", data = "I"},
			{description = "J", data = "J"},
			{description = "K", data = "K"},
			{description = "L", data = "L"},
			{description = "M", data = "M"},
			{description = "N", data = "N"},
			{description = "O", data = "O"},
			{description = "P", data = "P"},
			{description = "Q", data = "Q"},
			{description = "R", data = "R"},
			{description = "S", data = "S"},
			{description = "T", data = "T"},
			{description = "U", data = "U"},
			{description = "V", data = "V"},
			{description = "W", data = "W"},
			{description = "X", data = "X"},
			{description = "Y", data = "Y"},
			{description = "Z", data = "Z"},
			{description = "[", data = "["},
			{description = "]", data = "]"},
			{description = "\\", data ="\\"},
			{description = ";", data = ";"},
			{description = "\'", data ="\'"},
			{description = "/", data = "/"},
			{description = "-", data = "-"},
			{description = "=", data = "="}
		}
	},
	{
		name = "ABBREVIATESTATS",
		label = "Stat names",
		hover = "Abbreviated: HG:# | S:# | HP:#\nNormal: Hunger:# | Sanity:# | Health:#",
		default = {HUNGER = "HG:", SANITY = "S:", HEALTH = "HP:"},
		options = {
			{ description = "Abbreviated", data = {HUNGER = "HG:", SANITY = "S:", HEALTH = "HP:"}},
			{ description = "Normal", data = {HUNGER = "Hunger:", SANITY = "Sanity:", HEALTH = "Health:"}},
			{ description = "None", data = {HUNGER = "", SANITY = "", HEALTH = ""}},
		},
	},
	{
		name = "STATNUMFORMAT",
		label = "Stat number format",
		hover = "Fraction: HG: current/max\tPercent: HG: 100%\nBoth: HG: current/max (100%)",
		default = "$current/$maximum",
		options = {
			{ description = "Both", data = "$current/$maximum ($percent%)"},
			{ description = "Fraction", data = "$current/$maximum"},
			{ description = "Percent", data = "$percent%"},
		},
	},
	{
		name = "SHOWPENALTY",
		label = "Show stat penalties",
		hover = "If enabled, you will see health and sanity penalty percentages next to their respective stats.",
		default = true,
		options = {
			{ description = "Yes", data = true},
			{ description = "No", data = false},
		},
	},
	{
		name = "SHOWPLAYERNUMS",
		label = "Show player numbers",
		hover = "If enabled, you will see the number of each player.",
		default = true,
		options = {
			{ description = "Yes", data = true},
			{ description = "No", data = false},
		},
	},
	{
		name = "HIDEOWNSTATS",
		label = "Hide your own stats",
		hover = "If you select yes, your own stats will be hidden from the player stats list.",
		default = false,
		options = {
			{ description = "Yes", data = true},
			{ description = "No", data = false},
		},
	},
	{
		name = "SCALE",
		label = "Text size",
		hover = "Scales text size. The bigger the number, the smaller the text. Size can also be changed manually with the console command ChangeScale(*number*)",
		default = 36.5,
		options = {
			{ description = "6 (big)", data = 115},
			{ description = "12", data = 60},
			{ description = "20", data = 36.5},
			{ description = "30 (smaaaall)", data = 24.3},
			{ description = "50 (micro)", data = 14.6},
		},
	},
}