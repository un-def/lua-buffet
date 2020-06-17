--- Common functions and constants.
-- @module buffet
local _M = {
    --- A version of the library.
    _VERSION = '0.1.0',
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

return _M
