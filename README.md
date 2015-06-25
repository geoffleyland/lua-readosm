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

You can ask readosm to only read certain types of elements with a second
argument to open.  For example `readosm.open("map.pbf", "ways")` will read
only ways, and `ways,relations` will read only ways and relations.
Only reading the parts of the file you need can make things *much* faster.


## 3. Differences from readosm

readosm uses `READOSM_UNDEFINED` (-1234567890) when the uid field is undefined.
lua-readosm returns -1, which matches what is in the PBF file (if you're
reading PBF).
I'm not sure that deviating here is a good idea, so if you care about uids
(I don't for what I do), it would probably be best to check for uid < 0.

lua-readosm returns a string for the `member_type` field of a relation,
rather than `READOSM_MEMBER_{NODE,WAY,RELATION}`.
It just seems more Lua-y to do that.


## 4. Here be dragons!

OSM ids are *nearly* but not actually unique across nodes, ways and relations.
It's possible to have a node and a way with the same id.
I did not realise this until recently
(since collisions are rare, but do happen)
and so have been working on slightly wrong data for a couple of years.


## 5. Requirements

LuaJIT for now.
If there's interest, I could write a "classic" Lua binding,
but 6 months in, it has two stars and no forks on github,
so I'm not feeling a lot of demand.

Kind-of obviously, you need to install readosm, and the rock won't do
that for you.


## 6. Issues

+ Because readosm uses callbacks and because it's not possible to yield
  across C boundaries, lua-readosm uses a parse function with a callback,
  rather than the more familiar `for object in f:lines() do` iterator-type
  interface.  I'm afraid implementing an interface like this would probably
  require a ground-up rewrite of both the XML and PBF parsers.


## 7. Wishlist

+ Tests would be nice.
+ So would better documentation.


## 8. Alternatives

+ There are plenty of XML parsers available.
+ PBF is based on [Protocol Buffers](https://code.google.com/p/protobuf/)
  and there's a Lua library for reading Protocol Buffers
  [here](https://github.com/Neopallium/lua-pb).
+ You can download OSM data in other formats from a variety of providers,
  for example, [here](http://www.geofabrik.de/data/shapefiles.html).
+ I wrote another PBF (but not XML) OSM reader as part of
  [lua-osm-tools](https://github.com/geoffleyland/lua-osm-tools)
  in the hopes that a "pure"(ish) Lua implementation would give LuaJIT more
  chances for optimisation.
  It does, so they work out about the same speed :-).

