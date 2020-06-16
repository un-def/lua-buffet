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
                    iter = bf\receiveuntil '-++-', {inclusive: true}
                    for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'deadbeef-++-'}
                        {1, 'deadf00d-++-'}
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
                    iter = bf\receiveuntil '-++-', {inclusive: true}
                    for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'deadbeef-++-'}
                        {1, 'deadf00d-++-'}
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

            index = 0
            for input in *{
                {'deadbeef', '-++-', 'deadf00d', '-++-', 'trailer'}
                {'deadbee', 'f-++-', 'deadf00d-', '++-trailer'}
                {'deadbee', 'f-++', '-deadf00', 'd-++', '-trailer'}
                {'dead', 'beef', '-++-', 'dead', 'f00d-++-', 'trailer'}
            }
                index += 1
                msg = index
                describe 'when size is divisible', ->
                    it msg, ->
                        bf = new input
                        iter = bf\receiveuntil '-++-', {inclusive: true}
                        for {exp_n, exp_data, exp_err, exp_partial} in *{
                            {1, 'dead'}
                            {1, 'beef'}
                            {1, '-++-'}
                            {3, nil, nil, nil}
                            {1, 'dead'}
                            {1, 'f00d'}
                            {1, '-++-'}
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

                describe 'when size is divisible, less than pattern length', ->
                    it msg, ->
                        bf = new input
                        iter = bf\receiveuntil '-++-', {inclusive: true}
                        for {exp_n, exp_data, exp_err, exp_partial} in *{
                            {1, 'de'}
                            {1, 'ad'}
                            {1, 'be'}
                            {1, 'ef'}
                            {1, '-++-'}
                            {3, nil, nil, nil}
                            {1, 'de'}
                            {1, 'ad'}
                            {1, 'f0'}
                            {1, '0d'}
                            {1, '-++-'}
                            {3, nil, nil, nil}
                            {1, 'tr'}
                            {1, 'ai'}
                            {1, 'le'}
                            {3, nil, 'closed', 'r'}
                            {2, nil, 'closed'}
                            {2, nil, 'closed'}
                        }
                            n, data, err, partial = nargs iter 2
                            assert.are.equal exp_n, n
                            assert.are.equal exp_data, data
                            assert.are.equal exp_err, err
                            assert.are.equal exp_partial, partial

                describe 'when size is not divisible', ->
                    it msg, ->
                        bf = new input
                        iter = bf\receiveuntil '-++-', {inclusive: true}
                        for {exp_n, exp_data, exp_err, exp_partial} in *{
                            {1, 'deadb'}
                            {1, 'eef-++-'}
                            {3, nil, nil, nil}
                            {1, 'deadf'}
                            {1, '00d-++-'}
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

    it 'iterator() and iterator(size) mixed', ->
        bf = new 'deadbeef-++-dead-++-f00d-++-trailer'
        iter = bf\receiveuntil '-++-', {inclusive: true}
        for {size, exp_n, exp_data, exp_err, exp_partial} in *{
            {4, 1, 'dead'}
            {5, 1, 'beef-++-'}
            {nil, 3, nil, nil, nil}
            {4, 1, 'dead'}
            {1, 1, '-++-'}
            {nil, 3, nil, nil, nil}
            {3, 1, 'f00'}
            {nil, 1, 'd-++-'}
            {nil, 3, nil, 'closed', 'trailer'}
            {nil, 2, nil, 'closed'}
        }
            local n, data, err, partial
            if size
                n, data, err, partial = nargs iter size
            else
                n, data, err, partial = nargs iter!
            assert.are.equal exp_n, n
            assert.are.equal exp_data, data
            assert.are.equal exp_err, err
            assert.are.equal exp_partial, partial
