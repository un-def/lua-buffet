# lua-buffet

[![Build Status](https://img.shields.io/travis/un-def/lua-buffet.svg?style=flat-square)](https://travis-ci.org/un-def/lua-buffet)

Socket-like buffer objects for Lua

## Name

The word “buffet” is a portmanteau of “**buff**er” and “sock**et**”.

## TODO

### OpenResty

#### `ngx.socket.tcp`

  * [x] constructor  (`ngx.socket.tcp` ~ `buffet.resty.new`)
  * [ ] `:connect`
  * [ ] `:sslhandshake`
  * [ ] `:send`
  * [ ] `:receive`
    * [ ] `:receive()`
    * [ ] `:receive('*l')`
    * [x] `:receive('*a')`
    * [x] `:receive(size)`
  * [ ] `:receiveany`
  * [ ] `:receiveuntil`
    * [x] `reader()`
    * [x] `reader(size)`
    * [ ] `inclusive` option
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
