# lua-buffet

[![Luarocks](https://img.shields.io/luarocks/v/undef/lua-buffet?style=for-the-badge)](https://luarocks.org/modules/undef/lua-buffet)
[![Build Status](https://img.shields.io/travis/un-def/lua-buffet?style=for-the-badge)](https://travis-ci.org/un-def/lua-buffet)
[![License](https://img.shields.io/github/license/un-def/lua-buffet?style=for-the-badge)][license]

Socket-like buffer objects for Lua

## Name

The word “buffet” is a portmanteau of “**buff**er” and “sock**et**”.

## TODO

### OpenResty

#### `ngx.socket.tcp`

  * [x] constructor (`ngx.socket.tcp` ~ `buffet.resty.new`)
  * [ ] `:connect`
  * [ ] `:sslhandshake`
  * [ ] `:send`
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
