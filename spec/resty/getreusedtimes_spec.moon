import new from require 'buffet.resty'


describe 'getreusedtimes()', ->

    it 'should return 0 it not closed', ->
        bf = new!
        n, count = nargs bf\getreusedtimes!
        assert.are.equal 1, n
        assert.are.equal 0, count

    it 'should return error if closed', ->
        bf = new!
        bf\close!
        n, count, err = nargs bf\getreusedtimes!
        assert.are.equal 2, n
        assert.is.nil count
        assert.are.equal 'closed', err
