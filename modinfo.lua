name = "Player Status (server)"
description = "View other player's status, including some other properties. Press \"\\\" to toggle the list.\nIf you want to manually change the max number of players shown, you can use the command ChangeScale(maxplayersnumber)."
author = "rawii22 & lord_of_les_ralph"
version = "2.0"

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
		label = "Show only for host?",
		hover = "Let's you chose if you want others to see the player stats list.",
		options = {
			{ description = "No", data = false},
			{ description = "Yes", data = true},
		},
		default = true
	},
	{
		name = "SCALE",
		label = "Max num players visible",
		hover = "Scales text size. You can change if your server only allows a small number of people.",
		options = {
			{ description = "6 (big)", data = 115},
			{ description = "12", data = 60},
			{ description = "20", data = 36.5},
			{ description = "30 (smaaaall)", data = 24.3},
			{ description = "50 (micro)", data = 14.6},
		},
		default = 36.5
	},
}