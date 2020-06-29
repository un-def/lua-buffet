import new from require 'buffet.resty'
import is_closed from require 'buffet'


describe 'connect()', ->

    it 'should return 1 if already "connected"', ->
        bf = new 'deadbeef'
        for _ = 1, 2
            n, ok = nargs bf\connect!
            assert.are.equal 1, n
            assert.are.equal 1, ok
            assert.is.false is_closed bf

    it 'should return 1 if not "connected"', ->
        bf = new 'deadbeef'
        bf\close!
        n, ok = nargs bf\connect!
        assert.are.equal 1, n
        assert.are.equal 1, ok
        assert.is.false is_closed bf
