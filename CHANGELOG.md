# Changelog

## 0.2.0 (unreleased)

### Changed:

  * Improve compatibility of the Lua Nginx Module/OpenResty flavor:
    - `receive('*a')` does not close the buffet
    - `receive('*a')` returns an error if the buffet is closed
    - `receiveuntil(pattern)` does not check whether the buffet is closed

## 0.1.0

The first release.

The Lua Nginx Module/OpenResty flavor of the socket interface is partially implemented. The following methods are implemented:
  * `receive`
  * `receiveuntil`
  * `close`
