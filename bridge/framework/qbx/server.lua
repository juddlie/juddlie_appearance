if GetResourceState("qbx_core") ~= "started" then
	error("qbx_core is not started. Please start qbx_core before starting juddlie_appearance.")
end

local QBX <const> = exports["qbx_core"]

local bridge = {}

---@param src number
---@return string?
function bridge.getIdentifier(src)
	local player <const> = QBX:GetPlayer(src)
	if not player then return end

	return player.PlayerData.citizenid
end

---@param src number
---@return table
function bridge.getPlayerData(src)
	local player <const> = QBX:GetPlayer(src)
	if not player then return {} end

	local pd = player.PlayerData
	return {
		identifier = pd.citizenid,
		job = pd.job and pd.job.name or nil,
		jobGrade = pd.job and pd.job.grade and pd.job.grade.level or 0,
		gang = pd.gang and pd.gang.name or nil,
	}
end

return bridge