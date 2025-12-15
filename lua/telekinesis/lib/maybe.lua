local Maybe = {}

setmetatable(Maybe, {
  __call = function(self, ...)
    return self:new(...)
  end,
})

function Maybe:new(value)
  local instance = {
    value = value,
  }

  setmetatable(instance, self)
  self.__index = self

  return instance
end

function Maybe:_then(func)
  if self.value then
    func(self.value)
  end

  return self
end

function Maybe:_else(func)
  if not self.value then
    func()

    return self
  end

  return self
end

return Maybe
