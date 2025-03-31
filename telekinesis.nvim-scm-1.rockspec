rockspec_format = "3.0"
package = "telekinesis.nvim"
version = "scm-1"

dependencies = {
  "lua == 5.1",
}

test_dependencies = {
  "lua == 5.1",
  "tree-sitter-lua",
  "busted",
  "nlua"
}

source = {
  url = "git://github.com/jonatan-branting/" .. package,
}

build = {
  type = "builtin",
}

