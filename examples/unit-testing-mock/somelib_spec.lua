local match = require('luassert.match')
local buffet = require('buffet.resty')
local somelib = require('somelib')

it('use the buffet object as a mock', function()
    local bf = buffet.new({
        'foo\n',
        '\n',
        'bar\n',
        'baz\n',
    })
    local res, err = somelib.read(bf, string.upper)
    assert.are.same({'FOO', '', 'BAR', 'BAZ'}, res)
    assert.is_nil(err)
end)

it('replace default connect method to test error handling', function()
    local bf = buffet.new('foo\nbar')
    bf.connect = function()
        return nil, 'connection refused'
    end
    local res, err = somelib.read(bf)
    assert.is_nil(res)
    assert.are.equal('connection error: connection refused', err)
end)

it('wrap default receive method to test error handling', function()
    local bf = buffet.new('foo\n\n\nbar\n')
    local orig_receive = bf.receive
    bf.receive = function(...)
        local data, err, partial = orig_receive(...)
        if err == 'closed' then
            err = 'timeout'
        end
        return data, err, partial
    end
    local res, err = somelib.read(bf)
    assert.are.same({'foo', '', '', 'bar'}, res)
    assert.are.equal('receive error: timeout', err)
end)

it('wrap the buffet object in luassert.mock to track calls', function()
    local bf = buffet.new('foo\nbar\nbaz')
    -- XXX: luassert doesn't mock inherited methods,
    -- so we cache them in the object
    bf.connect = bf.connect
    bf.receive = bf.receive
    bf.send = bf.send
    local m = mock(bf)
    local res = somelib.read(m)
    assert.are.same({'foo', 'bar', 'baz'}, res)
    assert.spy(m.connect).was.called_with(match._, 'example.com', 12345)
    assert.spy(m.receive).was.called(3)   -- LF count + 1
    assert.spy(m.receive).was.called_with(match._, '*l')
    assert.spy(m.send).was_not.called()
end)
