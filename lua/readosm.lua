local ok, readosm_ffi = pcall(require, "readosm-ffi")

if not ok then
  error("Sorry, the PUC Lua interface to readosm is not implemented yet")
end

return readosm_ffi
