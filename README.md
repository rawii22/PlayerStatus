# PlayerStatus
**Purpose:** See the stats and properties of other players.

**Authors:** Alberto Romanach and Ricardo Romanach

**Steam page:** https://steamcommunity.com/sharedfiles/filedetails/?id=2169859220

**GitHub page:** https://github.com/rawii22/PlayerStatus


## Notes
***
In order to understand some terminology in the comments, I'll describe some stuff here.

These are some "scenarios" you might see referenced in the comments:
1. Non-dedicated non-caves
2. Non-dedicated with caves
3. Dedicated non-caves
4. Dedicated with caves

## Flow
***
1. Set up a netvar in each player's "player_classified" prefab.
2. Set up a periodic task (in each shard if caves are enabled)
    * Non-caves servers:
        * Periodic task will collect the data from AllPlayers and update everybody's netvar
        * When the netvar changes, every client's player list widget will update
    * Caves-enabled servers
        * The periodic task in each shard will SEND the data to the opposite shard via RPC.
        * Each shard will be awaiting the foreign player list and construct the final player list with the overworld players always being first.
        * Each shard will only update the netvars for players in that shard.
        * When the netvar changes, every client's player list widget will update

## Custom Console Commands
***
```
ChangeScale(number)
```

This command will change the scale of the widget that displays the player stats. If desired, it is supposed to resize the widget comfortably according to the current number of players in the server. However, any number can be used here until a good fit is acquired.

Parameters:
* number - Must be a positive number.

---

**The following custom console commands take in a number based on the player list on the screen and send the command to the proper shard if necessary. If the target player is already in the same shard, the command will simply be run locally.**

**These commands also use a special RPC that allows any Lua string to be executed in the opposite shard.**

```
RevivePlayer(number)
```
This will revive players in any shard as long as the player number from the player stat list is used.

Parameters:
* number - Must be a player number as seen on the player stat list.

```
RefillStats(number)
```
This will fully refill the stats of any player in any shard as long as the player number from the player stat list is used.

Parameters:
* number - Must be a player number as seen on the player stat list.

```
Godmode(number)
```
This will make any player enter godmode in any shard as long as the player number from the player stat list is used.

Parameters:
* number - Must be a player number as seen on the player stat list.

## Configurations
***

1. Show the player stat list only on the host
    * Default: yes
2. Toggle key for the player list
    * Default: \
3. Status abbreviation
    * Default: Hunger = "HG" Sanity = "S" Health = "HP"
4. Status number format
    * Default: current value / max value
5. Show health penalties
    * Default: yes
6. Show player numbers
    * Default: yes
7. Hide your own stats
    * Default: yes
8. Widget scale
    * Default: 20 players (36.5 internally)