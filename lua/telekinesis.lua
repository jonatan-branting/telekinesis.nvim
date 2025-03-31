local Logger = require("telekinesis.lib.logger")

local Telekinesis = {}

function Telekinesis.instance()
  assert(_G.telekinesis_instance, "Telekinesis has not been setup")

  return _G.telekinesis_instance
end

function Telekinesis.logger()
  return Logger:new(
    {
      level = vim.env.telekinesis_LOG_LEVEL or "debug"
    }
  )
end

function Telekinesis.setup(opts)
  Telekinesis.logger():debug("Telekinesis.setup")

  opts = vim.tbl_extend(
    "force",
    require("telekinesis.config").default_opts,
    opts or {}
  )

  _G.telekinesis_instance = Telekinesis:new(opts)

  return _G.telekinesis_instance
end

function Telekinesis:new(opts)
  local instance = {
    opts = opts,
    logger = Telekinesis.logger(),
  }

  setmetatable(instance, self)
  self.__index = self

  require("telekinesis.treesitter.query").add_directives()

  return instance
end

return Telekinesis
