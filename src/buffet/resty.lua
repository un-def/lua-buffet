--- OpenResty flavor of buffet objects.
-- @module buffet.resty
local error = error
local select = select
local setmetatable = setmetatable
local tonumber = tonumber
local tostring = tostring
local type = type

local math_floor = math.floor

local str_find = string.find
local str_format = string.format
local str_gsub = string.gsub
local str_sub = string.sub

local table_concat = table.concat
local table_insert = table.insert

local ERR_CLOSED = 'closed'
local ERR_RECEIVE_BAD_PATTERN = "bad argument #2 to 'receive' (bad pattern argument)"

local _M = {}

--- OpenResty buffet type
-- @type buffet

local mt = {}
mt.__index = mt

local _get_table_iterator = function(tbl)
    local index = 0
    return function()
        index = index + 1
        return tbl[index]
    end
end

local _get_chunk = function(bf)
    local chunk = bf._chunk
    if chunk then
        bf._chunk = nil
        return chunk
    end
    local iterator = bf._iterator
    if not iterator then
        return nil
    end
    while true do
        local chunk, err = iterator()   -- luacheck: ignore 421
        if not chunk then
            if err then
                bf._iterator_error = err
            end
            -- Here we just remove the reference to the iterator to prevent
            -- any further calls. It's easier than managing an additional
            -- attribute like `_iterator_is_done`.
            bf._iterator = nil
            return nil
        elseif chunk ~= '' then
            return chunk
        end
    end
end

local _store_chunk = function(bf, chunk)
    if bf._chunk then
        return error('buffet already has a chunk', 0)
    end
    if chunk == '' then
        return
    end
    bf._chunk = chunk
end

local _remove_cr = function(str)
    str = str_gsub(str, '\r', '')
    return str
end

local _receive_line = function(bf)
    local buffer = {}
    while true do
        local chunk = _get_chunk(bf)
        if not chunk then
            bf:close()
            return nil, ERR_CLOSED, _remove_cr(table_concat(buffer))
        end
        local lf_at = str_find(chunk, '\n', 1, true)
        if lf_at then
            table_insert(buffer, str_sub(chunk, 1, lf_at - 1))
            _store_chunk(bf, str_sub(chunk, lf_at + 1))
            return _remove_cr(table_concat(buffer))
        end
        table_insert(buffer, chunk)
    end
end

local _receive_all = function(bf)
    local buffer = {}
    while true do
        local chunk = _get_chunk(bf)
        if not chunk then
            break
        end
        table_insert(buffer, chunk)
    end
    return table_concat(buffer)
end

local _receive_size = function(bf, size)
    size = math_floor(size)
    if size < 0 then
        return error(ERR_RECEIVE_BAD_PATTERN, 0)
    elseif size == 0 then
        return ''
    end
    local have_bytes = 0
    local buffer = {}
    while true do
        local chunk = _get_chunk(bf)
        if not chunk then
            bf:close()
            return nil, ERR_CLOSED, table_concat(buffer)
        end
        have_bytes = have_bytes + #chunk
        if have_bytes == size then
            table_insert(buffer, chunk)
            return table_concat(buffer)
        elseif have_bytes > size then
            _store_chunk(bf, str_sub(chunk, size - have_bytes))
            table_insert(buffer, str_sub(chunk, 1, size - have_bytes - 1))
            return table_concat(buffer)
        end
        table_insert(buffer, chunk)
    end
end

--- Read the data according to the reading pattern or size.
--
-- See [Lua Nginx Module documentation](https://github.com/openresty/lua-nginx-module#tcpsockreceive).
-- @function receive
-- @tparam[1] number|string size_or_pattern a size of data to read or a pattern:
--
--  * `'*a'` to read all data
--  * `'*l'` to read a line
-- @treturn[1] string data
-- @treturn[2] nil
-- @treturn[2] string an error
-- @treturn[2] string partial data
-- @treturn[3] nil
-- @treturn[3] string an error
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
                return error(ERR_RECEIVE_BAD_PATTERN, 0)
            end
            return _receive_size(self, pattern)
        end
    elseif pattern_type == 'number' then
        return _receive_size(self, pattern)
    end
    return error(ERR_RECEIVE_BAD_PATTERN, 0)
end

local _find_pattern = function(str, pattern, search_start, search_stop)
    if search_stop and #str > search_stop then
        str = str_sub(str, 1, search_stop)
    end
    return str_find(str, pattern, search_start, true)
end

local _receive_until = function(bf, pattern, inclusive, size)
    local pattern_len = #pattern
    local search_stop = nil
    if size then
        search_stop = size + pattern_len - 1
    end
    local buffer = ''
    while true do
        local chunk = _get_chunk(bf)
        if not chunk then
            if size and #buffer > size then
                _store_chunk(bf, str_sub(buffer, size + 1))
                return str_sub(buffer, 1, size), false, false
            end
            return buffer, true, false
        end
        local search_start = #buffer - pattern_len
        if search_start < 1 then
            search_start = 1
        end
        buffer = buffer .. chunk
        local pattern_start, pattern_stop = _find_pattern(buffer, pattern, search_start, search_stop)
        if pattern_start then
            if #buffer > pattern_stop then
                _store_chunk(bf, str_sub(buffer, pattern_stop + 1))
            end
            local stop
            if inclusive then
                stop = pattern_stop
            else
                stop = pattern_start - 1
            end
            return str_sub(buffer, 1, stop), false, true
        end
        if search_stop and #buffer > search_stop then
            _store_chunk(bf, str_sub(buffer, size + 1))
            return str_sub(buffer, 1, size), false, false
        end
    end
end

local _normalize_receivenutil_iterator_size_arg = function(...)
    if select('#', ...) == 0 then
        return nil
    end
    local size = ...
    local size_type = type(size)
    if size_type == 'string' then
        size = tonumber(size)
        if size then
            size_type = 'number'
        end
    end
    if size_type ~= 'number' then
        return error(str_format(
            'bad argument #1 to iterator (number expected, got %s)', size_type), 0)
    end
    if size <= 0 then
        return nil
    end
    return math_floor(size)
end

local _get_receivenutil_iterator = function(bf, pattern, inclusive)
    local emit_nil_on_next_call = false
    return function(...)
        if bf._closed then
            return nil, ERR_CLOSED
        end
        if emit_nil_on_next_call then
            emit_nil_on_next_call = false
            return nil, nil, nil
        end
        local size = _normalize_receivenutil_iterator_size_arg(...)
        local data, done, found = _receive_until(bf, pattern, inclusive, size)
        if size and found then
            emit_nil_on_next_call = true
        end
        if not done then
            return data
        end
        bf:close()
        return nil, ERR_CLOSED, data
    end
end

--- Get an iterator to read the data until the specified pattern.
--
-- See [Lua Nginx Module documentation](https://github.com/openresty/lua-nginx-module#tcpsockreceiveuntil).
-- @function receiveuntil
-- @tparam string pattern
-- @tparam ?table options
-- @treturn[1] function an iterator
-- @treturn[2] nil
-- @treturn[2] string an error
mt.receiveuntil = function(self, ...)
    local args_count = select('#', ...)
    local options = nil
    local pattern
    if args_count == 1 then
        pattern = ...
    elseif args_count == 2 then
        pattern, options = ...
        if type(options) ~= 'table' then
            return error(str_format(
                "bad argument #3 to 'receiveuntil' (table expected, got %s)", type(options)), 0)
        end
    else
        return error(str_format(
            'expecting 2 or 3 arguments (including the object), but got %d', args_count + 1), 0)
    end
    local inclusive = false
    if options then
        inclusive = options.inclusive
        if type(inclusive) ~= 'boolean' then
            return error(str_format('bad "inclusive" option value type: %s', type(inclusive)), 0)
        end
    end
    local pattern_type = type(pattern)
    if pattern_type == 'number' then
        pattern = tostring(pattern)
    elseif pattern_type ~= 'string' then
        return error(str_format(
            "bad argument #2 to 'receiveuntil' (string expected, got %s)", pattern_type), 0)
    end
    if pattern == '' then
        return nil, 'pattern is empty'
    end
    return _get_receivenutil_iterator(self, pattern, inclusive)
end

--- Close the buffet.
--
-- Marks the object as closed. Removes the reference to the input data.
--
-- See [Lua Nginx Module documentation](https://github.com/openresty/lua-nginx-module#tcpsockclose).
-- @function close
-- @treturn[1] number 1 in case of success
-- @treturn[2] nil
-- @treturn[2] string an error
mt.close = function(self)
    if self._closed then
        return nil, ERR_CLOSED
    end
    self._closed = true
    self._iterator = nil
    self._chunk = nil
    return 1
end

--- Connect the buffet.
--
-- This method is _almost_ noop, it only marks the object as “connected” (not closed).
-- The return status is always success (1).
--
-- See [Lua Nginx Module documentation](https://github.com/openresty/lua-nginx-module#tcpsockconnect).
-- @function connect
-- @tparam any ... not checked, not used
-- @treturn number 1
mt.connect = function(self)
    self._closed = false
    return 1
end

--- @section end

--- Create a new buffet object.
-- @tparam[1] string|table|function data
-- input data, one of:
--
-- * a byte string
-- * an array-like table of byte strings (be aware that the object will use **the same** table, not a copy)
-- * an iterator function producing byte strings
-- @treturn[1] buffet a buffet object
-- @treturn[2] nil
-- @treturn[2] string an error
_M.new = function(data)
    local iterator = nil
    local chunk = nil
    local data_type = type(data)
    if data_type == 'function' then
        iterator = data
    elseif data_type == 'table' then
        iterator = _get_table_iterator(data)
    elseif data_type == 'string' then
        chunk = data
    else
        return nil, str_format('argument #1 must be string, table, or function, got: %s', data_type)
    end
    return setmetatable({
        _closed = false,
        _iterator = iterator,
        _chunk = chunk,
    }, mt)
end

return _M
