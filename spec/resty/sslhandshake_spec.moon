import new from require 'buffet.resty'


describe 'sslhandshake()', ->

    it 'should return true if not closed', ->
        bf = new 'deadbeef'
        for _ = 1, 2
            n, ok = nargs bf\sslhandshake!
            assert.are.equal 1, n
            assert.is.true ok

    it 'should return error if closed', ->
        bf = new 'deadbeef'
        bf\close!
        n, ok, err = nargs bf\sslhandshake!
        assert.are.equal 2, n
        assert.is.nil ok
        assert.are.equal 'closed', err
