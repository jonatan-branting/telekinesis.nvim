rockspec_format = "3.0"
package = "telekenesis.nvim"
version = "scm-1"

dependencies = {
  "lua == 5.1",
}

test_dependencies = {
  "lua == 5.1",
  "tree-sitter-lua",
  "busted"
}

source = {
  url = "git://github.com/jonatan-branting/" .. package,
}

build = {
  type = "builtin",
  copy_directories = {
    "plugin",
    "parser",
    "doc"
  },
}

