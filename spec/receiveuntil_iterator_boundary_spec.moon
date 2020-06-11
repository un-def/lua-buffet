import new from require 'buffet.resty'


describe 'receiveuntil() iterator boundary cases:', ->

    describe 'with trailer', ->

        describe '4 char pattern', ->
            index = 0
            for input in *{
                'deadbeef-++-deadf00d-++-trailer'
                {'deadbeef', '-++-', 'deadf00d', '-++-', 'trailer'}
                {'deadbee', 'f-++-', 'deadf00d-', '++-trailer'}
                {'deadbee', 'f-++', '-deadf00', 'd-++', '-trailer'}
                {'dead', 'beef', '-++-', 'dead', 'f00d-++-', 'trailer'}
                {'d', 'eadbeef-++-de', 'ad', 'f00d', '-+', '+-', 'trai', 'le', 'r'}
            }
                index += 1
                describe index, ->

                    it 'read 4 bytes', ->
                        bf = new input
                        iter = bf\receiveuntil '-++-'
                        for {exp_n, exp_data, exp_err, exp_partial} in *{
                            {1, 'dead'}
                            {1, 'beef'}
                            {3, nil, nil, nil}
                            {1, 'dead'}
                            {1, 'f00d'}
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

                    it 'read 3 bytes', ->
                        bf = new input
                        iter = bf\receiveuntil '-++-'
                        for {exp_n, exp_data, exp_err, exp_partial} in *{
                            {1, 'dea'}
                            {1, 'dbe'}
                            {1, 'ef'}
                            {3, nil, nil, nil}
                            {1, 'dea'}
                            {1, 'df0'}
                            {1, '0d'}
                            {3, nil, nil, nil}
                            {1, 'tra'}
                            {1, 'ile'}
                            {3, nil, 'closed', 'r'}
                            {2, nil, 'closed'}
                            {2, nil, 'closed'}
                        }
                            n, data, err, partial = nargs iter 3
                            assert.are.equal exp_n, n
                            assert.are.equal exp_data, data
                            assert.are.equal exp_err, err
                            assert.are.equal exp_partial, partial

        describe '1 char pattern', ->
            index = 0
            for input in *{
                'deadbeef-deadf00d-trailer'
                {'deadbeef', '-', 'deadf00d', '-', 'trailer'}
                {'deadbee', 'f-', 'deadf00d-', 'trailer'}
                {'deadbee', 'f', '-deadf00', 'd-', 'trailer'}
                {'dead', 'beef', '-', 'dead', 'f00d-', 'trailer'}
                {'d', 'eadbeef-de', 'ad', 'f00d', '', '-', 'trai', 'le', 'r'}
            }
                index += 1
                it index, ->
                    bf = new input
                    iter = bf\receiveuntil '-'
                    for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'dead'}
                        {1, 'beef'}
                        {3, nil, nil, nil}
                        {1, 'dead'}
                        {1, 'f00d'}
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

    describe 'without trailer', ->

        describe '3 char pattern', ->
            index = 0
            for input in *{
                'deadbeef***deadf00d***'
                {'dea', 'dbeef*', '*', '*de', 'adf00d', '**', '*'}
                {'deadbeef**', '*', 'deadf', '00d*', '**'}
                {'deadbee', 'f**', '*deadf00', 'd**', '*'}
                {'dead', 'beef', '***', 'dead', 'f00d***', ''}
                {'d', 'eadbeef***de', 'ad', 'f00d', '**', '*'}
            }
                index += 1
                describe index, ->

                    it 'read 7 bytes', ->
                        bf = new input
                        iter = bf\receiveuntil '***'
                        for {exp_n, exp_data, exp_err, exp_partial} in *{
                            {1, 'deadbee'}
                            {1, 'f'}
                            {3, nil, nil, nil}
                            {1, 'deadf00'}
                            {1, 'd'}
                            {3, nil, nil, nil}
                            {3, nil, 'closed', ''}
                            {2, nil, 'closed'}
                            {2, nil, 'closed'}
                        }
                            n, data, err, partial = nargs iter 7
                            assert.are.equal exp_n, n
                            assert.are.equal exp_data, data
                            assert.are.equal exp_err, err
                            assert.are.equal exp_partial, partial

                    it 'read 1 bytes', ->
                        bf = new input
                        iter = bf\receiveuntil '***'
                        for {exp_n, exp_data, exp_err, exp_partial} in *{
                            {1, 'd'}, {1, 'e'}, {1, 'a'}, {1, 'd'}
                            {1, 'b'}, {1, 'e'}, {1, 'e'}, {1, 'f'}
                            {3, nil, nil, nil}
                            {1, 'd'}, {1, 'e'}, {1, 'a'}, {1, 'd'}
                            {1, 'f'}, {1, '0'}, {1, '0'}, {1, 'd'}
                            {3, nil, nil, nil}
                            {3, nil, 'closed', ''}
                            {2, nil, 'closed'}
                            {2, nil, 'closed'}
                        }
                            n, data, err, partial = nargs iter 1
                            assert.are.equal exp_n, n
                            assert.are.equal exp_data, data
                            assert.are.equal exp_err, err
                            assert.are.equal exp_partial, partial

        describe '1 char pattern', ->
            index = 0
            for input in *{
                'deadbeef-deadf00d-'
                {'deadbeef', '-', 'deadf00d-'}
                {'deadbee', 'f-', 'deadf00d-'}
                {'deadbee', 'f', '-deadf00', 'd-'}
                {'dead', 'beef', '-', 'dead', 'f00d-'}
                {'d', 'eadbeef-de', 'ad', 'f00d', '', '-'}
            }
                index += 1
                it index, ->
                    bf = new input
                    iter = bf\receiveuntil '-'
                    for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'dead'}
                        {1, 'beef'}
                        {3, nil, nil, nil}
                        {1, 'dead'}
                        {1, 'f00d'}
                        {3, nil, nil, nil}
                        {3, nil, 'closed', ''}
                        {2, nil, 'closed'}
                        {2, nil, 'closed'}
                    }
                        n, data, err, partial = nargs iter 4
                        assert.are.equal exp_n, n
                        assert.are.equal exp_data, data
                        assert.are.equal exp_err, err
                        assert.are.equal exp_partial, partial

    it 'pattern longer than buffer value', ->
        bf = new {'---', '-', '--', '-', '-deadf00d', '--------'}
        iter = bf\receiveuntil '--------'
        for {exp_n, exp_data, exp_err, exp_partial} in *{
            {1, ''}
            {3, nil, nil, nil}
            {1, 'dead'}
            {1, 'f00d'}
            {3, nil, nil, nil}
            {3, nil, 'closed', ''}
            {2, nil, 'closed'}
        }
            n, data, err, partial = nargs iter 4
            assert.are.equal exp_n, n
            assert.are.equal exp_data, data
            assert.are.equal exp_err, err
            assert.are.equal exp_partial, partial
