import new from require 'buffet.resty'
import is_closed from require 'buffet'


describe 'close()', ->

    it 'should close it not closed', ->
        bf = new 'deadbeef'
        n, ok = nargs bf\close!
        assert.are.equal 1, n
        assert.are.equal 1, ok
        assert.is.true is_closed bf

    it 'should return error if already closed', ->
        bf = new 'deadbeef'
        bf\close!
        n, ok, err = nargs bf\close!
        assert.are.equal 2, n
        assert.is.nil ok
        assert.are.equal 'closed', err
        assert.is.true is_closed bf
