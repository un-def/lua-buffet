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
-- @tparam[opt] number|string size_or_pattern a size of data to read or a pattern:
--
--  * `'*a'` to read all data
--  * `'*l'` to read a line
--
-- If no parameter is specified, then it is assumed to be the pattern `'*l'`.
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

--- Read the data, at most max bytes.
--
-- The main difference between `receive(size)` and `receiveany(max)` is that the latter doesn't read the next chunk
-- from the input table/iterator if there is any data in the internal buffer left over from the previous calls.
--
-- See [Lua Nginx Module documentation](https://github.com/openresty/lua-nginx-module#tcpsockreceiveany).
-- @function receiveany
-- @tparam number|string max a max size of data to read
-- @treturn[1] string data
-- @treturn[2] nil
-- @treturn[2] string an error
-- @treturn[2] string an empty string (this is an undocumented quirk of the Lua Nginx Module)
-- @treturn[3] nil
-- @treturn[3] string an error
mt.receiveany = function(self, max)
    if self._closed then
        return nil, ERR_CLOSED
    end
    local err = "bad argument #2 to 'receiveany' (bad max argument)"
    local max_type = type(max)
    if max_type == 'string' then
        max = tonumber(max)
        if not max then
            return error(err, 0)
        end
    elseif max_type ~= 'number' then
        return error(err, 0)
    end
    max = math_floor(max)
    if max < 1 then
        return error(err, 0)
    end
    local chunk = _get_chunk(self)
    if not chunk then
        self:close()
        return nil, ERR_CLOSED, ''
    end
    if #chunk > max then
        _store_chunk(self, str_sub(chunk, max + 1))
        chunk = str_sub(chunk, 1, max)
    end
    return chunk
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
-- @tparam[opt] table options
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

local _get_table_len = function(tbl)
    local max_index = 0
    for key in next, tbl do
        if type(key) ~= 'number' or math_floor(key) ~= key or key < 1 then
            return nil, 'non-array table'
        end
        if key > max_index then
            max_index = key
        end
    end
    return max_index
end

local _flatten_send_data_table
_flatten_send_data_table = function(tbl, acc)
    if not acc then
        acc = {}
    end
    local len, err = _get_table_len(tbl)
    if err then
        return nil, err
    end
    for index = 1, len do
        local value = tbl[index]
        local value_type = type(value)
        if value_type == 'string' then
            table_insert(acc, value)
        elseif value_type == 'number' then
            table_insert(acc, tostring(value))
        elseif value_type == 'table' then
            -- Should we limit recursion depth or track seen tables to avoid
            -- errors due to recursive tables?
            local _, err = _flatten_send_data_table(value, acc)   -- luacheck: ignore 421
            if err then
                return nil, err
            end
        else
            return nil, 'bad data type ' .. value_type
        end
    end
    return acc
end

--- Send data.
--
-- Appends a string representation of the data to the internal send buffer. Use @{get_send_buffer} to access the buffer
-- or @{get_sent_data} to get the content of the buffer as a string.
--
-- The `data` parameter can be:
--
--  * a string
--  * an array-like table containing strings (possibly nested)
--  * a number, boolean or nil (will be converted to a string)
--
-- See [Lua Nginx Module documentation](https://github.com/openresty/lua-nginx-module#tcpsocksend).
-- @function send
-- @tparam string|table|number|boolean|nil data the data to send
-- @treturn[1] number number of bytes have been sent
-- @treturn[2] nil
-- @treturn[2] string an error
mt.send = function(self, data)
    if self._closed then
        return nil, ERR_CLOSED
    end
    local data_type = type(data)
    if data_type == 'string' then   -- luacheck: ignore 542
        -- pass
    elseif data_type == 'table' then
        local flat_tbl, err = _flatten_send_data_table(data)
        if not flat_tbl then
            return error(str_format("bad argument #2 to 'send' (%s found)", err), 0)
        end
        data = table_concat(flat_tbl)
    elseif data_type == 'number' or data_type == 'boolean' or data == nil then
        data = tostring(data)
    else
        return error(str_format(
            "bad argument #2 to 'send' (string, number, boolean, nil, or array table expected, got %s)", data_type), 0)
    end
    table_insert(self._send_buffer, data)
    return #data
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

--- Do SSL/TLS handshake.
--
-- This method is noop.
-- If the buffet is not closed, the method returns `true` (as if `false` was passed
-- as the `reused_session` argument).
-- Otherwise, the method returns `nil` and an error.
--
-- See [Lua Nginx Module documentation](https://github.com/openresty/lua-nginx-module#tcpsocksslhandshake).
-- @function sslhandshake
-- @tparam any ... not checked, not used
-- @treturn[1] boolean true
-- @treturn[2] nil
-- @treturn[2] string an error
mt.sslhandshake = function(self)
    if self._closed then
        return nil, ERR_CLOSED
    end
    return true
end

--- @section end

--- Create a new buffet object.
-- @tparam[opt] string|table|function data
-- input data, one of:
--
-- * a byte string
-- * an array-like table of byte strings (be aware that the object will use **the same** table, not a copy)
-- * an iterator function producing byte strings
--
-- If the parameter is omitted or `nil`, this is roughly equivalent to passing an empty string.
-- @treturn[1] buffet a buffet object
-- @treturn[2] nil
-- @treturn[2] string an error
_M.new = function(data)
    local iterator = nil
    local chunk = nil
    if data ~= nil then
        local data_type = type(data)
        if data_type == 'function' then
            iterator = data
        elseif data_type == 'table' then
            iterator = _get_table_iterator(data)
        elseif data_type == 'string' then
            if data ~= '' then
                chunk = data
            end
        else
            return nil, str_format('argument #1 must be string, table, or function, got: %s', data_type)
        end
    end
    return setmetatable({
        _closed = false,
        _iterator = iterator,
        _chunk = chunk,
        _send_buffer = {},
    }, mt)
end

return _M
