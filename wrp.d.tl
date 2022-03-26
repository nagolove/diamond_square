
local record Wrapper
    record Shape end
    record Space end
    record Body end

    init_space: function(damping: number): Space
    free_space: function(Space)
    step: function(dt: number)

    type EachSegmentCallback = function(x1: number, y1: number, x2: number, y2: number)
    type EachBodyCallback = function(x: number, y: number, angle: number, obj: any)

    enum ObjectType
        "tank"
    end

    query_all_shapes: function(EachBodyCallback)
    query_all_tanks: function(EachBodyCallback)

    -- Создать поли-тело данной ширины и высоты, прикрепив к нему таблицу.
    -- Нужно указывать тип тела из перечисление ObjectType для соблюдений 
    -- внутренней логики работы модуля wrapper
    new_body: function(
        type: ObjectType, 
        xpos: number, ypos: number,
        w: number, h: number, 
        self: table
    ): Body

    -- Установить положение тела
    set_position: function(b: Body, x: number, y: number)
    -- Получить положение тела и его угол поворота
    get_position: function(b: Body): number, number, number
    -- Приложить импульс к данному телу в определенной точке
    apply_impulse: function(b: Body, ix: number, iy: number, px: number, py: number)
    -- Приложить силу к данному телу в определенной точке
    apply_force: function(b: Body, fx: number, fy: number, px: number, py: number)
    -- Установить вращение тела
    set_torque: function(Body, torque: number)
    -- Узнать тип тела - динамический(1), кинематический(2) или статический(3)
    get_body_type: function(Body): integer
    -- Получить скорость тела
    get_body_vel: function(Body): number, number
    -- Получить угловую скорость тела
    get_body_ang_vel: function(Body): number
    -- Установить угловую скорость тела
    set_body_ang_vel: function(Body, w: number)

    -- Создать новый сегмент. Сегмент тонкий(не имеет толщины) и крепится к
    -- статичному телу пространства
    new_static_segment: function(x1: number, y1: number, x2: number, y2: number): Shape
    -- Удаляет и освобождает память о фигуре
    free_static_segment: function(Shape)

    draw_static_segments: function(EachSegmentCallback)

    type EachShape = function(
        shape: Shape, 
        px: number, 
        py: number, 
        distance: number,
        gradx: number,
        grady: number)

    -- Обратный вызов функции для фигур в данной точке
    get_shape_under_point: function(x: number, y: number, cb: EachShape)

    -- Возвращает тело данной фигуры
    get_shape_body: function(Shape): Body

    -- Возвращает данные о физическом теле.
    -- Масса, момент инерции, центр гравитации(x, y), положение(x, y), 
    -- скорость(x, y), сила под действием которой находится тело(x, y), 
    -- угол, угловая скорость, крутящий момент.
    get_body_stat: function(Body): number, number, number, number, number, number, number, number, number, number, number, number, number
    shape_print_filter: function(Shape)
end

return Wrapper
