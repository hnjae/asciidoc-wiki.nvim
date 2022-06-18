-- The module that keeps variables to be accessed by other modules.

local M = {}


-- TODO: do i need this? <2022-06-18, Hyunjae Kim>
M.update_config = function(config)
  M.config = config
end

return M
