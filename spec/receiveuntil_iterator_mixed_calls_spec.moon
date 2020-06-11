import new from require 'buffet.resty'


describe 'receiveuntil() iterator mixed calls cases:', ->

    it 'iterator() and iterator(size)', ->
        bf = new 'deadbeef--dead--f00d--trailer'
        iter = bf\receiveuntil '--'
        for {size, exp_n, exp_data, exp_err, exp_partial} in *{
            {4, 1, 'dead'}
            {4, 1, 'beef'}
            {nil, 3, nil, nil, nil}
            {4, 1, 'dead'}
            {1, 3, nil, nil, nil}
            {4, 1, 'f00d'}
            {4, 3, nil, nil, nil}
            {nil, 3, nil, 'closed', 'trailer'}
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

    it 'iterator(size) and receive(size)', ->
        bf = new 'dead--beef--dead--f00d--trailer'
        iter = bf\receiveuntil '--'
        receive = (size) -> bf\receive size
        for {fn, size, exp_n, exp_data, exp_err, exp_partial} in *{
            {iter, 2, 1, 'de'}
            {receive, 3, 1, 'ad-'}
            {iter, 4, 1, '-bee'}
            {receive, 1, 1, 'f'}
            {iter, 2, 1, ''}
            {iter, 2, 3, nil, nil, nil}
            {iter, 2, 1, 'de'}
            {receive, 4, 1, 'ad--'}
            {iter, 2, 1, 'f0'}
            {receive, 4, 1, '0d--'}
            {iter, 4, 1, 'trai'}
            {receive, 3, 1, 'ler'}
            {iter, 4, 3, nil, 'closed', ''}
            {iter, 4, 2, nil, 'closed'}
            {receive, 4, 2, nil, 'closed'}
        }
            n, data, err, partial = nargs fn size
            assert.are.equal exp_n, n
            assert.are.equal exp_data, data
            assert.are.equal exp_err, err
            assert.are.equal exp_partial, partial
