import new from require 'buffet.resty'
import is_closed from require 'buffet'


describe 'setkeepalive()', ->

    it 'should close the buffet and return 1 if not closed', ->
        bf = new 'deadbeef'
        n, ok = nargs bf\setkeepalive!
        assert.are.equal 1, n
        assert.are.equal 1, ok
        assert.is.true is_closed bf

    it 'should return error if closed', ->
        bf = new 'deadbeef'
        bf\close!
        n, ok, err = nargs bf\setkeepalive!
        assert.are.equal 2, n
        assert.is.nil ok
        assert.are.equal 'closed', err
        assert.is.true is_closed bf
