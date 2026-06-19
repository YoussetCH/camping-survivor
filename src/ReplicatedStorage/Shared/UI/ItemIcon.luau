--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Items = require(ReplicatedStorage.Shared.Constants.Items)

export type ItemIconModule = {
	getImageContent: (itemId: string) -> string?,
	applyTo: (imageLabel: ImageLabel, itemId: string?) -> (),
}

local ItemIcon: ItemIconModule = {} :: ItemIconModule

function ItemIcon.getImageContent(itemId: string): string?
	local assetId = Items.getIconAssetId(itemId)

	if assetId == nil then
		return nil
	end

	return `rbxassetid://{assetId}`
end

function ItemIcon.applyTo(imageLabel: ImageLabel, itemId: string?)
	if itemId == nil then
		imageLabel.Visible = false
		imageLabel.Image = ""
		return
	end

	local content = ItemIcon.getImageContent(itemId)

	if content == nil then
		imageLabel.Visible = false
		imageLabel.Image = ""
		return
	end

	imageLabel.Image = content
	imageLabel.Visible = true
end

return ItemIcon
