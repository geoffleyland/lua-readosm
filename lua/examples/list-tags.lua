local ro = require"readosm"

local f = ro.open(arg[1])

local tag_map = {}

f:parse(function(type, o)
    for k, v in pairs(o.tags) do
      tag_map[k] = tag_map[k] or {}
      tag_map[k][1] = (tag_map[k][1] or 0) + 1
      tag_map[k][v] = (tag_map[k][v] or 0) + 1
    end
  end)

f:close()

local tags = {}
for k, v in pairs(tag_map) do
  local values = {}
  for k2, count in pairs(v) do
    if k2 ~= 1 then
      values[#values+1] = { value = k2, count = count }
    end
  end
  table.sort(values, function(a, b) return a.count > b.count end)
  tags[#tags+1] = { key = k, values = values, count = v[1] }
end

table.sort(tags, function(a, b) return a.count > b.count end)

for _, k in ipairs(tags) do
  io.stdout:write(("%-50s\t%8d\n"):
    format(k.key, k.count))
  for i = 1, math.min(100, #k.values) do
   local v = k.values[i]
    io.stdout:write(("  %3d: %-50s\t%8d\t%5.3f\n"):
      format(i, v.value, v.count, v.count / k.count))
  end
end
