import new from require 'buffet.resty'


describe 'settimeouts()', ->

    it 'should return nothing if not closed', ->
        bf = new!
        n = nargs bf\settimeouts 1000, 2000, 3000
        assert.are.equal 0, n

    it 'should return nothing if closed', ->
        bf = new!
        bf\close!
        n = nargs bf\settimeouts 1000, 2000, 3000
        assert.are.equal 0, n
