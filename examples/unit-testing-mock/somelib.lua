local _M = {}

_M.HOST = 'example.com'
_M.PORT = 12345

_M.read = function(sock, fn)
    local ok, err = sock:connect(_M.HOST, _M.PORT)
    if not ok then
        return nil, 'connection error: ' .. err
    end
    local lines = {}
    while true do
        local data, err, partial = sock:receive('*l')   -- luacheck: ignore 421
        if partial and #partial > 0 then
            data = partial
        end
        if data then
            if fn then
                data = fn(data)
            end
            table.insert(lines, data)
        end
        if err == 'closed' then
            return lines
        elseif err then
            return lines, 'receive error: ' .. err
        end
    end
end

return _M
