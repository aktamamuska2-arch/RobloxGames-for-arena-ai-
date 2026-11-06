-- ServerStorage/NOTES
-- DEVLOG NOTES in ServerStorage
2024/07/07
-- 00: Initialized with animations, sounds, punching script, custom walking/running sounds.
-- 01: Left click continuous, attack cooldown, attack cooldown progress bar GUI.
-- 02: Hit counter works (resets after 2 seconds of inactivity) locally as required.
-- 03: Hit counter causes problems with multiple weapon tools. Added custom sword model. Set proper sword animations.
-- 04: [X][Hit counter] Made additional variants for the sword. Added custom katana model with variants.
-- 05: [X][Hit counter] Added custom spear with variants.
2024/07/08
-- 01: Hit counter problem has been solved, by letting a server-side script handle the hit counter instead of within the weapon LocalScript.
-- 02: Made weapon control variables more accessible and modular via String and Number Values. Turned 'swords' into Tools.
-- 03: Made a simple shop model and a talking NPC with player proximity detection.
-- 04: Made a fully-functional loading screen.
-- 05: Tried to make a dynamic shop GUI, but failed.
-- 06: Manual category, dynamic item fetching system implemented for the shop. Struggling to find best angle for 3D viewports.
-- 07: [X][Dynamic category] Found a suitable angle at last! Items now rotate in 3D in the shop GUI.
-- 08: [X][Dynamic category] Added shop purchasing logic. Items are buyable. But the currency "GT" DataStore isn't saving on player exit.
-- 09: [X][Dynamic category, DataStore not saving]
----------- Found out the reason why DataStore isn't saving! The changes are being made in a LocalScript (SwordsScript)! Need to use Remote Events.
----------- Also found another error: hit damage doesn't affect everyone. Same reason as above. Need to refactor into a Server Script for handling remote events.
2024/07/09
-- 01: [X][Dynamic category, DataStore not saving, hit damage] Updated the combat script and weapon LocalScripts to let the server handle hits and damage.
-- 02: [X][Dynamic category, DataStore not saving] Updated the LocalScript to only handle the cooldown progress bar; everything else is sent as a payload to CombatHandler.
-- 03: [X][Dynamic category] Updated the currency handler, shop handler, and added a new script for adding tools to inventory. DataStores saves GT successfully now.
-- 04: Dynamic category is unnecessary for the shop. Too much work for too few options. Added new script for saving/loading inventory item names to/from DataStores.
-- 05: Fixed a minor issue of equipped items not being saved when a player leaves.
-- 06: Added an inventory GUI like Ohio in "MainGui", but lacking the code to apply it. Made new Wallet model/tool.
-- 07: Modified the Wallet's display font to a monospace one. Getting the issue of equipped items not being saved again.
-- 08: [X][Items throw error when loading inventory, idlewalkanim sometimes doesn't load] Trying to fix errors.
-- 09: [X][Items throw error when loading inventory, idlewalkanim sometimes doesn't load] Decided to change the Shop GUI into a Skin GUI; Swords are now only 1 type each, and the variants are "skins".
----------- (Decision: Make this game more like "Ohio" and transfer the Shop features to "Bangla Battlegrounds" for a more "Combat Warriors" vibe)
----------- Temporarily disabled Swords script in the SkinGui (ex: ShopGui) because refactoring is required.
----------- Something strange happens to the inventory when player dies/respawns (check the PlayerAdded/PlayerRemoved, etc. parts of code)
-- 10: Inventory saving/loading issue seems to be solved. Added buying prompt for "shop crates" like "Ohio". Possible issue of multiple calls to the buying logic. Added menu icons panel.
2024/07/10
-- 01: Added a "debounce" mechanism to prevent multiple purchases for a single click on a shop crate.
-- 02: Debounce still fails if player already has multiple instances of the item in the "backpack" inventory. Disallowed players from buying multiple duplicates of the same item.
-- 03: Inventory saving/loading problem solved by player.CharacterAdded:Connect event.
-- 04: Added katanas to the shop. And additional skins/variants to ReplicatedStorage.
-- 05: Added spears to the shop. Added icons for martial, wallet, sword, katana, spear.
-- 06: [X][IdleWalkAnim doesn't load sometimes] Added new Codes GUI for redeeming codes, with related scripts.
-- 07: [X][Shop multiple purchases, inventory not loading] Trying to make house models.
-- 08: [X][Shop multiple purchases, inventory not loading] Made a bungalow house inspired by the basic "Ohio" house.
-- 09: [X][Shop multiple purchases] Idk what I'm doing, lol. Currently trying to make a cool map ASAP.
2024/07/11
-- 01: Began working on a castle-like area using Synty Dungeon Pack assets.
-- 02: Made a castle hallway.
2024/07/12
-- 01: Made a custom gun system based on a UMP45 model I made, and Rufus14's NPC AI script (same as the NPCs in "Broken")
-- 02: Working on the exterior side of the "castle" area.
2024/07/13
-- 01: Working on an outer region beyond the "castle" area.
-- 02: Added a "{IQUA} Cathedral" by devil1mood for the "castle".
-- 03: Turned the baseplate into terrain. Adjusted terrain for the roads, paths, etc. Moved the "shop" outdoors.
-- 04: Added outfit "characters" that can be equipped for appearance and/or abilities.
2024/07/14
-- 01: Arranged all the weapon meshes into categories: shields, scythes, axes [1H], axes [2H], maces [1H], hammers [2H], swords [1H], swords [2H], spears, staves, specials.
-- 02: Turned the swords into tools, and added a ProximityPrompt for the shop.
-- 03: Enabled the old Shop GUI for the shop. Decided to keep inventory items after death, although haven't changed the scripts yet.
-- 04: Shop works, inventory works, no multiple purchases. All praise be to the Almighty!
-- 05: NPC dummies now respawn automatically and drop gold! Although the respawn doesn't work properly.
-- 06: [X][Inventory 'sometimes' doesn't save after death, custom Health gui doesn't work 'sometimes'] Added a ka-ching sound for transactions
----------- Need to make the trashing campfire only accept specific items (and not the default wallet, martial, etc.)
2024/07/15
-- 01: Fixed the campfire trashing thing. NPC dummies now respawn correctly, too. Only need to make sure the inventory problem is resolved.
-- 02: The inventory system is fixed (maybe) Bruh, now the items remain even after removing/trashing them! :(
-- 03: Fixed the obsidian sword model not getting welded properly. Souls Gui works, but the Souls models are messed up, so reverting back to Soulstemp script.
-- 04: Added NPC dialog GUI. Works okay. Nvm, it causes conflicts with multiple NPCs with the dialog texts not being updated.
----------- Ah, I see the problem now! The dialog is only becoming invisible, but it's not getting "deactivated" when the NPC is bade goodbye.
----------- Bloody hell! The custom health GUI hadn't been working properly all this time!
-- 05: NPC dialog scripts fixed. But the custom health GUI isn't. Maybe I'd have to work on a new one.
2024/07/16
-- 01: Added health, energy and xp progress GUI (StatsGui). Not scripted yet.
-- 02: Added "leaderstats" for player level and playtime.
-- 03: Inventory system (almost) fixed, XP & Level system fixed. All praise be to the Almighty!
----------- only problem with inv sys is that equipped items don't get saved when players leave the game.
-- 04: Shop GUI issue with Script/LocalScript GUI manipulation mismatch fixed by putting everything into the "PromptScript" Script.
-- 05: Added Level XP progress bar GUI and a new custom Health GUI.
-- 06: Added "Energy" player data and GUI. Possible issue with how the energy is depleted and/or replenished.
-- 07: IdleWalkRun needs to implement the Energy depletion mechanic. Tried but failed.
-- 08: [X][Energy depletion/recharge, inventory not saving equipped items] Added DataStore for player stats (MaxHealth, MaxEnergy, Strength, Agility, Soul).
----------- Will need to add the "leveling up" GUI for incrementing the stat values when players level up.
-- 09: [X][Energy depletion/recharge, inventory not saving equipped items] Made sure DataStore stat values are loaded/saved properly and initialized if not found.
-- 10: [X][Energy depletion/recharge, inventory not saving equipped items] Added VFX trails for swords like Blox Fruits.
2024/07/17
-- 01: [X][Energy depletion/recharge, inventory not saving equipped items] Made new Stats GUI for upgrading stats from level points. But no scripts yet.
-- 02: [X][Energy depletion/recharge, inventory not saving equipped items] Added scripts for displaying the stats, but haven't put the final script yet.
-- 03: [X][Energy depletion/recharge, inventory not saving equipped items] Stat upgrade GUI works. But something goes wrong when player respawns/dies.
-- 04: [X][Inventory not saving equipped items] Stat upgrade GUI works fully now. Energy depletes on sprint, recharges automatically when not sprinting.