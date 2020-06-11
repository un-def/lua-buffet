import new from require 'buffet.resty'


describe 'receive(pattern)', ->

    describe 'should raise error if bad pattern:', ->
        for {pattern, msg} in *{
            {nil, 'nil'}
            {'foo', 'unsupported string pattern'}
            {false, 'boolean'}
            {{}, 'table'}
        }
            it msg, ->
                bf = new 'deadbeef'
                ok, err = pcall bf\receive, pattern
                assert.is.false, ok
                assert.are.equal "bad argument #2 to 'receive' (bad pattern argument)", err

describe "receive('*a')", ->

    describe 'should return all data at once', ->
        for {input, msg} in *{
            {'dead\rbeef\r\ndead\rf00d\r\n', 'from string'}
            {{'dead', '\rbeef\r\nde', '', 'ad\rf00d', '\r', '\n'}, 'from table'}
        }
            it msg, ->
                bf = new input
                n, data = nargs bf\receive '*a'
                assert.are.equal 1, n
                assert.are.equal 'dead\rbeef\r\ndead\rf00d\r\n', data
                for _ = 1, 2
                    n, data = nargs bf\receive '*a'
                    assert.are.equal 1, n
                    assert.are.equal '', data

    it 'should return empty string if closed', ->
        bf = new 'deadbeef'
        bf\close!
        for _ = 1, 2
            n, data = nargs bf\receive '*a'
            assert.are.equal 1, n
            assert.are.equal '', data
