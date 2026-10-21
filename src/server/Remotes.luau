--!strict
-- Gets (or creates) a RemoteEvent in ReplicatedStorage.Remotes. Only the
-- server creates remotes; clients wait for them with WaitForChild.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local function getFolder(): Instance
	local existing = ReplicatedStorage:FindFirstChild("Remotes")
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	return folder
end

function Remotes.get(name: string): RemoteEvent
	local folder = getFolder()
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("RemoteEvent") then
		return existing
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

return Remotes
