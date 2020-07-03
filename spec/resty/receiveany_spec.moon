import new from require 'buffet.resty'
import is_closed from require 'buffet'


describe 'receiveany(max)', ->

    describe 'should raise error if bad max argument type:', ->
        for {msg, max} in *{
            {'boolean', true}
            {'nil', nil}
            {'non-number-like string', 'foo'}
            {'table', {1}}
            {'function', ->}
            {'negative', -1}
            {'zero', 0}
        }
            it msg, ->
                bf = new 'deadbeef'
                ok, err = pcall bf.receiveany, bf, max
                assert.is.false, ok
                assert.are.equal "bad argument #2 to 'receiveany' (bad max argument)", err

    it 'should return error if closed', ->
        bf = new 'deadbeef'
        bf\close!
        n, data, err = nargs bf\receiveany 4
        assert.are.equal 2, n
        assert.is.nil data
        assert.are.equal 'closed', err

    it 'should accept floating-point numbers', ->
        bf = new 'deadbeefdeadf00d'
        for {max, expected} in *{
            {2.1, 'de'}
            {2.9, 'ad'}
            {3.1, 'bee'}
            {3.9, 'fde'}
        }
            n, data = nargs bf\receiveany max
            assert.are.equal 1, n
            assert.are.equal expected, data

    it 'should accept number-like strings', ->
        bf = new 'deadbeefdeadf00d'
        for {max, expected} in *{
            {'2', 'de'}
            {'   3\t\t\n', 'adb'}
            {'3.999', 'eef'}
        }
            n, data = nargs bf\receiveany max
            assert.are.equal 1, n
            assert.are.equal expected, data

    it 'should return the requested amount of bytes if there is enough bytes in the "buffer"', ->
        bf = new 'deadbeefdeadf00d'
        for {max, expected} in *{
            {4, 'dead'}
            {2, 'be'}
            {1, 'e'}
        }
            n, data = nargs bf\receiveany max
            assert.are.equal 1, n
            assert.are.equal expected, data

    it 'should return the entire "buffer" content if there is no enough bytes', ->
        bf = new 'deadbeefdeadf00d'
        for {max, expected} in *{
            {4, 'dead'}
            {1024, 'beefdeadf00d'}
        }
            n, data = nargs bf\receiveany max
            assert.are.equal 1, n
            assert.are.equal expected, data
        assert.is.false is_closed(bf)

    it 'should close the buffet and return an error if there is no bytes in the "buffer"', ->
        bf = new!
        n, data, err, partial = nargs bf\receiveany 1
        assert.are.equal 3, n
        assert.is.nil data
        assert.are.equal 'closed', err
        assert.are.equal '', partial
        assert.is.true is_closed(bf)

    it 'should not read a next chunk if there is a chunk in the "buffer"', ->
        bf = new {'', 'dead', '', '', 'f00ddead', '', '', 'beef'}
        for expected in *{'dead', 'f00dde', 'ad', 'beef'}
            n, data = nargs bf\receiveany 6
            assert.are.equal 1, n
            assert.are.equal expected, data
