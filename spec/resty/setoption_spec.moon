import new from require 'buffet.resty'


describe 'setoption()', ->

    it 'should return nothing if not closed', ->
        bf = new!
        n = nargs bf\setoption 'keepalive', true
        assert.are.equal 0, n

    it 'should return nothing if closed', ->
        bf = new!
        bf\close!
        n = nargs bf\setoption 'keepalive', true
        assert.are.equal 0, n
