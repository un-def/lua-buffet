local str_format = string.format
local str_sub = string.sub
local table_concat = table.concat
local table_insert = table.insert
local math_floor = math.floor

local ERR_CLOSED = 'closed'
local ERR_NOT_IMPL = 'not implemented'
local ERR_BAD_PATTERN = "bad argument #2 to 'receive' (bad pattern argument)"

local _M = {
    _VERSION = '0.1.0.dev0',
}

local mt = {}
mt.__index = mt

local _get_table_reader = function(tbl)
    local index = 0
    return function()
        index = index + 1
        return tbl[index]
    end
end

local _get_next_chunk = function(self)
    local chunk, err = self._iterator()
    if err then
        self._iterator_error = err
    end
    return chunk
end

local _receive_line = function(_)
    return nil, ERR_NOT_IMPL
end

local _receive_all = function(_)
    return nil, ERR_NOT_IMPL
end

local _receive_size = function(self, size)
    size = math_floor(size)
    if size < 0 then
        return nil, ERR_BAD_PATTERN
    end
    if size == 0 then
        return ''
    end
    local have_bytes = 0
    local chunk = self._chunk
    local chunk_remainder = nil
    local chunk_len
    -- maybe we already have enough bytes in current chunk
    if chunk then
        chunk_len = #chunk
        local last_index = self._last_index
        local new_last_index = last_index + size
        if new_last_index < chunk_len then
            self._last_index = new_last_index
            return str_sub(chunk, last_index + 1, new_last_index)
        elseif new_last_index == chunk_len then
            self._chunk = nil
            return str_sub(chunk, last_index + 1)
        else
            self._chunk = nil
            chunk_remainder = str_sub(chunk, last_index + 1)
            have_bytes = #chunk_remainder
        end
    end
    -- buffet constructed from string has no iterator
    if not self._iterator then
        self:close()
        return nil, ERR_CLOSED, chunk_remainder or ''
    end
    -- we don't have enough bytes, going to iterate
    local buffer
    if chunk_remainder then
        buffer = {chunk_remainder}
    else
        buffer = {}
    end
    while true do
        chunk = _get_next_chunk(self)
        if not chunk then
            self:close()
            return nil, ERR_CLOSED, table_concat(buffer)
        end
        chunk_len = #chunk
        if chunk_len then
            have_bytes = have_bytes + chunk_len
            if have_bytes == size then
                table_insert(buffer, chunk)
                return table_concat(buffer)
            elseif have_bytes > size then
                self._chunk = chunk
                local last_index = chunk_len - have_bytes + size
                self._last_index = last_index
                table_insert(buffer, str_sub(chunk, 1, last_index))
                return table_concat(buffer)
            end
        end
        table_insert(buffer, chunk)
    end
end

_M.new = function(bytes)
    local iterator = nil
    local chunk = nil
    local bytes_type = type(bytes)
    if bytes_type == 'function' then
        iterator = bytes
    elseif bytes_type == 'table' then
        iterator = _get_table_reader(bytes)
    elseif bytes_type == 'string' then
        chunk = bytes
    else
        return nil, str_format('argument #1 must be function, got: %s', bytes_type)
    end
    return setmetatable({
        _closed = false,
        _iterator = iterator,
        _chunk = chunk,
        _last_index = 0,
    }, mt)
end

mt.close = function(self)
    if self._closed then
        return nil, ERR_CLOSED
    end
    self._closed = true
    self._iterator = nil
    self._chunk = nil
    return 1
end

mt.receive = function(self, ...)
    if self._closed then
        return nil, ERR_CLOSED
    end
    if select('#', ...) == 0 then
        return _receive_line(self)
    end
    local pattern = ...
    local pattern_type = type(pattern)
    if pattern_type == 'string' then
        if pattern == '*l' then
            return _receive_line(self)
        elseif pattern == '*a' then
            return _receive_all(self)
        else
            pattern = tonumber(pattern)
            if not pattern then
                return nil, ERR_BAD_PATTERN
            end
            return _receive_size(self, pattern)
        end
    elseif pattern_type == 'number' then
        return _receive_size(self, pattern)
    end
    return nil, ERR_BAD_PATTERN
end

return _M
