--!strict

local ItemTypes = require(script.Parent.Parent.Types.Item)

export type ItemsModule = {
	get: (id: string) -> ItemTypes.ItemDefinition?,
	getAll: () -> { ItemTypes.ItemDefinition },
	getNameKey: (id: string) -> string,
}

local definitions: { [string]: ItemTypes.ItemDefinition } = {
	stick = {
		id = "stick",
		nameKey = "item.stick.name",
		category = "raw",
		maxStack = 30,
	},
	stone = {
		id = "stone",
		nameKey = "item.stone.name",
		category = "raw",
		maxStack = 30,
	},
	flint = {
		id = "flint",
		nameKey = "item.flint.name",
		category = "raw",
		maxStack = 10,
	},
	leaf = {
		id = "leaf",
		nameKey = "item.leaf.name",
		category = "raw",
		maxStack = 30,
	},
	fiber = {
		id = "fiber",
		nameKey = "item.fiber.name",
		category = "raw",
		maxStack = 30,
	},
	tinder = {
		id = "tinder",
		nameKey = "item.tinder.name",
		category = "processed",
		maxStack = 10,
	},
	berry = {
		id = "berry",
		nameKey = "item.berry.name",
		category = "food",
		maxStack = 30,
	},
	bandage = {
		id = "bandage",
		nameKey = "item.bandage.name",
		category = "medicine",
		maxStack = 10,
	},
	sparks = {
		id = "sparks",
		nameKey = "item.sparks.name",
		category = "processed",
		maxStack = 10,
	},
	wood = {
		id = "wood",
		nameKey = "item.wood.name",
		category = "raw",
		maxStack = 30,
	},
	stone_axe = {
		id = "stone_axe",
		nameKey = "item.stone_axe.name",
		category = "tool",
		maxStack = 1,
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

return Items
