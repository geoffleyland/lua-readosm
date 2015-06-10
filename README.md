# Lua-readosm - Read OpenStreetMaps XML and PBF files

## 1. What?

Lua-readosm is a binding to
[readosm](https://www.gaia-gis.it/fossil/readosm/index) for reading
[OpenStreetMap](http://www.openstreetmap.org) (OSM) data in XML and
[PBF](http://wiki.openstreetmap.org/wiki/PBF_Format) formats.

As such it tries to follow the readosm API fairly closely, except that
instead of the user supplying three callbacks to `parse` as in the C API,
one for each data type,
only one callback needs to be supplied, which is passed an argument
indicating the type of the data read.

At the moment, I'm afraid there's only a LuaJIT FFI-style binding implemented,
if it turns out there's any interest in this, I'll try to find some time to
put together a "classic" binding.


## 2. How?

    local readosm = require("readosm")
    local f = readosm.open("map.pbf")
    f:parse(function(type, object)
        print(type)
        for k, v in pairs(object.tags) do print(k, v) end
      end)
    f:close()

The field names in the data object are the same as for readosm's C API,
however, the fields have been converted to appropriate Lua types.

In the case of the FFI binding (ie, the only one) the objects passed are
cdata structs with metatables.  The raw fields for, for example, the tags
are available with an underscore prefixed to the name
(that is, `object._tags` is a `readosm_tag *` and object.tags in a Lua table).

The Lua tables derived from the underlying FFI data are only created on demand,
so doing nothing while parsing an entire file creates no garbage.


## 3. Requirements

LuaJIT for now.


## 4. Issues

+ Because readosm uses callbacks and because it's not possible to yield
  across C boundaries, lua-readosm uses a parse function with a callback,
  rather than the more familiar `for object in f:lines() do` iterator-type
  interface.  I'm afraid implementing an interface like this would probably
  require a ground-up rewrite of both the XML and PBF parsers.


## 5. Wishlist

+ Tests would be nice.
+ So would better documentation.


## 6. Alternatives

+ There are plenty of XML parsers available.
+ PBF is based on [Protocol Buffers](https://code.google.com/p/protobuf/)
  and there's a Lua library for reading Protocol Buffers
  [here](https://github.com/Neopallium/lua-pb).
+ You can download OSM data in other formats from a variety of providers,
  for example, [here](http://www.geofabrik.de/data/shapefiles.html).
