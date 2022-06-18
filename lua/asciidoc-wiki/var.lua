-- The module that keeps variables to be accessed by other modules.

local M = {}


-- TODO: do i need this? <2022-06-18, Hyunjae Kim>
local update_config = function(config)
  M.config = config
end
M.update_config = update_config

return M
