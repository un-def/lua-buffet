import new from require 'buffet.resty'


describe 'send()', ->

    it 'should raise error if bad argument type', ->
        err_tpl = "bad argument #2 to 'send' (string, number, boolean, nil, or array table expected, got %s)"
        bf = new!
        ok, err = pcall bf.send, bf, ->
        assert.is.false, ok
        assert.are.equal err_tpl\format('function'), err
        f = io.tmpfile!
        ok, err = pcall bf.send, bf, f
        assert.is.false, ok
        assert.are.equal err_tpl\format('userdata'), err
        f\close!

    describe 'should raise error if non-array table:', ->
        for {msg, data} in *{
            {'non-number', {'foo', 'bar', key: 'baz'}}
            {'negative number', {'foo', 'bar', [-1]: 'baz'}}
            {'floating-point number', {'foo', 'bar', [3.001]: 'baz'}}
            {'non-number, nested', {'foo', {'bar', key: 'baz'}}}
            {'negative number, nested', {'foo', 'bar', {[-1]: 'baz'}}}
            {'floating-point number, nested', {'foo', 'bar', {[3.001]: 'baz'}}}
        }
            it msg, ->
                bf = new!
                ok, err = pcall bf.send, bf, data
                assert.is.false, ok
                assert.are.equal "bad argument #2 to 'send' (non-array table found)", err

    describe 'should raise error if bad value type in table:', ->
        for {bad_type, value} in *{
            {'boolean', true}
            {'nil', nil}
            {'function', ->}
        }
            it bad_type, ->
                tbl = {'foo', nil, 'bar'}
                tbl[2] = value
                bf = new!
                ok, err = pcall bf.send, bf, tbl
                assert.is.false, ok
                assert.are.equal "bad argument #2 to 'send' (bad data type %s found)"\format(bad_type), err

    it 'should return error if closed', ->
        bf = new!
        bf\close!
        n, sent, err = nargs bf\send 'foo'
        assert.are.equal 2, n
        assert.is.nil sent
        assert.are.equal 'closed', err

    it 'should store sent data in send buffer', ->
        bf = new!
        bf\send 'foo'
        bf\send 'bar'
        bf\send 'baz'
        assert.are.same bf._send_buffer, {'foo', 'bar', 'baz'}

    describe 'should cast non-string value to string:', ->
        for {msg, value, expected} in *{
            {'int', 5, '5'}
            {'float', 5.25, '5.25'}
            {'boolean', false, 'false'}
            {'nil', nil, 'nil'}
        }
            it msg, ->
                bf = new!
                n, sent = nargs bf\send value
                assert.are.equal 1, n
                assert.are.equal #expected, sent
                assert.are.equal expected, bf._send_buffer[1]

    it 'should flatten nested table', ->
        bf = new!
        n, sent = nargs bf\send {'alfa ', {'bravo ', {{'charlie '}, 'delta ', 'echo '}}, 'foxtrot ', 'golf'}
        assert.are.equal 1, n
        assert.are.equal 42, sent
        assert.are.equal 'alfa bravo charlie delta echo foxtrot golf', bf._send_buffer[1]

    it 'should flatten nested table with numbers', ->
        bf = new!
        n, sent = nargs bf\send {'foo', {1.23, {-432, 0.33}, 'bar', 'baz'}, 'qux'}
        assert.are.equal 1, n
        assert.are.equal 24, sent
        assert.are.equal 'foo1.23-4320.33barbazqux', bf._send_buffer[1]
