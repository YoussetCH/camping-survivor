--!strict

local ItemTypes = require(script.Parent.Parent.Types.Item)

export type ItemsModule = {
	get: (id: string) -> ItemTypes.ItemDefinition?,
	getAll: () -> { ItemTypes.ItemDefinition },
}

local definitions: { [string]: ItemTypes.ItemDefinition } = {
	stick = {
		id = "stick",
		displayName = "Palo",
		category = "raw",
		maxStack = 30,
	},
	stone = {
		id = "stone",
		displayName = "Piedra",
		category = "raw",
		maxStack = 30,
	},
	flint = {
		id = "flint",
		displayName = "Pedernal",
		category = "raw",
		maxStack = 10,
	},
	leaf = {
		id = "leaf",
		displayName = "Hojas",
		category = "raw",
		maxStack = 30,
	},
	fiber = {
		id = "fiber",
		displayName = "Fibra",
		category = "raw",
		maxStack = 30,
	},
	tinder = {
		id = "tinder",
		displayName = "Yesca",
		category = "processed",
		maxStack = 10,
	},
	berry = {
		id = "berry",
		displayName = "Bayas",
		category = "food",
		maxStack = 30,
	},
	bandage = {
		id = "bandage",
		displayName = "Vendaje",
		category = "medicine",
		maxStack = 10,
	},
	sparks = {
		id = "sparks",
		displayName = "Chispas",
		category = "processed",
		maxStack = 10,
	},
	wood = {
		id = "wood",
		displayName = "Madera",
		category = "raw",
		maxStack = 30,
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

return Items
