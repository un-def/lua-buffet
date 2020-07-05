--- Common functions and constants.
-- @module buffet
local table_concat = table.concat

local _M = {
    --- A version of the library.
    _VERSION = '0.2.0',
    _DESCRIPTION = 'Socket-like buffer objects for Lua',
    _URL = 'https://github.com/un-def/lua-buffet',
    _LICENSE = 'MIT',
}

--- Check whether a buffet object is closed.
-- @tparam buffet bf the buffet object
-- @treturn boolean true if the buffet object is closed
_M.is_closed = function(bf)
    return bf._closed
end

--- Get an error returned by an iterator function (if present).
-- @tparam buffet bf the buffet object
-- @return[1] the error value
-- @treturn[2] nil
_M.get_iterator_error = function(bf)
    return bf._iterator_error
end

--- Get a send buffer.
--
-- The function returns a **reference** to the buffer table, not a copy.
-- @tparam buffet bf the buffet object
-- @treturn table the send buffer
_M.get_send_buffer = function(bf)
    return bf._send_buffer
end

--- Get the entire content of a send buffer as a string.
--
-- This function is a shortcut for `table.concat(get_send_buffer(bf))`.
-- @tparam buffet bf the buffet object
-- @treturn string the content of the send buffer
_M.get_sent_data = function(bf)
    return table_concat(bf._send_buffer)
end

return _M
