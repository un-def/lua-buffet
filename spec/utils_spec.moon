import is_closed, get_iterator_error from require 'buffet'
import new from require 'buffet.resty'


describe 'is_closed(bf)', ->

    it "should return true if buffet is closed with 'close' method", ->
        bf = new 'deadbeef'
        bf\close!
        n, closed = nargs is_closed bf
        assert.are.equal 1, n
        assert.are.equal true, closed

    it "should return true if buffet is closed with 'receive' method", ->
        bf = new 'deadbeef'
        bf\receive '*a'
        n, closed = nargs is_closed bf
        assert.are.equal 1, n
        assert.are.equal true, closed

    it 'should return false if buffet is not closed', ->
        bf = new 'deadbeef'
        n, closed = nargs is_closed bf
        assert.are.equal 1, n
        assert.are.equal false, closed

    it "should not check object type and return '_closed' field as is", ->
        n, closed = nargs is_closed {_closed: 'foo'}
        assert.are.equal 1, n
        assert.are.equal 'foo', closed


describe 'get_iterator_error(bf)', ->

    it 'should return nil if there was no error', ->
        iterator = coroutine.wrap ->
            coroutine.yield 'foo'
            coroutine.yield 'bar'
            coroutine.yield nil
            coroutine.yeild 'baz'
        bf = new iterator
        chunks = {}
        while true
            chunk, err = bf\receive 2
            if err
                assert.are.equal 'closed', err
                break
            table.insert chunks, chunk
        assert.are.same {'fo', 'ob', 'ar'}, chunks
        n, iter_err = nargs get_iterator_error bf
        assert.are.equal 1, n
        assert.is.nil iter_err

    it 'should return error value if there was an error', ->
        iterator = coroutine.wrap ->
            coroutine.yield 'foo'
            coroutine.yield 'bar'
            coroutine.yield nil, 'some error'
            coroutine.yeild 'baz'
        bf = new iterator
        chunks = {}
        while true
            chunk, err = bf\receive 2
            if err
                assert.are.equal 'closed', err
                break
            table.insert chunks, chunk
        assert.are.same {'fo', 'ob', 'ar'}, chunks
        n, iter_err = nargs get_iterator_error bf
        assert.are.equal 1, n
        assert.are.equal 'some error', iter_err

    it "should not check object type and return '_iterator_error' field as is", ->
        n, closed = nargs get_iterator_error {_iterator_error: 'foo'}
        assert.are.equal 1, n
        assert.are.equal 'foo', closed
