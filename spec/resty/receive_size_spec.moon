import new from require 'buffet.resty'


get_buffet = (input) ->
    if type(input) == 'function'
        new input!
    else
        new input


describe 'receive(size)', ->

    it 'should return error if closed', ->
        bf = new 'deadbeef'
        bf\close!
        n, data, err = nargs bf\receive 4
        assert.are.equal 2, n
        assert.is.nil data
        assert.are.equal 'closed', err

    describe 'should raise error if size is negative', ->
        for {size, msg} in *{
            {-1, 'number'}
            {'-1', 'number-like string'}
        }
            it msg, ->
                bf = new 'deadbeef'
                ok, err = pcall bf\receive, size
                assert.is.false, ok
                assert.are.equal "bad argument #2 to 'receive' (bad pattern argument)", err

    it 'should return empty string if size = 0 unless closed', ->
        bf = new 'deadbeef'
        for _ = 1, 3
            n, data = nargs bf\receive 0
            assert.are.equal 1, n
            assert.are.equal '', data
        bf\close!
        n, data, err = nargs bf\receive 0
        assert.are.equal 2, n
        assert.is.nil data
        assert.are.equal 'closed', err

    input_string = 'deadbeefdeadf00d'
    input_table = {'', 'de', 'adbee', '', 'fde' , 'adf0', '0', 'd', '', ''}
    input_iterator = ->
        index = 0
        ->
            index += 1
            input_table[index]

    for {input, msg} in *{
        {input_string, 'from string'}
        {input_table, 'from table'}
        {input_iterator, 'from iterator'}
    }
        describe msg, ->

            it 'with partial', ->
                bf = get_buffet input
                for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'deadb'}
                        {1, 'eefde'}
                        {1, 'adf00'}
                        {3, nil, 'closed', 'd'}
                        {2, nil, 'closed'}
                        {2, nil, 'closed'}
                }
                    n, data, err, partial = nargs bf\receive 5
                    assert.are.equal exp_n, n
                    assert.are.equal exp_data, data
                    assert.are.equal exp_err, err
                    assert.are.equal exp_partial, partial

            it 'with empty partial', ->
                bf = get_buffet input
                for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'deadbeef'}
                        {1, 'deadf00d'}
                        {3, nil, 'closed', ''}
                        {2, nil, 'closed'}
                        {2, nil, 'closed'}
                }
                    n, data, err, partial = nargs bf\receive 8
                    assert.are.equal exp_n, n
                    assert.are.equal exp_data, data
                    assert.are.equal exp_err, err
                    assert.are.equal exp_partial, partial

            it 'more than body', ->
                bf = get_buffet input
                for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {3, nil, 'closed', 'deadbeefdeadf00d'}
                        {2, nil, 'closed'}
                        {2, nil, 'closed'}
                }
                    n, data, err, partial = nargs bf\receive 1024
                    assert.are.equal exp_n, n
                    assert.are.equal exp_data, data
                    assert.are.equal exp_err, err
                    assert.are.equal exp_partial, partial

    it 'should accept floating-point numbers', ->
        bf = new 'deadbeefdeadf00d'
        for {size, exp_n, exp_data, exp_err, exp_partial} in *{
            {2.1, 1, 'de'}
            {2.9, 1, 'ad'}
            {3.1, 1, 'bee'}
            {3.9, 1, 'fde'}
        }
            n, data, err, partial = nargs bf\receive size
            assert.are.equal exp_n, n
            assert.are.equal exp_data, data
            assert.are.equal exp_err, err
            assert.are.equal exp_partial, partial

    it 'should accept number-like strings', ->
        bf = new 'deadbeefdeadf00d'
        for {exp_n, exp_data, exp_err, exp_partial} in *{
            {1, 'deadb'}
            {1, 'eefde'}
            {1, 'adf00'}
            {3, nil, 'closed', 'd'}
        }
            n, data, err, partial = nargs bf\receive ' \t 5\r\n '
            assert.are.equal exp_n, n
            assert.are.equal exp_data, data
            assert.are.equal exp_err, err
            assert.are.equal exp_partial, partial

    it 'should keep CR characters', ->
        bf = new {'deadbe', 'ef\r', '\n', 'dead', '', 'f00d\r\n'}
        for {exp_n, exp_data, exp_err, exp_partial} in *{
            {1, 'deadbeef\r\nde'}
            {3, nil, 'closed','adf00d\r\n'}
        }
            n, data, err, partial = nargs bf\receive 12
            assert.are.equal exp_n, n
            assert.are.equal exp_data, data
            assert.are.equal exp_err, err
            assert.are.equal exp_partial, partial
