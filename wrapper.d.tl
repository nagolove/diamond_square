global record Wrapper
    average: function(...:any): number
    each_body: function(function(iter_num: integer), call_count: integer)
    init_space: function(space: any)
end

return Wrapper
