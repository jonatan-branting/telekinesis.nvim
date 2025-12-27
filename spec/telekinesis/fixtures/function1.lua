local foo = "bar"

local function hello(arg)
  print(foo, arg)
  print(foo, arg)
  print('Hello, world!', arg)
  print(foo, arg)
  print(foo, arg)
end

hello("test")
