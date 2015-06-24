--- LuaJIT FFI-based binding to readosm.
--  This uses the same open, parse, close interface as the "vanilla" binding.
--  However the objects returned to the parse callback are the C objects
--  returned by readosm's parse, and readosm reuses the same memory for
--  every callback of the same type, so you can't hold on to the object
--  between invocations of the callback.
--  If you want to store the data, copy it.
--
--  An index metamethod is used to provide Lua-like interfaces to some of
--  the C struct fields.  The actual fields in the struct are prefixed with
--  and underscore, and the vanilla fieldnames are implemented by __index.
--  This means the conversions are done on demand, and not performed if the
--  fields aren't accessed.  In all cases the original field in the C struct
--  can be accesed by the field name prefixed with an underscore.
--
--  - `tag`'s `key` and `value`, `node`, `way` and `relation`'s `user` and
--    `member`'s `role` use the metamethod to convert the underlying `char*`
--    to a Lua string.
--  - `node`, `way` and `relation`'s `timestamp` are converted to a Lua
--    [time](http://www.lua.org/manual/5.2/manual.html#pdf-os.time).
--  - `node`, `way` and `relation`'s `tags` are converted to a Lua table.
--    as noted above, this conversion is done on the fly.  The results of
--    the conversion are cached, so accessing `tags` on the same callback
--    argument more than once shouldn't be too costly.
--  - `way`'s `node_refs` are converted to a Lua table in a similar fashion.
--  - `relations`'s `member`s are also converted to a Lua table.

local ffi = require"ffi"
local cd = require"readosm.cdefs"

local RO = ffi.load"readosm"

local osmfile = {}
osmfile.__index = osmfile


local no_config =
{
  nodes         = true,
  ways          = true,
  relations     = true,
}


--- Open an OSM file
--  The file must have an .osm (XML) or .pbf extension
--  @return file object
local function open(filename, what)
  local h = ffi.cast("const void**", ffi.new("void*[1]"))
  local result = RO.readosm_open(filename, h)
  if result == cd.constants.READOSM_OK then
    what = what and what:lower()
    config = not what and no_config or
    {
      nodes       = what:find("node"),
      ways        = what:find("way"),
      relations   = what:find("relation"),
    }

    return setmetatable({ handle=h[0], filename=filename, config=config}, osmfile)
  else
    error(("osmread error reading '%s': %s"):
          format(filename, cd.error_map[result]))
  end
end


local tag_cache = setmetatable({}, { __mode = "kv"})
local node_cache = setmetatable({}, { __mode = "kv"})
local member_cache = setmetatable({}, { __mode = "kv"})

local fields =
{
  key = function(n) return ffi.string(n._key) end,
  value = function(n) return ffi.string(n._value) end,
  user = function(n) return n._user == nil and "" or ffi.string(n._user) end,
  role = function(n) return ffi.string(n._role) end,
  member_type = function(n) return cd.member_map(n._member_type) end,
  timestamp = function(n)
      return ffi.string(n._timestamp)
    end,
  tags = function(n)
      local tc = tag_cache[n.id]
      if tc then return tc end
      local tags = {}
      for i = 0, n.tag_count-1 do
        tags[n._tags[i].key] = n._tags[i].value
      end
      tag_cache[n.id] = tags
      return tags
    end,
  node_refs = function(n)
      local nc = node_cache[n.id]
      if nc then return nc end
      local nodes = {}
      for i = 0, n.node_ref_count-1 do
        nodes[i+1] = n._node_refs[i]
      end
      node_cache[n.id] = nodes
      return nodes
    end,
  member_refs = function(n)
      local mc = member_cache[n.id]
      if mc then return mc end
      local members = {}
      for i = 0, n.member_count-1 do
        members[i+1] = n._members[i]
      end
      node_cache[n.id] = members
      return members
    end,
}

local function node_index(n, k)
  local f = fields[k]
  return f and f(n)
end

local node_metatable = { __index = node_index }

ffi.metatype("readosm_tag",      node_metatable)
ffi.metatype("readosm_node",     node_metatable)
ffi.metatype("readosm_way",      node_metatable)
ffi.metatype("readosm_relation", node_metatable)
ffi.metatype("readosm_member",   node_metatable)


local OK, ABORT = cd.constants.READOSM_OK, cd.constants.READOSM_ABORT

local function parse(h, filename, config, cb)

  local function wrap(r) return r == false and ABORT or OK end

  local function node_cb(_, o) return wrap(cb("node",      o)) end
  local function way_cb (_, o) return wrap(cb("way",       o)) end
  local function rel_cb (_, o) return wrap(cb("relation",  o)) end

  local ok = RO.readosm_parse(h, ffi.cast("void*", 0),
    config.nodes and node_cb or nil,
    config.ways and way_cb or nil,
    config.relations and rel_cb or nil)
--  local ok = RO.readosm_parse(h, ffi.cast("void*", 0), ffi.cast("readosm_node_callback", 0), ffi.cast("readosm_way_callback", 0), ffi.cast("readosm_relation_callback", 0))

  if ok ~= OK then
    error(("osmread error parsing '%s': %s"):
          format(filename, cd.error_map[result]))
  end
end


function osmfile:parse(callback)
  return parse(self.handle, self.filename, self.config, callback)
end


--[[
-- Unfortunately, we can'd get an iterator to work, because you can't yield
-- from inside a callback.
function osmfile:lines()
  return coroutine.wrap(
    function()
        parse(self.handle, self.filename,
          function(type, o) coroutine.yield(type, o) end)
      end)
end
--]]


local function close(h, filename)
  local result = RO.readosm_close(h)
  if result ~= cd.constants.READOSM_OK then
    error(("osmread error parsing '%s': %s"):
          format(filename, cd.error_map[result]))
  end
end

function osmfile:close()
  return close(self.handle, self.filename)
end


return { open = open }

