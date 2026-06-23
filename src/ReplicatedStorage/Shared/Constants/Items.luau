--!strict

local ItemTypes = require(script.Parent.Parent.Types.Item)

export type ItemsModule = {
	get: (id: string) -> ItemTypes.ItemDefinition?,
	getAll: () -> { ItemTypes.ItemDefinition },
	getNameKey: (id: string) -> string,
	getIconAssetId: (id: string) -> number?,
}

local definitions: { [string]: ItemTypes.ItemDefinition } = {
	stick = {
		id = "stick",
		nameKey = "item.stick.name",
		category = "raw",
		maxStack = 30,
		iconAssetId = 80155224613147,
	},
	stone = {
		id = "stone",
		nameKey = "item.stone.name",
		category = "raw",
		maxStack = 30,
		iconAssetId = 85645012953146,
	},
	flint = {
		id = "flint",
		nameKey = "item.flint.name",
		category = "raw",
		maxStack = 10,
		iconAssetId = 105442743288171,
	},
	leaf = {
		id = "leaf",
		nameKey = "item.leaf.name",
		category = "raw",
		maxStack = 30,
		iconAssetId = 115900584628312,
	},
	fiber = {
		id = "fiber",
		nameKey = "item.fiber.name",
		category = "raw",
		maxStack = 30,
		iconAssetId = 104267172186105,
	},
	tinder = {
		id = "tinder",
		nameKey = "item.tinder.name",
		category = "processed",
		maxStack = 10,
		iconAssetId = 81982444539218,
	},
	berry = {
		id = "berry",
		nameKey = "item.berry.name",
		category = "food",
		maxStack = 30,
		iconAssetId = 93669238932589,
	},
	bandage = {
		id = "bandage",
		nameKey = "item.bandage.name",
		category = "medicine",
		maxStack = 10,
		iconAssetId = 75635417626973,
	},
	antidote = {
		id = "antidote",
		nameKey = "item.antidote.name",
		category = "medicine",
		maxStack = 10,
		iconAssetId = 75635417626973,
	},
	herb_common = {
		id = "herb_common",
		nameKey = "item.herb_common.name",
		category = "raw",
		maxStack = 20,
		iconAssetId = 115900584628312,
	},
	sparks = {
		id = "sparks",
		nameKey = "item.sparks.name",
		category = "processed",
		maxStack = 10,
		iconAssetId = 95375202329318,
	},
	wood = {
		id = "wood",
		nameKey = "item.wood.name",
		category = "raw",
		maxStack = 30,
		iconAssetId = 98678398563582,
	},
	stone_axe = {
		id = "stone_axe",
		nameKey = "item.stone_axe.name",
		category = "tool",
		maxStack = 1,
		iconAssetId = 80295401817385,
	},
	bp_campfire = {
		id = "bp_campfire",
		nameKey = "item.bp_campfire.name",
		category = "blueprint",
		maxStack = 1,
		iconAssetId = 91432023295936,
	},
	bp_chest = {
		id = "bp_chest",
		nameKey = "item.bp_chest.name",
		category = "blueprint",
		maxStack = 1,
		iconAssetId = 91432023295936,
	},
	bp_craft_table = {
		id = "bp_craft_table",
		nameKey = "item.bp_craft_table.name",
		category = "blueprint",
		maxStack = 1,
		iconAssetId = 91432023295936,
	},
	rope = {
		id = "rope",
		nameKey = "item.rope.name",
		category = "processed",
		maxStack = 20,
		iconAssetId = 104267172186105,
	},
}

local Items: ItemsModule = {}

function Items.get(id: string): ItemTypes.ItemDefinition?
	return definitions[id]
end

function Items.getAll(): { ItemTypes.ItemDefinition }
	local allItems: { ItemTypes.ItemDefinition } = {}

	for _, item in definitions do
		table.insert(allItems, item)
	end

	return allItems
end

function Items.getNameKey(id: string): string
	local item = definitions[id]

	if item ~= nil then
		return item.nameKey
	end

	return `item.{id}.name`
end

function Items.getIconAssetId(id: string): number?
	local item = definitions[id]

	if item ~= nil then
		return item.iconAssetId
	end

	return nil
end

return Items
