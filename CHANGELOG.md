# Changelog

## 0.2.0 (unreleased)

### Features:

  * [buffet.resty] The Lua Nginx Module/OpenResty flavor of the socket interface is now fully implemented:
    - Implement `send` method
    - Implement `receiveany` method
    - Implement noop/dummy methods:
      + `connect`
      + `sslhandshake`
  * [buffet] Add `get_send_buffer` and `get_sent_data` functions for accessing the send buffer.

### Improvements:

  * [buffet.resty] Improve compatibility of the Lua Nginx Module/OpenResty flavor:
    - `receive('*a')` does not close the buffet
    - `receive('*a')` returns an error if the buffet is closed
    - `receiveuntil(pattern)` does not check whether the buffet is closed
  * [buffet.resty] Make the `data` parameter of the constructor optional

### Internal Changes

  * [buffet.resty] Do not use the `close` method internally

## 0.1.0

The first release.

The Lua Nginx Module/OpenResty flavor of the socket interface is partially implemented. The following methods are implemented:
  * `receive`
  * `receiveuntil`
  * `close`
