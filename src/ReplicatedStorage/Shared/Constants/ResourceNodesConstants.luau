--!strict

export type NodeType = "gather" | "chop"

export type ParsedOutput = {
	itemId: string,
	minQuantity: number,
	maxQuantity: number,
}

export type ResourceNodesConstantsModule = {
	GLOBAL_RESPAWN_SECONDS: number,
	PLAYER_COOLDOWN_SECONDS: number,
	AXE_TOOL_PREFIXES: { string },
	parseOutputs: (raw: string) -> { ParsedOutput },
	rollOutputs: (raw: string) -> { { itemId: string, quantity: number } },
	matchesAxeTool: (toolItemId: string?) -> boolean,
	getNodeType: (nodeType: string) -> NodeType?,
}

local ResourceNodesConstants: ResourceNodesConstantsModule = {
	GLOBAL_RESPAWN_SECONDS = 180,
	PLAYER_COOLDOWN_SECONDS = 60,
	AXE_TOOL_PREFIXES = { "axe_", "stone_axe", "pick_" },
}

function ResourceNodesConstants.parseOutputs(raw: string): { ParsedOutput }
	local outputs: { ParsedOutput } = {}

	for segment in string.gmatch(raw, "[^,]+") do
		local trimmed = string.match(segment, "^%s*(.-)%s*$") or segment
		local itemId, quantitySpec = string.match(trimmed, "^([^:]+):(.+)$")

		if itemId ~= nil and quantitySpec ~= nil then
			local minQuantity = tonumber(string.match(quantitySpec, "^(%d+)")) or 1
			local maxQuantity = tonumber(string.match(quantitySpec, "%-(%d+)$")) or minQuantity

			if maxQuantity < minQuantity then
				maxQuantity = minQuantity
			end

			table.insert(outputs, {
				itemId = itemId,
				minQuantity = minQuantity,
				maxQuantity = maxQuantity,
			})
		end
	end

	return outputs
end

function ResourceNodesConstants.rollOutputs(raw: string): { { itemId: string, quantity: number } }
	local rolled: { { itemId: string, quantity: number } } = {}

	for _, output in ResourceNodesConstants.parseOutputs(raw) do
		local quantity = output.minQuantity

		if output.maxQuantity > output.minQuantity then
			quantity = math.random(output.minQuantity, output.maxQuantity)
		end

		table.insert(rolled, {
			itemId = output.itemId,
			quantity = quantity,
		})
	end

	return rolled
end

function ResourceNodesConstants.matchesAxeTool(toolItemId: string?): boolean
	if toolItemId == nil then
		return false
	end

	for _, prefix in ResourceNodesConstants.AXE_TOOL_PREFIXES do
		if string.sub(toolItemId, 1, #prefix) == prefix or toolItemId == prefix then
			return true
		end
	end

	return false
end

function ResourceNodesConstants.getNodeType(nodeType: string): NodeType?
	if nodeType == "gather" or nodeType == "chop" then
		return nodeType
	end

	return nil
end

return ResourceNodesConstants
