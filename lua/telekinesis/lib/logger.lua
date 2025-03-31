local Logger = {}

local levels = {
  { name = "trace", hl = "Comment" },
  { name = "debug", hl = "Comment" },
  { name = "info", hl = "None" },
  { name = "warn", hl = "WarningMsg" },
  { name = "error", hl = "ErrorMsg" },
  { name = "fatal", hl = "ErrorMsg" },
}

function Logger:new(opts)
  local instance = {
    minimum_level = opts.level,
    levels_to_print = {}
  }

  local minimum_level_found = false

  for i, level in ipairs(levels) do
    if instance.minimum_level ==  level.name then
      minimum_level_found = true
    end

    if minimum_level_found then
      table.insert(instance.levels_to_print, level.name)
    end
  end

  setmetatable(instance, self)
  self.__index = self

  return instance
end

function Logger:should_print_level(level)
  for _, v in ipairs(self.levels_to_print) do
    if v == level then
      return true
    end
  end
  return false
end

function Logger:log(level, ...)
  if self:should_print_level(level) then
    print(...)
  end
end

function Logger:debug(...)
  self:log("debug", ...)
end

function Logger:info(...)
  self:log("info", ...)
end

function Logger:warn(...)
  self:log("warn", ...)
end

function Logger:error(...)
  self:log("error", ...)
end

function Logger:fatal(...)
  self:log("fatal", ...)
end

function Logger:trace(...)
  self:log("trace", ...)
end

return Logger
