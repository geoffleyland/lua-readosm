local ok, readosm_ffi = pcall(require, "readosm-ffi")

if not ok then
  error("Couldn't load readosm_ffi: "..readosm_ffi)
end

return readosm_ffi
