local _M = {
    _VERSION = '0.1.0.dev0',
    _DESCRIPTION = 'Socket-like buffer objects for Lua',
    _URL = 'https://github.com/un-def/lua-buffet',
    _LICENSE = 'MIT',
}

_M.is_closed = function(bf)
    return bf._closed
end

_M.get_iterator_error = function(bf)
    return bf._iterator_error
end

return _M
