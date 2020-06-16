import new from require 'buffet.resty'


get_input_iterator = (tbl) ->
    index = 0
    ->
        index += 1
        tbl[index]


describe 'receiveuntil()', ->

    describe 'iterator()', ->

        describe 'with trailer', ->

            input_string = 'deadbeef-++-deadf00d-++-trailer'
            input_table = {'', 'de', 'adbee', '', 'f-++-de' , 'adf0', '0', 'd-', '++', '-trail', 'er'}
            input_iterator = get_input_iterator input_table

            for {input, msg} in *{
                {input_string, 'from string'}
                {input_table, 'from table'}
                {input_iterator, 'from iterator'}
            }
                it msg, ->
                    bf = new input
                    iter = bf\receiveuntil '-++-'
                    for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'deadbeef'}
                        {1, 'deadf00d'}
                        {3, nil, 'closed', 'trailer'}
                        {2, nil, 'closed'}
                        {2, nil, 'closed'}
                    }
                        n, data, err, partial = nargs iter!
                        assert.are.equal exp_n, n
                        assert.are.equal exp_data, data
                        assert.are.equal exp_err, err
                        assert.are.equal exp_partial, partial

        describe 'without trailer', ->

            input_string = 'deadbeef-++-deadf00d-++-'
            input_table = {'', 'de', 'adbee', '', 'f-++-de' , 'adf0', '0', '', 'd-', '++', '-'}
            input_iterator = get_input_iterator input_table

            for {input, msg} in *{
                {input_string, 'from string'}
                {input_table, 'from table'}
                {input_iterator, 'from iterator'}
            }
                it msg, ->
                    bf = new input
                    iter = bf\receiveuntil '-++-'
                    for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'deadbeef'}
                        {1, 'deadf00d'}
                        {3, nil, 'closed', ''}
                        {2, nil, 'closed'}
                        {2, nil, 'closed'}
                    }
                        n, data, err, partial = nargs iter!
                        assert.are.equal exp_n, n
                        assert.are.equal exp_data, data
                        assert.are.equal exp_err, err
                        assert.are.equal exp_partial, partial

    describe 'iterator(size)', ->

        describe 'should raise error if size is not number or number-like string: ', ->
            for {size, exp_err} in *{
                {nil, "bad argument #1 to iterator (number expected, got nil)"}
                {true, "bad argument #1 to iterator (number expected, got boolean)"}
                {{}, "bad argument #1 to iterator (number expected, got table)"}
                {(-> nil), "bad argument #1 to iterator (number expected, got function)"}
                {'s', "bad argument #1 to iterator (number expected, got string)"}
            }
                it tostring(size), ->
                    bf = new 'dead--beef'
                    iter = bf\receiveuntil '--'
                    ok, err = pcall iter, size
                    assert.is.false, ok
                    assert.are.equal exp_err, err

        it 'should convert number-like string to number', ->
            bf = new 'deadbeef-++-dead-++-f00d-++-trailer'
            iter = bf\receiveuntil '-++-'
            for {exp_n, exp_data, exp_err, exp_partial} in *{
                {1, 'dead'}
                {1, 'beef'}
                {1, ''}
                {3, nil, nil, nil}
                {1, 'dead'}
                {1, ''}
                {3, nil, nil, nil}
                {1, 'f00d'}
                {1, ''}
                {3, nil, nil, nil}
                {1, 'trai'}
                {3, nil, 'closed', 'ler'}
                {2, nil, 'closed'}
            }
                n, data, err, partial = nargs iter '\t\t   4 \n'
                assert.are.equal exp_n, n
                assert.are.equal exp_data, data
                assert.are.equal exp_err, err
                assert.are.equal exp_partial, partial

        it 'should round floating-point number to floor', ->
            bf = new 'deadbeef-++-dead-++-f00d-++-trailer'
            iter = bf\receiveuntil '-++-'
            for {size, exp_n, exp_data, exp_err, exp_partial} in *{
                {2.1, 1, 'de'}
                {2.9, 1, 'ad'}
                {3.9, 1, 'bee'}
                {10.5, 1, 'f'}
                {1.1, 3, nil, nil, nil}
            }
                n, data, err, partial = nargs iter size
                assert.are.equal exp_n, n
                assert.are.equal exp_data, data
                assert.are.equal exp_err, err
                assert.are.equal exp_partial, partial

        describe 'with trailer', ->

            describe 'read in two steps', ->
                input_string = 'deadbeef-++-deadf00d-++-trailer'
                input_table = {'', 'de', 'adbee', '', 'f-++-de' , 'adf0', '0', 'd-', '++', '-trail', 'er'}
                input_iterator = get_input_iterator input_table

                for {input, msg} in *{
                    {input_string, 'from string'}
                    {input_table, 'from table'}
                    {input_iterator, 'from iterator'}
                }
                    it msg, ->
                        bf = new input
                        iter = bf\receiveuntil '-++-'
                        for {exp_n, exp_data, exp_err, exp_partial} in *{
                            {1, 'deadb'}
                            {1, 'eef'}
                            {3, nil, nil, nil}
                            {1, 'deadf'}
                            {1, '00d'}
                            {3, nil, nil, nil}
                            {1, 'trail'}
                            {3, nil, 'closed', 'er'}
                            {2, nil, 'closed'}
                            {2, nil, 'closed'}
                        }
                            n, data, err, partial = nargs iter 5
                            assert.are.equal exp_n, n
                            assert.are.equal exp_data, data
                            assert.are.equal exp_err, err
                            assert.are.equal exp_partial, partial

            describe 'read at once', ->
                input_string = 'deadbeef-++-deadf00d-++-trailer'
                input_table = {'', 'deadbee', '', 'f-++-de' , 'ad', 'f00d', '-++', '-traile', 'r'}
                input_iterator = get_input_iterator input_table

                for {input, msg} in *{
                    {input_string, 'from string'}
                    {input_table, 'from table'}
                    {input_iterator, 'from iterator'}
                }
                    it msg, ->
                        bf = new input
                        iter = bf\receiveuntil '-++-'
                        for {exp_n, exp_data, exp_err, exp_partial} in *{
                            {1, 'deadbee'}
                            {1, 'f'}
                            {3, nil, nil, nil}
                            {1, 'deadf00'}
                            {1, 'd'}
                            {3, nil, nil, nil}
                            {3, nil, 'closed', 'trailer'}
                            {2, nil, 'closed'}
                            {2, nil, 'closed'}
                        }
                            n, data, err, partial = nargs iter 7
                            assert.are.equal exp_n, n
                            assert.are.equal exp_data, data
                            assert.are.equal exp_err, err
                            assert.are.equal exp_partial, partial

        it 'without trailer', ->
            bf = new 'deadbeef-++-deadf00d-++-'
            iter = bf\receiveuntil '-++-'
            for {exp_n, exp_data, exp_err, exp_partial} in *{
                {1, 'deadb'}
                {1, 'eef'}
                {3, nil, nil, nil}
                {1, 'deadf'}
                {1, '00d'}
                {3, nil, nil, nil}
                {3, nil, 'closed', ''}
                {2, nil, 'closed'}
                {2, nil, 'closed'}
            }
                n, data, err, partial = nargs iter 5
                assert.are.equal exp_n, n
                assert.are.equal exp_data, data
                assert.are.equal exp_err, err
                assert.are.equal exp_partial, partial

        describe 'when size more than part', ->

            it 'without trailer', ->
                bf = new 'deadbeef-++-deadf00d-++-'
                iter = bf\receiveuntil '-++-'
                for {exp_n, exp_data, exp_err, exp_partial} in *{
                    {1, 'deadbeef'}
                    {3, nil, nil, nil}
                    {1, 'deadf00d'}
                    {3, nil, nil, nil}
                    {3, nil, 'closed', ''}
                    {2, nil, 'closed'}
                    {2, nil, 'closed'}
                }
                    n, data, err, partial = nargs iter 16
                    assert.are.equal exp_n, n
                    assert.are.equal exp_data, data
                    assert.are.equal exp_err, err
                    assert.are.equal exp_partial, partial

            it 'with trailer', ->
                bf = new 'deadbeef-++-deadf00d-++-trailer'
                iter = bf\receiveuntil '-++-'
                for {exp_n, exp_data, exp_err, exp_partial} in *{
                    {1, 'deadbeef'}
                    {3, nil, nil, nil}
                    {1, 'deadf00d'}
                    {3, nil, nil, nil}
                    {3, nil, 'closed', 'trailer'}
                    {2, nil, 'closed'}
                    {2, nil, 'closed'}
                }
                    n, data, err, partial = nargs iter 16
                    assert.are.equal exp_n, n
                    assert.are.equal exp_data, data
                    assert.are.equal exp_err, err
                    assert.are.equal exp_partial, partial

        describe 'when size is divisible', ->
            index = 0
            for input in *{
                {'deadbeef', '-++-', 'deadf00d', '-++-', 'trailer'}
                {'deadbee', 'f-++-', 'deadf00d-', '++-trailer'}
                {'deadbee', 'f-++', '-deadf00', 'd-++', '-trailer'}
                {'dead', 'beef', '-++-', 'dead', 'f00d-++-', 'trailer'}
            }
                index += 1
                it index, ->
                    bf = new input
                    iter = bf\receiveuntil '-++-'
                    for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'dead'}
                        {1, 'beef'}
                        {1, ''}
                        {3, nil, nil, nil}
                        {1, 'dead'}
                        {1, 'f00d'}
                        {1, ''}
                        {3, nil, nil, nil}
                        {1, 'trai'}
                        {3, nil, 'closed', 'ler'}
                        {2, nil, 'closed'}
                        {2, nil, 'closed'}
                    }
                        n, data, err, partial = nargs iter 4
                        assert.are.equal exp_n, n
                        assert.are.equal exp_data, data
                        assert.are.equal exp_err, err
                        assert.are.equal exp_partial, partial

    it 'iterator(0) is same as iterator()', ->
        bf = new 'deadbeef-++-dead-++-f00d-++-trailer'
        iter = bf\receiveuntil '-++-'
        for {exp_n, exp_data, exp_err, exp_partial} in *{
            {1, 'deadbeef'}
            {1, 'dead'}
            {1, 'f00d'}
            {3, nil, 'closed', 'trailer'}
            {2, nil, 'closed'}
        }
            n, data, err, partial = nargs iter 0
            assert.are.equal exp_n, n
            assert.are.equal exp_data, data
            assert.are.equal exp_err, err
            assert.are.equal exp_partial, partial

    it 'iterator(-1) is same as iterator()', ->
        bf = new 'deadbeef-++-dead-++-f00d-++-trailer'
        iter = bf\receiveuntil '-++-'
        for {exp_n, exp_data, exp_err, exp_partial} in *{
            {1, 'deadbeef'}
            {1, 'dead'}
            {1, 'f00d'}
            {3, nil, 'closed', 'trailer'}
            {2, nil, 'closed'}
        }
            n, data, err, partial = nargs iter -1
            assert.are.equal exp_n, n
            assert.are.equal exp_data, data
            assert.are.equal exp_err, err
            assert.are.equal exp_partial, partial
