import new from require 'buffet.resty'


describe 'receiveuntil()', ->

    it 'should raise error if too few args', ->
        bf = new 'deadbeef'
        ok, err = pcall bf.receiveuntil, bf
        assert.is.false, ok
        assert.are.equal 'expecting 2 or 3 arguments (including the object), but got 1', err

    it 'should raise error if too many args', ->
        bf = new 'deadbeef'
        ok, err = pcall bf.receiveuntil, bf, '--', {}, true
        assert.is.false, ok
        assert.are.equal 'expecting 2 or 3 arguments (including the object), but got 4', err

describe 'receiveuntil(pattern)', ->

    it 'should convert pattern numeric value to string', ->
        bf = new 'deadbeef1.23deadf00d1.23trailer'
        iter = bf\receiveuntil 1.23
        for {exp_n, exp_data, exp_err, exp_partial} in *{
            {1, 'deadbeef'}
            {1, 'deadf00d'}
            {3, nil, 'closed', 'trailer'}
            {2, nil, 'closed'}
        }
            n, data, err, partial = nargs iter!
            assert.are.equal exp_n, n
            assert.are.equal exp_data, data
            assert.are.equal exp_err, err
            assert.are.equal exp_partial, partial

    describe 'should raise error if bad pattern:', ->
        for {pattern, exp_err} in *{
            {nil, "bad argument #2 to 'receiveuntil' (string expected, got nil)"}
            {true, "bad argument #2 to 'receiveuntil' (string expected, got boolean)"}
            {{}, "bad argument #2 to 'receiveuntil' (string expected, got table)"}
            {(-> nil), "bad argument #2 to 'receiveuntil' (string expected, got function)"}
        }
            it tostring(pattern), ->
                bf = new 'deadbeef'
                ok, err = pcall bf\receiveuntil, pattern
                assert.is.false, ok
                assert.are.equal exp_err, err

    it 'should return error if pattern string is empty', ->
        bf = new 'deadbeef'
        n, iter, err = nargs bf\receiveuntil ''
        assert.are.equal n, 2
        assert.is.nil iter
        assert.are.equal 'pattern is empty', err

    it 'should return iterator despite closed connection', ->
        bf = new 'dead--beef'
        bf\close!
        n, iter = nargs bf\receiveuntil '--'
        assert.are.equal n, 1
        assert.is.function iter

describe 'receiveuntil(pattern, options)', ->

    describe 'should raise error if bad options:', ->
        for {options, exp_err} in *{
            {nil, "bad argument #3 to 'receiveuntil' (table expected, got nil)"}
            {true, "bad argument #3 to 'receiveuntil' (table expected, got boolean)"}
            {'s', "bad argument #3 to 'receiveuntil' (table expected, got string)"}
            {(-> nil), "bad argument #3 to 'receiveuntil' (table expected, got function)"}
        }
            it tostring(options), ->
                bf = new 'deadbeef'
                ok, err = pcall bf\receiveuntil, '--', options
                assert.is.false, ok
                assert.are.equal exp_err, err

    describe 'should raise error if bad inclusive option:', ->
        for {value, exp_err} in *{
            {'s', 'bad "inclusive" option value type: string'}
            {1, 'bad "inclusive" option value type: number'}
            {(-> nil), 'bad "inclusive" option value type: function'}
        }
            it tostring(value), ->
                bf = new 'deadbeef'
                ok, err = pcall bf\receiveuntil, '--', {inclusive: value}
                assert.is.false, ok
                assert.are.equal exp_err, err
