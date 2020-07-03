std = 'min'
exclude_files = {
    'examples/**/modules',
}
files['**/*_spec.lua'] = {
    std = '+busted',
}
files['examples/resty-chunked-formdata'] = {
    std = 'ngx_lua',
}
