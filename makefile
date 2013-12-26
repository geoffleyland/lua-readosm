LUA= $(shell echo `which lua`)
LUA_BINDIR= $(shell echo `dirname $(LUA)`)
LUA_PREFIX= $(shell echo `dirname $(LUA_BINDIR)`)
LUA_VERSION = $(shell echo `lua -v 2>&1 | cut -d " " -f 2 | cut -b 1-3`)
LUA_SHAREDIR=$(LUA_PREFIX)/share/lua/$(LUA_VERSION)

default:
	@echo "Nothing to build.  Try 'make install'."

install:
	cp lua/readosm.lua $(LUA_SHAREDIR)
	cp lua/readosm-ffi.lua $(LUA_SHAREDIR)
	mkdir $(LUA_SHAREDIR)/readosm
	cp lua/readosm/cdefs.lua $(LUA_SHAREDIR)/readosm
