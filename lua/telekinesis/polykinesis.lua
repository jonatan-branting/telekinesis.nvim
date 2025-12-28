local Logger = require("telekinesis.lib.logger")
local Enumerable = require("telekinesis.lib.enumerable")

local Polykinesis = {}

function Polykinesis.instance()
  if not _G.polykinesis_instance then
    _G.polykinesis_instance = Polykinesis:new()
  end

  return _G.polykinesis_instance
end


function Polykinesis.logger()
  return Logger:new(
    {
      level = vim.env.POLYKINESIS_LOG_LEVEL or "error",
    }
  )
end

local logger = Polykinesis.logger()

function Polykinesis:new(opts)
  local instance = {
    config = opts,
    logger = Polykinesis.logger(),
    ns_id = vim.api.nvim_create_namespace("PolykinesisNamespace"),
    cursors = Enumerable:new({}),
    current_cursor = nil,
    type_buffer = "",
    is_replaying = false,
  }

  setmetatable(instance, self)
  self.__index = self

  local safestate_augroup = vim.api.nvim_create_augroup("BetterNSafeState", { clear = true })

  vim.on_key(
    function(_, typed)
      if typed == "" then
        return
      end

      if vim.fn.mode() == "c" then
        return
      end

      if instance.is_replaying then
        return
      end

      instance.type_buffer = instance.type_buffer .. typed

      if vim.fn.mode() == "i" then
        vim.api.nvim_create_autocmd("InsertLeave", {
          group = safestate_augroup,
          callback = function(_)
            local buffer = instance.type_buffer

            instance.type_buffer = ""
            instance.is_replaying = true

            instance.cursors:reverse():each(function(cursor)
              cursor:goto()

              vim.api.nvim_feedkeys(buffer, "mtx", false)
            end)

            instance.cursors:clear()
            instance.is_replaying = false
          end,
          once = true
        })
      else
        vim.api.nvim_create_autocmd("SafeState", {
          group = safestate_augroup,
          callback = function(_)
            if vim.fn.mode() == "i" then
              return
            end

            local buffer = instance.type_buffer

            instance.type_buffer = ""
            instance.is_replaying = true

            instance.cursors:each(function(cursor)
              cursor:goto()

              vim.api.nvim_feedkeys(buffer, "mtx", false)
            end)

            instance.cursors:clear()
            instance.is_replaying = false
          end,
          once = true
        })
      end
    end,
    instance.ns_id,
    {}
  )

  return instance
end

function Polykinesis:add_cursor(cursor)
  if self.is_replaying then
    logger:debug("Polykinesis:add_cursor() is_replaying, returning early")
    return
  end

  self.cursors:append(cursor)
end

function Polykinesis:add_cursors(cursors)
  for _, cursor in ipairs(cursors) do
    self:add_cursor(cursor)
  end
end

function Polykinesis:clear_buffer()
  self.type_buffer = ""
end

return Polykinesis
