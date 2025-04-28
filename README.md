# Raid Loot Announcer

This is the initial release for RaidLootAnnouncer. It's been the culmination of two weeks of learning Lua every afternoon.

## What does it do?

This addon for World of Warcraft takes a CSV formatted string and transforms it using a schema building string, represented by "Profile" in the addon. This is meant to represent Tier. It also takes a second string which is the reserve data which the user can clear easily with the addon. Once data has been imported into the addon, the user can set the selected difficulty of the encounters and tier name set by the imported "Profile Name" from the other tab. Now the user just clicks on the boss names to view the list of loot reservations, if any.

## Data Formatting

### Tier/Profile
Difficulty, Encounter Name/Boss Name, Tier/Game Version number, Encounter order/Boss order

### Loot Reservation
Reserver/Character, Difficulty, Encounter Name/Boss Name, Reserved Item

## About the Data

### Encounter Name/Boss Name
Note that Encounter Name/Boss Name are recurring data points. These tie the relations of loot reservations to the structure of the tier. 

### Difficulty
This is hard-coded to just be either Normal, Heroic, or Mythic. This should be fine for the rest of the game, but who knows-- Maybe Blizzard will some day add Mythic+ difficulty to raid like they did Mythic back in Mists of Pandaria. Just keep in note that capitalization does matter (maybe in a future release we make it case insensitive).
