local upload = require('resty.upload')
local http = require('resty.http')
local buffet = require('buffet.resty')
local cjson = require('cjson')

local get_header = function(headers, name)
    local header = headers[name]
    if not header then
        return nil
    end
    if type(header) == 'table' then
        return header[1]
    end
    return header
end

local get_query_arg = function(query_args, name, cast)
    local value = query_args[name]
    if type(value) == 'table' then
        value = value[1]
    end
    if not value then
        return nil
    end
    if cast then
        value = cast(value)
    end
    return value
end

local bad_request = function(sock)
    sock:send('HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n')
    ngx.exit(ngx.ERROR)
end

local handler = function()
    -- get transfer-encoding header value (used only in logs)
    local headers = ngx.req.get_headers()
    local transfer_encoding = get_header(headers, 'transfer-encoding')
    local chunked = transfer_encoding == 'chunked'
    ngx.log(ngx.INFO, 'chunked transfer-encoding: ', chunked)
    -- get chunk size from query string (`/upload?chunk-size=NN`)
    local chunk_size = get_query_arg(ngx.req.get_uri_args(), 'chunk-size', tonumber)
    if not chunk_size or chunk_size < 1 then
        chunk_size = 8
    end
    ngx.log(ngx.INFO, 'chunk size: ' , chunk_size)
    -- get raw request socket
    local sock, err = ngx.req.socket(true)
    if not sock then
        ngx.log(ngx.ERR, 'socket error: ', err)
        return bad_request(sock)
    end
    -- get body reader iterator
    local iterator = http.get_client_body_reader(nil, chunk_size, sock)
    -- wrap it in buffet socket-like object
    local bf = buffet.new(iterator)
    -- create form object
    local form, err = upload:new(chunk_size, nil, bf)   -- luacheck: ignore 411
    if not form then
        ngx.log(ngx.ERR, 'form constructor error: ', err)
        return bad_request(sock)
    end
    -- iterate the form
    local lines = {}
    while true do
        local typ, res, err = form:read()   -- luacheck: ignore 421
        if not typ then
            ngx.log(ngx.ERR, 'form read error: ', err)
            break
        end
        table.insert(lines, cjson.encode({typ, res}))
        if typ == 'eof' then
            break
        end
    end
    -- write http response
    table.insert(lines, '')
    local body = table.concat(lines, '\n')
    sock:send(string.format(
        'HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: %d\r\n\r\n%s',
        #body, body
    ))
end

return {
    handler = handler,
}
