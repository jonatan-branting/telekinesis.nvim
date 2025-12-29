local foo = "bar"

local hello = function(arg)
  print(foo, arg)
  print(foo, arg)
  print("Hello, world!", arg)
  print(foo, arg)
  print(foo, arg)
end

hello("test")
