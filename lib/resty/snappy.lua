local ffi        = require "ffi"
local ffi_new    = ffi.new
local ffi_typeof = ffi.typeof
local ffi_cdef   = ffi.cdef
local ffi_load   = ffi.load
local ffi_str    = ffi.string
local C          = ffi.C
local tonumber   = tonumber

ffi_cdef[[
typedef enum {
  SNAPPY_OK = 0,
  SNAPPY_INVALID_INPUT = 1,
  SNAPPY_BUFFER_TOO_SMALL = 2
} snappy_status;
snappy_status snappy_compress(const char* input, size_t input_length, char* compressed, size_t* compressed_length);
snappy_status snappy_uncompress(const char* compressed, size_t compressed_length, char* uncompressed, size_t* uncompressed_length);
size_t snappy_max_compressed_length(size_t source_length);
snappy_status snappy_uncompressed_length(const char* compressed, size_t compressed_length, size_t* result);
snappy_status snappy_validate_compressed_buffer(const char* compressed, size_t compressed_length);
]]

local lib = ffi_load "snappy"
local char_t = ffi_typeof "char[?]"
local size_t = ffi_typeof "size_t[1]"
local snappy = {}

function snappy.compress(input)
    local il = #input
    local ml = snappy.max_compressed_length(il)
    local compressed = ffi_new(char_t, ml)
    local cl = ffi_new(size_t)
    cl[0] = tonumber(ml)
    local status = lib.snappy_compress(input, il, compressed, cl)
    local len = tonumber(cl[0])
    if (status == C.SNAPPY_OK) then
        return ffi_str(compressed, len), len
    else
        return nil, tonumber(status)
    end
end

function snappy.uncompress(compressed)
    local cl = #compressed
    local ul = ffi_new(size_t)
    local status = lib.snappy_uncompressed_length(compressed, cl, ul)
    if (status ~= C.SNAPPY_OK) then
        return nil, tonumber(status)
    end
    local uncompressed = ffi_new(char_t, tonumber(ul[0]))
    status = lib.snappy_uncompress(compressed, cl, uncompressed, ul)
    local len = tonumber(ul[0])
    if (status == C.SNAPPY_OK) then
        return ffi_str(uncompressed, len), len
    else
        return nil, tonumber(status)
    end
end

function snappy.max_compressed_length(source_length)
    return tonumber(lib.snappy_max_compressed_length(source_length))
end

function snappy.uncompressed_length(compressed)
    local result = ffi_new(size_t)
    local status = lib.snappy_uncompressed_length(compressed, #compressed, result)
    if (status == C.SNAPPY_OK) then
        return tonumber(result[0])
    else
        return nil
    end
end

function snappy.validate_compressed_buffer(compressed)
    local status = lib.snappy_validate_compressed_buffer(compressed, #compressed)
    return status == C.SNAPPY_OK
end

return snappy