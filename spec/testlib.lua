local _M = {}

_M.nargs = function(...)
    return select('#', ...), ...
end

if ... then
    return _M
else
    _G['testlib'] = _M
    for k, v in pairs(_M) do
        _G[k] = v
    end
end
