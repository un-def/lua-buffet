import new from require 'buffet.resty'


describe 'settimeout()', ->

    it 'should return nothing if not closed', ->
        bf = new!
        n = nargs bf\settimeout 1000
        assert.are.equal 0, n

    it 'should return nothing if closed', ->
        bf = new!
        bf\close!
        n = nargs bf\settimeout 1000
        assert.are.equal 0, n
