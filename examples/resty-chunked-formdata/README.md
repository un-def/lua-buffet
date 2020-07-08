# OpenResty: processing `Transfer-Encoding: chunked` + `Content-Type: multipart/form-data`

This is an example of how to process a `multipart/form-data` form _in a streaming fashion_ when a request body is encoded with `chunked` transfer encoding.

Here we use [`lua-resty-http`](https://github.com/ledgetech/lua-resty-http) to decode `chunked` encoding, [`lua-resty-upload`](https://github.com/openresty/lua-resty-upload)<sup>†</sup> to process a form, and `lua-buffet` to glue them together.

---

<sup>†</sup> Currently we use our fork of the `lua-resty-upload` library because the original library doesn't allow to use an arbitrary socket object.

## How it works

First we [create](https://github.com/openresty/lua-nginx-module#ngxreqsocket) a _raw_ cosocket object to read a body of the request. We have to use the _raw_ mode because `ngx.req.socket()` returns an error if the body is `chunked`–encoded (the error says `chunked request bodies not supported yet`). It would be great if we could read raw `chunked` data in the non-_raw_ mode (we decode `chunked` encoding by ourselves anyway), but it doesn't work that way.

Then we pass the socket object to the [`get_client_body_reader`](https://github.com/ledgetech/lua-resty-http#get_client_body_reader) utility. It returns a regular iterator function (that is, a function that returns a new data chunk on each call or `nil` if there is no more data). The iterator handles `chunked`–encoding internally and returns already decoded data. It works _in a streaming fashion_, that is, the iterator reads from the socket only when needed and only requested amount of bytes.

Then we wrap the iterator in the `buffet.resty` object. The buffet object has the same inteface as the original socket object.

Finally we [create](https://github.com/openresty/lua-resty-upload#synopsis) the form using the buffet object instead of the original socket object and iterate the form to read its content _in a streaming fashion_.

## How to run the example

1. Install dependencies (`luarocks` or `opm` is not required):

    ```sh
    make install
    ```

2. Run nginx:

    ```sh
    make run
    ```

3. Make a request:

    * Make a regular (not `chunked`) request:

      ```sh
      make request

      ...
      > POST /upload?chunk-size=16 HTTP/1.1
      ...
      > Content-Type: multipart/form-data; boundary=------------------------41f104555e80dd9e
      >
      ...
      < HTTP/1.1 200 OK
      < Connection: close
      < Content-Length: 207
      <
      ["header",["Content-Disposition","form-data; name=\"content\"","Content-Disposition: form-data; name=\"content\""]]
      ["body","Socket-like buff"]
      ["body","er objects for L"]
      ["body","ua"]
      ["part_end"]
      ["eof"]
      ```

    * Make a `chunked` request:

      ```sh
      make chunked-request

      ...
      > POST /upload?chunk-size=16 HTTP/1.1
      ...
      > Transfer-Encoding: chunked
      > Content-Type: multipart/form-data; boundary=------------------------d4edb998497c04b6
      >
      < HTTP/1.1 200 OK
      < Connection: close
      < Content-Length: 207
      <
      ["header",["Content-Disposition","form-data; name=\"content\"","Content-Disposition: form-data; name=\"content\""]]
      ["body","Socket-like buff"]
      ["body","er objects for L"]
      ["body","ua"]
      ["part_end"]
      ["eof"]
      ```

    * Make a request with a different read chunk size:

      ```sh
      make [chunked-]request chunk-size=4
      ```

    * Make a request with a different text message as form content:

      ```sh
      make [chunked-]request content='Hello, World!'
      ```

    * Make a request with form content from a file:

      ```sh
      make [chunked-]request content=@README.md
      ```
