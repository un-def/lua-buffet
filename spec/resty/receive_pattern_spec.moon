import new from require 'buffet.resty'
import is_closed from require 'buffet'


get_input_iterator = (tbl) ->
    index = 0
    ->
        index += 1
        tbl[index]


describe 'receive(pattern)', ->

    for {pattern, msg} in *{
        {nil, 'nil'}
        {'foo', 'unsupported string pattern'}
        {false, 'boolean'}
        {{}, 'table'}
    }
        it 'should raise error if bad pattern: ' .. msg, ->
            bf = new 'deadbeef'
            ok, err = pcall bf\receive, pattern
            assert.is.false, ok
            assert.are.equal "bad argument #2 to 'receive' (bad pattern argument)", err

        it 'should ignore bad pattern if not connected: ' .. msg, ->
            bf = new 'deadbeef'
            bf\close!
            n, data, err = nargs bf\receive pattern
            assert.are.equal 2, n
            assert.is.nil data
            assert.are.equal 'closed', err

describe "receive('*a')", ->

    describe 'should return all data at once', ->
        for {input, msg} in *{
            {'dead\rbeef\r\ndead\rf00d\r\n', 'from string'}
            {{'dead', '\rbeef\r\nde', '', 'ad\rf00d', '\r', '\n'}, 'from table'}
        }
            it msg, ->
                bf = new input
                n, data = nargs bf\receive '*a'
                assert.are.equal 1, n
                assert.are.equal 'dead\rbeef\r\ndead\rf00d\r\n', data
                for _ = 1, 2
                    n, data = nargs bf\receive '*a'
                    assert.are.equal 1, n
                    assert.are.equal '', data

    it 'should return empty string if there are no data', ->
        bf = new 'deadbeef'
        bf\receive '*a'
        for _ = 1, 2
            n, data = nargs bf\receive '*a'
            assert.are.equal 1, n
            assert.are.equal '', data

    it 'should not close connection', ->
        bf = new 'deadbeef'
        bf\receive '*a'
        assert.is.false is_closed bf

    it 'should return error if closed', ->
        bf = new 'deadbeef'
        bf\close!
        for _ = 1, 2
            n, data, err = nargs bf\receive '*a'
            assert.are.equal 2, n
            assert.is.nil data
            assert.are.equal 'closed', err

for {msg, fn} in *{
    {'receive(*l)', (bf) -> bf\receive '*l'}
    {'receive()', (bf) -> bf\receive!}
}
    describe msg, ->

        describe 'without trailing newline', ->
            input_string = '\r\r\r\n\rdead\n\r\nbeef\r\ndead\rf00d\r'
            input_table = {'', '\r\r\r\n\rde', 'ad\n', '\r\nbeef\r', '\ndead\rf00d\r'}
            input_iterator = get_input_iterator input_table
            for {input, msg_suffix} in *{
                {input_string, 'from string'}
                {input_table, 'from table'}
                {input_iterator, 'from iterator'}
            }
                it msg_suffix, ->
                    bf = new input
                    for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, ''}
                        {1, 'dead'}
                        {1, ''}
                        {1, 'beef'}
                        {3, nil, 'closed', 'deadf00d'}
                        {2, nil, 'closed'}
                    }
                        n, data, err, partial = nargs fn bf
                        assert.are.equal exp_n, n
                        assert.are.equal exp_data, data
                        assert.are.equal exp_err, err
                        assert.are.equal exp_partial, partial

        describe 'with trailing newline', ->
            input_string = 'dead\n\r\nbeef\ndead\rf00d\n'
            input_table = {'dead', '\n\r', '\nbeef\nde', 'ad\rf0', '0d\n'}
            input_iterator = get_input_iterator input_table
            for {input, msg_suffix} in *{
                {input_string, 'from string'}
                {input_table, 'from table'}
                {input_iterator, 'from iterator'}
            }
                it msg_suffix, ->
                    bf = new input
                    for {exp_n, exp_data, exp_err, exp_partial} in *{
                        {1, 'dead'}
                        {1, ''}
                        {1, 'beef'}
                        {1, 'deadf00d'}
                        {3, nil, 'closed', ''}
                        {2, nil, 'closed'}
                    }
                        n, data, err, partial = nargs fn bf
                        assert.are.equal exp_n, n
                        assert.are.equal exp_data, data
                        assert.are.equal exp_err, err
                        assert.are.equal exp_partial, partial

        it 'should return error if closed', ->
            bf = new 'deadbeef'
            bf\close!
            for _ = 1, 2
                n, data, err = nargs bf\receive '*l'
                assert.are.equal 2, n
                assert.is.nil data
                assert.are.equal 'closed', err
