import new from require 'buffet.resty'


describe 'new()', ->

    describe 'should accept', ->
        for {value, value_type} in *{
            {{}, 'table'}
            {'', 'string'}
            {(-> nil), 'function'}
        }
            it value_type, ->
                n, bf = nargs new value
                assert.are.equal 1, n
                assert.is.table bf

    describe 'should not accept', ->
        for {value, value_type} in *{
            {nil, 'nil'}
            {false, 'boolean'}
            {0, 'number'}
        }
            it value_type, ->
                n, bf, err = nargs new value
                assert.are.equal 2, n
                assert.is.nil bf
                expected_err = 'argument #1 must be string, table, or function, got: %s'\format value_type
                assert.are.equal expected_err, err
