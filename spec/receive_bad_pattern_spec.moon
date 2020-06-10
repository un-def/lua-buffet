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
