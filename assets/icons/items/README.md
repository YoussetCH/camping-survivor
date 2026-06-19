# Item icons

PNG source files for inventory and crafting UI. Uploaded to Roblox via Studio MCP; asset IDs live in `src/ReplicatedStorage/Shared/Constants/Items.luau` (`iconAssetId` per item).

| File | Item ID |
|------|---------|
| stick.png | stick |
| stone.png | stone |
| flint.png | flint |
| leaf.png | leaf |
| fiber.png | fiber |
| tinder.png | tinder |
| berry.png | berry |
| bandage.png | bandage |
| sparks.png | sparks |
| wood.png | wood |
| stone_axe.png | stone_axe |
| bp_campfire.png | bp_campfire |

Recipe icons use the first output item (`Recipes.getIconItemId`).

To re-upload after editing PNGs:

1. Serve this folder: `python3 -m http.server 8765`
2. Use Studio MCP `upload_image` with `http://localhost:8765/<file>.png`
3. Update `iconAssetId` values in `Items.luau`
