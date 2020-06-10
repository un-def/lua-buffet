import new from require 'buffet.resty'


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
