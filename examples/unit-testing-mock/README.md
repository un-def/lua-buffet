# Unit Testing: Socket Mock Objects

This is an example of using the `lua-buffet` library to test code that expects real socket objects by mocking them.

Here we test some library named `somelib` containing a single function `read`. The function accepts a socket object and an optional transformer function, connects to a remote server, reads the response line-by-line until the connection is closed or an error occurs, and returns a table containing lines optionally transformed using the passed function. If an error ocurred, the function returns the second value describing the error. If an error occured during the connection phase, the first returned value will be `nil`.

The tests are writen using the [busted](https://olivinelabs.com/busted/) unit testing framework. Use `make test` to run them.
