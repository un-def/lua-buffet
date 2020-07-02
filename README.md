# lua-buffet

[![Luarocks](https://img.shields.io/luarocks/v/undef/lua-buffet?style=for-the-badge)](https://luarocks.org/modules/undef/lua-buffet)
[![OPM](https://img.shields.io/opm/v/un-def/lua-buffet?color=brightgreen&style=for-the-badge)](https://opm.openresty.org/package/un-def/lua-buffet/)
[![Build Status](https://img.shields.io/travis/un-def/lua-buffet?style=for-the-badge)](https://travis-ci.org/un-def/lua-buffet)
[![License](https://img.shields.io/github/license/un-def/lua-buffet?style=for-the-badge)][license]

Socket-like buffer objects for Lua

## Name

The word “buffet” is a portmanteau of “**buff**er” and “sock**et**”.

## Description

A _buffet_ is an object that has the same interface as socket objects in the popular Lua libraries [LuaSocket](http://w3.impa.br/~diego/software/luasocket/) and [Lua Nginx Module](https://github.com/openresty/lua-nginx-module) but doesn't do any real network communication. Instead the network stack the _buffet_ receives data from an arbitrary source. The data source can be a string, a table of strings or an iterator function producing strings.

The _buffet_ works in a streaming fashion. That is, the _buffet_ doesn't try to read and store internally the whole source data at once but reads as little as possible and only when necessary. That means that the _buffet_ can be efficiently used as a proxy for sources of unlimited amounts of data such as _real_ sockets or file I/O readers.

Another possible use is unit testing where the _buffet_ can be used as a mock object instead of the real socket object.

## Basic usage

```lua
local buffet = require('buffet')
local buffet_resty = require('buffet.resty')

-- Input data is a string.
-- Read data in chunks of 3 bytes.
local bf = buffet_resty.new('data string')
print(buffet.is_closed(bf))   -- false
repeat
    local data, err, partial = bf:receive(3)
    print(data, err, partial)
until err
print(buffet.is_closed(bf))   -- true

-- Input data is a table containing data chunks.
-- Read data line by line.
local bf = buffet_resty.new({'line 1\nline', ' 2\nli', 'ne 3\n'})
repeat
    local data, err, partial = bf:receive('*l')
    print(data, err, partial)
until err

-- Input data is a function producing data chunks.
-- Read data splitted by the specified pattern, up to 4 bytes at once.
local iterator = coroutine.wrap(function()
    coroutine.yield('first-==-se')
    coroutine.yield('cond-==')
    coroutine.yield('-thi')
    coroutine.yield('rd')
    coroutine.yield(nil, 'some error')
    coroutine.yield('unreachable')
end)
local bf = buffet_resty.new(iterator)
local reader = bf:receiveuntil('-==-')
print(buffet.get_iterator_error(bf))   -- nil
repeat
    local data, err, partial = reader(4)
    print(data, err, partial)
until err
print(buffet.get_iterator_error(bf))   -- some error
```

For more advanded usage see the [examples](https://github.com/un-def/lua-buffet/tree/master/examples) directory.

## Documentation

Documentation is available at https://undef.im/lua-buffet/.

## Changelog

For detailed changelog see [CHANGELOG.md](https://github.com/un-def/lua-buffet/blob/master/CHANGELOG.md).

## TODO

### OpenResty

#### `ngx.socket.tcp`

  * [x] constructor (`ngx.socket.tcp` ~ `buffet.resty.new`)
  * [x] `:connect` (noop)
  * [x] `:sslhandshake` (noop)
  * [x] `:send`
  * [x] `:receive`
    * [x] `:receive()`
    * [x] `:receive('*l')`
    * [x] `:receive('*a')`
    * [x] `:receive(size)`
  * [ ] `:receiveany`
  * [x] `:receiveuntil`
    * [x] `iterator()`
    * [x] `iterator(size)`
    * [x] `inclusive` option
  * [x] `:close`
  * [ ] `:settimeout`
  * [ ] `:settimeouts`
  * [ ] `:setoption`
  * [ ] `:setkeepalive`
  * [ ] `:getreusedtimes`

#### `ngx.socket.udp`

...

### LuaSocket

...

## License

The [MIT License][license].


[license]: https://github.com/un-def/lua-buffet/blob/master/LICENSE
