local Maybe = require("telekinesis.lib.maybe")

local Enumerable = {}

setmetatable(Enumerable, {
  __call = function(self, ...)
    return self:new(...)
  end,
})

function Enumerable:new(items)
  local instance = {
    items = items or {},
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

function Enumerable:append(item)
  table.insert(self.items, item)
end

function Enumerable:insert(item)
  table.insert(self.items, item)
end

function Enumerable:length()
  return #self.items
end

function Enumerable:reverse()
  local reversed = {}

  for i = #self.items, 1, -1 do
    table.insert(reversed, self.items[i])
  end

  return Enumerable:new(reversed)
end

function Enumerable:contains(item)
  for _, i in pairs(self.items) do
    if i == item then
      return true
    end
  end

  return false
end

function Enumerable:excludes(item)
  for _, i in pairs(self.items) do
    if i == item then
      return false
    end
  end

  return true
end

function Enumerable:partition(func)
  local a = {}
  local b = {}
  for _, item in pairs(self.items) do
    if func(item) then
      table.insert(a, item)
    else
      table.insert(b, item)
    end
  end

  return a, b
end

function Enumerable:any(func)
  if not func then
    return self:length() > 0
  end

  return self:find(func) ~= nil
end

function Enumerable:group_by(func)
  local groups = {}

  for _, item in pairs(self.items) do
    local key = func(item)

    if not groups[key] then
      groups[key] = Enumerable:new()
    end

    groups[key]:append(item)
  end

  return Enumerable:new(groups)
end

function Enumerable:dup()
  local copied_items = {}

  for _, item in pairs(self.items) do
    table.insert(copied_items, item)
  end

  return Enumerable:new(copied_items)
end

function Enumerable:empty()
  return self:length() == 0
end

function Enumerable:to_table()
  return self.items
end

function Enumerable:each(func_or_func_name)
  local func = nil
  if type(func_or_func_name) == "string" then
    func = function(item, ...) return item[func_or_func_name](item, ...) end
  else
    func = func_or_func_name
  end

  for i, item in pairs(self.items) do
    func(item, i)
  end

  return self
end

function Enumerable:map(func_or_func_name)
  local mapped = {}

  local func = nil
  if type(func_or_func_name) == "string" then
    func = function(item, ...) return item[func_or_func_name](item, ...) end
  else
    func = func_or_func_name
  end

  for i, item in pairs(self.items) do
    local result, _ = func(item, i)

    table.insert(mapped, result)
  end

  return Enumerable:new(mapped)
end

function Enumerable:filter(func)
  local filtered = {}

  for _, item in pairs(self.items) do
    if func(item) then
      table.insert(filtered, item)
    end
  end

  return Enumerable:new(filtered)
end

function Enumerable:select(func)
  return self:filter(func)
end

function Enumerable:reject(func)
  local filtered = {}

  for _, item in pairs(self.items) do
    if not func(item) then
      table.insert(filtered, item)
    end
  end

  return Enumerable:new(filtered)
end

function Enumerable:reduce(func, initial)
  local result = initial

  for _, item in pairs(self.items) do
    result = func(result, item)
  end

  return result
end

function Enumerable:find(func)
  for _, item in pairs(self.items) do
    if func(item) then
      return item
    end
  end
end

function Enumerable:find_maybe(func)
  for _, item in pairs(self.items) do
    if func(item) then
      return Maybe(item)
    end
  end

  return Maybe(nil)
end

function Enumerable:_then(func)
  return func(self.items)
end

function Enumerable:tap(func)
  func(self.items)

  return self
end

function Enumerable:last(count)
  count = count or 1
  if count == 1 then
    return self.items[self:length()]
  end

  local result = {}

  for i = self:length() - count + 1, self:length() do
    table.insert(result, self.items[i])
  end

  return result
end

function Enumerable:first(count)
  count = count or 1
  local result = {}

  for i = 1, count do
    table.insert(result, self.items[i])
  end

  return result
end

function Enumerable:table()
  return self.items
end

function Enumerable:_items()
  return self.items
end

function Enumerable:sort(func)
  table.sort(self.items, function(a, b)
    return func(a) < func(b)
  end)

  return self
end

function Enumerable:maybe(func)
  local result = func(self)

  return Maybe(result)
end

return Enumerable
