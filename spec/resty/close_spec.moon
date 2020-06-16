import new from require 'buffet.resty'


describe 'close()', ->

    it 'should close it not closed', ->
        bf = new 'deadbeef'
        n, ok = nargs bf\close!
        assert.are.equal 1, n
        assert.are.equal 1, ok

    it 'should return error if already closed', ->
        bf = new 'deadbeef'
        bf\close!
        n, ok, err = nargs bf\close!
        assert.are.equal 2, n
        assert.is.nil ok
        assert.are.equal 'closed', err
