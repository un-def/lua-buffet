import new from require 'buffet.resty'


describe 'receive()', ->

    describe 'should return error if bad pattern:', ->
        for {pattern, msg} in *{
            {nil, 'nil'}
            {'foo', 'unsupported string pattern'}
            {false, 'boolean'}
            {{}, 'table'}
        }
            it msg, ->
                bf = new 'deadbeef'
                n, chunk, err = nargs bf\receive pattern
                assert.are.equal 2, n
                assert.is.nil chunk
                assert.are.equal "bad argument #2 to 'receive' (bad pattern argument)", err
