// vim: set colorcolumn=85
// vim: fdm=marker

#include "chipmunk/chipmunk.h"
#include "chipmunk/chipmunk_structs.h"

#include "mem_guard.h"

#include <assert.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

// Проверить указатель на текущее физическое пространство.
// Вызвать ошибку Lua в случае пустого указателя.
#define CHECK_SPACE \
if (!cur_space) {                                       \
    lua_pushstring(lua, "Space pointer is null.\n");    \
    lua_error(lua);                                     \
}                                                       \

typedef struct {
    int32_t regindex_ud;     // индекс userdata
    int32_t regindex_table;  // индекс для связанной таблицы
/*} num __attribute__((packed, aligned(2)));*/
} Parts;

#define SET_USER_DATA_UD(b, reg_index) \
    ((Parts*)(&b->userData))->regindex_ud = reg_index;

#define GET_USER_DATA_UD(b) ((Parts*)(&b->userData))->regindex_ud

#define SET_USER_DATA_TABLE(b, reg_index) \
    ((Parts*)(&b->userData))->regindex_table = reg_index;

#define GET_USER_DATA_TABLE(b) ((Parts*)(&b->userData))->regindex_table

cpShapeFilter ALL_FILTER = { 1, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES };

// Что делает этот фильтр?
#define GRABBABLE_MASK_BIT (1<<31)

cpShapeFilter GRAB_FILTER = {
    CP_NO_GROUP, 
    GRABBABLE_MASK_BIT, 
    GRABBABLE_MASK_BIT
};
cpShapeFilter NOT_GRABBABLE_FILTER = {
    CP_NO_GROUP, 
    // Что делает оператор ~ ? Побитовое отрицание?
    ~GRABBABLE_MASK_BIT, 
    // Что делает оператор ~ ? Побитовое отрицание?
    ~GRABBABLE_MASK_BIT
};

void print_userData(void *data) {
    int index_ud = ((Parts*)data)->regindex_ud;
    int index_table = ((Parts*)data)->regindex_table;
    printf("regindex_ud = %d, regindex_table = %d\n", index_ud, index_table);
}

void print_body_stat(cpBody *b) {
    printf("mass, inertia %f, %f \n", b->m, b->i);
    printf("cog (%f, %f)\n", b->cog.x, b->cog.y);
    printf("pos (%f, %f)\n", b->p.x, b->p.y);
    printf("vel (%f, %f)\n", b->v.x, b->v.y);
    printf("force (%f, %f)\n", b->f.x, b->f.y);
    printf("a %f\n", b->a);
    printf("w %f\n", b->w);
    printf("t %f\n", b->t);
}

static void stack_dump (lua_State *L) {
    int i;
    int top = lua_gettop(L);
    for (i = 1; i <= top; i++) { /* repeat for each level */
        int t = lua_type(L, i);
        switch (t) {
            case LUA_TSTRING: { /* strings */
                                  printf("’%s’", lua_tostring(L, i));
                                  break;
                              }
            case LUA_TBOOLEAN: { /* booleans */
                                   printf(lua_toboolean(L, i) ? "true" : "false");
                                   break;
                               }
            case LUA_TNUMBER: { /* numbers */
                                  printf("%g", lua_tonumber(L, i));
                                  break;
                              }
            default: { /* other values */
                         printf("%s", lua_typename(L, t));
                         break;
                     }
        }
        printf(" "); /* put a separator */
    }
    printf("\n"); /* end the listing */
}

static cpSpace *cur_space = NULL;

static int init_space(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expects 1 argument.\n");
        lua_error(lua);
    }

#ifdef DEBUG
    printf("init_space()\n");
    stack_dump(lua);
#endif

    cur_space = lua_newuserdata(lua, sizeof(cpSpace));

    // Дублирую значени userdata на стеке т.к. lua_ref() снимает одно значение
    // с верхушки.
    lua_pushvalue(lua, 2);

    SET_USER_DATA_UD(cur_space, luaL_ref(lua, LUA_REGISTRYINDEX));

#ifdef DEBUG
    printf("after ref\n");
    stack_dump();
#endif

    cpSpaceInit(cur_space);
    double damping = lua_tonumber(lua, 1);

    /*lua_pushlightuserdata(lua, cur_space);*/

	/*cpSpaceSetIterations(space, 30);*/
	/*cpSpaceSetGravity(space, cpv(0, -500));*/
	/*cpSpaceSetSleepTimeThreshold(space, 0.5f);*/
	/*cpSpaceSetCollisionSlop(space, 0.5f);*/
    cpSpaceSetDamping(cur_space, damping);

    return 1;
}

static void ConstraintFreeWrap(
        cpSpace *space, 
        cpConstraint *constraint, 
        void *data
) {
    lua_State *lua = (lua_State*)data;
    cpSpaceRemoveConstraint(space, constraint);
    luaL_unref(lua, LUA_REGISTRYINDEX, GET_USER_DATA_UD(constraint));
    /*cpConstraintFree(constraint);*/
}

struct PostCallbackData {
    cpSpace *space;
    lua_State *lua;
};

static void PostConstraintFree(
        cpConstraint *constraint,
        struct PostCallbackData *data
) {
    cpSpaceAddPostStepCallback(
            data->space, 
            (cpPostStepFunc)ConstraintFreeWrap, 
            constraint, 
            data->lua
    );
}

static void ShapeFreeWrap(cpSpace *space, cpShape *shape, void *unused){
    lua_State *lua = (lua_State*)unused;

	cpSpaceRemoveShape(space, shape);
    luaL_unref(lua, LUA_REGISTRYINDEX, GET_USER_DATA_UD(shape));
	/*cpShapeFree(shape);*/
}

static void PostShapeFree(cpShape *shape, struct PostCallbackData *data){
    cpSpaceAddPostStepCallback(
            data->space, 
            (cpPostStepFunc)ShapeFreeWrap, 
            shape, 
            data->lua
    );
}

static int free_space(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    cpSpace *space = (cpSpace*)lua_touserdata(lua, 1);

    struct PostCallbackData data = {
        .space = space,
        .lua = lua,
    };

    cpSpaceEachShape(space, (cpSpaceShapeIteratorFunc)PostShapeFree, &data);
    cpSpaceEachConstraint(
            space, (cpSpaceConstraintIteratorFunc)PostConstraintFree, space
    );

    luaL_unref(lua, LUA_REGISTRYINDEX, GET_USER_DATA_UD(space));
    /*cpSpaceFree(space);*/
}

/*#define DENSITY (1.0/10000.0)*/
#define DENSITY (1.0/10000.0)

// добавить трения для тел так, что-бы они останавливались после приложения
// импульса
static int new_body(lua_State *lua) {
    CHECK_SPACE;

    int top = lua_gettop(lua);
    if (top != 6) {
        lua_pushstring(lua, "Function should receive only 3 arguments.\n");
        lua_error(lua);
    }

    luaL_checktype(lua, 1, LUA_TSTRING); // type
    luaL_checktype(lua, 2, LUA_TNUMBER); // x pos
    luaL_checktype(lua, 3, LUA_TNUMBER); // y pos
    luaL_checktype(lua, 4, LUA_TNUMBER); // w in pixels
    luaL_checktype(lua, 5, LUA_TNUMBER); // h in pixels
    luaL_checktype(lua, 6, LUA_TTABLE);  // associated table

    const char *object_type = lua_tostring(lua, 1);
    if (strcmp(object_type, "tank") == 0) {
        printf("new tank\n");
    } else {
        char buf[64];
        snprintf(buf, 
                sizeof(buf), 
                "Unknown object type literal '%s'\n", 
                object_type);
        lua_pushstring(lua, buf);
        lua_error(lua);
    }

    cpVect pos = {
        .x = (int)lua_tonumber(lua, 2),
        .y = (int)lua_tonumber(lua, 3),
    };

    int w = (int)lua_tonumber(lua, 4);
    int h = (int)lua_tonumber(lua, 5);

    printf("new_body\n");
    stack_dump(lua);
    printf("------------------\n");

    // ссылка на табличку, связанную с телом
    int assoc_table_reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);

    cpBody *b = lua_newuserdata(lua, sizeof(cpBody));
    cpFloat mass = w * h * DENSITY;
    cpFloat moment = cpMomentForBox(mass, w, h);
    cpBodyInit(b, mass, moment);
    cpSpaceAddBody(cur_space, b);

    //TODO Проверить как работает дублирование верхнего значения на стеке
    lua_pushvalue(lua, lua_gettop(lua));
    int body_reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);

    printf("before shape ud\n");
    stack_dump(lua);
    printf("------------------\n");

    cpShape *shape = lua_newuserdata(lua, sizeof(cpPolyShape));
    SET_USER_DATA_UD(shape, luaL_ref(lua, LUA_REGISTRYINDEX));
    cpBoxShapeInit((cpPolyShape*)shape, b, w, h, 0.f);

    /*printf("shape_reg_index %d\n", shape_reg_index);*/
    /*printf("assoc_table_reg_index %d\n", assoc_table_reg_index);*/

    /*b->userData = assoc_table_reg_index;*/

    SET_USER_DATA_UD(b, body_reg_index);
    SET_USER_DATA_TABLE(b, assoc_table_reg_index);

    // Удалить все предшествующие возвращаемому значению элементы стека.
    // Не уверен в нужности вызова.
    /*for(int i = 0; i <= 5; i++) {*/
        /*lua_remove(lua, 1);*/
    /*}*/

    printf("after ref\n");
    stack_dump(lua);
    printf("------------------\n");

    /*cpShapeSetFriction(shape, 10000.);*/
    /*printf("shape friction: %f\n", cpShapeGetFriction(shape));*/
    /*cpShapeSetFriction(shape, 1);*/

    cpSpaceAddShape(cur_space, (cpShape*)shape);
    cpBodySetPosition(b, pos);

    print_body_stat(b);

    printf("before return\n");
    stack_dump(lua);

    return 1;
}

// Как обеспечить более быструю рисовку?
// Вариант решения - вызывать функцию обратного вызова только если с момента
// прошлого рисования произошло изменению положения, более чем на 0.5px
// Как хранить данные о прошлом положении?
void on_each_tank(cpBody *body, void *data) {
    lua_State *lua = (lua_State*)data;

    /*printf("------------------\n");*/
    /*print_body_stat(body);*/

    // TODO Убрать лишние операции со стеком, получать таблицу связанную с 
    // телом один раз.

    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)body->userData);*/
    /*lua_pushstring(lua, "id");*/
    /*lua_gettable(lua, -2);*/
    /*const char *id = lua_tostring(lua, -1);*/
    /*lua_remove(lua, -1);*/
    /*lua_remove(lua, -1);*/
    /*printf("tank id = %s\n", id);*/

    /*int table_reg_index = ((Parts*)(&body->userData))->table;*/
    int table_reg_index = GET_USER_DATA_TABLE(body);
    lua_rawgeti(lua, LUA_REGISTRYINDEX, table_reg_index);

    lua_pushstring(lua, "_prev_x");
    lua_gettable(lua, -2);
    double prev_x = lua_tonumber(lua, -1);
    lua_remove(lua, -1); // remove last result

    /*stackDump(lua);*/

    lua_pushstring(lua, "_prev_y");
    lua_gettable(lua, -2);
    double prev_y = lua_tonumber(lua, -1);
    lua_remove(lua, -1); // remove last result

    lua_remove(lua, -1); // body->userData table

    /*printf("prev_x, prev_y %.3f, %.3f \n", prev_x, prev_y);*/

    double epsilon = 0.001;
    double dx = fabs(prev_x - body->p.x);
    double dy = fabs(prev_y - body->p.y);

    if (dx > epsilon || dy > epsilon) {
        lua_pushvalue(lua, 1); // callback function
        lua_pushnumber(lua, body->p.x);
        lua_pushnumber(lua, body->p.y);
        lua_pushnumber(lua, body->a);
        lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)body->userData);
        lua_call(lua, 4, 0);
    }

    /*stackDump(lua);*/
    /*printf("---------------------------\n");*/

    lua_rawgeti(lua, LUA_REGISTRYINDEX, table_reg_index);

    lua_pushstring(lua, "_prev_x"); //key
    lua_pushnumber(lua, body->p.x); //value
    lua_settable(lua, -3);

    lua_pushstring(lua, "_prev_y"); //key
    lua_pushnumber(lua, body->p.y); //value
    lua_settable(lua, -3);

    lua_remove(lua, -1);

    /*stackDump(lua);*/
    /*printf("||||||||||||||||||||||||||||||||\n");*/

    /*printf("on_each_body\n");*/
}

void on_each_body(cpBody *body, void *data) {
    lua_State *lua = (lua_State*)data;

    lua_pushvalue(lua, 1); // callback function
    lua_pushnumber(lua, body->p.x);
    lua_pushnumber(lua, body->p.y);
    lua_pushnumber(lua, body->a);
    /*int table_reg_index = ((Parts*)(&body->userData))->table;*/

    int table_reg_index = GET_USER_DATA_TABLE(body);
    printf("table_reg_index = %d\n", table_reg_index);
    lua_rawgeti(lua, LUA_REGISTRYINDEX, table_reg_index);

    /*stackDump(lua);*/
    lua_call(lua, 4, 0);

    /*printf("on_each_body\n");*/
}

void print_space_info(cpSpace *space) {
    printf("iterations %d\n", space->iterations);
    printf("damping %f\n", space->damping);
    printf("data %p\n", space->userData);
    printf("curr_dt %f\n", space->curr_dt);
    printf("stamp %d\n", space->stamp);
}

static int query_all_tanks(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TFUNCTION);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Space pointer is null.\n");
        lua_error(lua);
    }

    assert(cur_space && "space is NULL");

    cpSpaceEachBody(cur_space, on_each_tank, lua);

    return 0;
}

static int query_all_shapes(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TFUNCTION);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Space pointer is null.\n");
        lua_error(lua);
    }

    /*printf("cur_space %p\n", cur_space);*/
    /*print_space_info(cur_space);*/
    assert(cur_space && "space is NULL");

    /*cpSpaceEachBody(cur_space, on_each_body, lua);*/

    return 0;
}

static int step(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TNUMBER);

    if (!cur_space) {
        lua_pushstring(lua, "Space pointer is null.\n");
        lua_error(lua);
    }

    double dt = lua_tonumber(lua, 1);
    /*printf("dt %f\n", dt);*/
    cpSpaceStep(cur_space, dt);

    return 0;
}

static int get_position(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_touserdata(lua, 1);
    lua_pushnumber(lua, b->p.x);
    lua_pushnumber(lua, b->p.y);
    lua_pushnumber(lua, b->a);

    return 3;
}

static int set_position(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 3) {
        lua_pushstring(lua, "Function expects 3 arguments.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_touserdata(lua, 1);
    double x = lua_tonumber(lua, 2);
    double y = lua_tonumber(lua, 3);
    cpVect pos = { .x = x, .y = y};
    /*printf("pos %f, %f\n", pos.x, pos.y);*/
    cpBodySetPosition(b, pos);

    print_body_stat(b);
    
    return 0;
}

static int apply_force(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    luaL_checktype(lua, 4, LUA_TNUMBER);
    luaL_checktype(lua, 5, LUA_TNUMBER);

    cpVect force = { 
        .x = lua_tonumber(lua, 2),
        .y = lua_tonumber(lua, 3),
    };

    cpVect point = { 
        .x = lua_tonumber(lua, 4),
        .y = lua_tonumber(lua, 5),
    };

    int top = lua_gettop(lua);
    if (top != 5) {
        lua_pushstring(lua, "Function expects 5 arguments.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_touserdata(lua, 1);

    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)b->userData);*/

    // {{{
    /*stack_dump(lua);*/
    /*printf("-----------------------\n");*/
    /*lua_pushstring(lua, "id");*/
    /*lua_gettable(lua, 6);*/
    /*stack_dump(lua);*/
    /*luaL_checktype(lua, 7, LUA_TNUMBER);*/
    /*int id = (int)lua_tonumber(lua, 7);*/
    // печатать порядковый номер объекта
    /*printf("id = %d\n", id);*/
    // }}}
    
    cpBodyApplyForceAtLocalPoint(b, force, point);

    return 0;
}

static int apply_impulse(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    luaL_checktype(lua, 4, LUA_TNUMBER);
    luaL_checktype(lua, 5, LUA_TNUMBER);

    cpVect impulse = { 
        .x = lua_tonumber(lua, 2),
        .y = lua_tonumber(lua, 3),
    };

    cpVect point = { 
        .x = lua_tonumber(lua, 4),
        .y = lua_tonumber(lua, 5),
    };

    int top = lua_gettop(lua);
    if (top != 5) {
        lua_pushstring(lua, "Function expect 5 arguments.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_touserdata(lua, 1);

    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)b->userData);*/

    // {{{
    /*stack_dump(lua);*/
    /*printf("-----------------------\n");*/
    /*lua_pushstring(lua, "id");*/
    /*lua_gettable(lua, 6);*/
    /*stack_dump(lua);*/
    /*luaL_checktype(lua, 7, LUA_TNUMBER);*/
    /*int id = (int)lua_tonumber(lua, 7);*/
    // печатать порядковый номер объекта
    /*printf("id = %d\n", id);*/
    // }}}
    
    cpBodyApplyImpulseAtLocalPoint(b, impulse, point);

    return 0;
}

static int new_static_segment(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TNUMBER);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    luaL_checktype(lua, 4, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 4) {
        lua_pushstring(lua, "Function expect 4 arguments.\n");
        lua_error(lua);
    }

    assert(cur_space && "space is NULL");

    cpVect p1 = { .x = lua_tonumber(lua, 1), .y = lua_tonumber(lua, 2), };
    cpVect p2 = { .x = lua_tonumber(lua, 3), .y = lua_tonumber(lua, 4), };

    cpBody *static_body = cpSpaceGetStaticBody(cur_space);

    /*cpBody *static_body = cpBodyNew(10000.f, 1.);*/
    /*cpSpaceAddBody(cur_space, static_body);*/

    cpShape *shape = lua_newuserdata(lua, sizeof(cpSegmentShape));
    lua_pushvalue(lua, 5);

    SET_USER_DATA_UD(shape, luaL_ref(lua, LUA_REGISTRYINDEX));

    cpSegmentShapeInit((cpSegmentShape*)shape, static_body, p1, p2, 0.0f);
    cpSpaceAddShape(cur_space, shape);
    cpShapeSetElasticity(shape, 1.0f);
    cpShapeSetFriction(shape, 1.0f);

    // что дает установка следующего фильтра?
    cpShapeSetFilter(shape, NOT_GRABBABLE_FILTER);

    /*lua_pushlightuserdata(lua, shape);*/

    return 1;
}

static int free_static_segment(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    assert(cur_space && "space is NULL");

    cpShape *shape = (cpShape*)lua_touserdata(lua, 1);
    cpSpaceRemoveShape(cur_space, shape);
    luaL_unref(
            lua, 
            LUA_REGISTRYINDEX, 
            ((Parts*)(&shape->userData))->regindex_ud
    );
    /*cpShapeFree(shape);*/

    return 0;
}

void on_segment_shape(cpBody *body, cpShape *shape, void *data) {
    lua_State *lua = (lua_State*)data;
    /*printf("on_segment_shape\n");*/
    /*printf("shape->klass = %d\n", shape->klass);*/
    if (shape->klass->type == CP_SEGMENT_SHAPE) {
        cpSegmentShape *seg = (cpSegmentShape*)shape;

        lua_pushvalue(lua, 1); // callback function
        lua_pushnumber(lua, seg->a.x);
        lua_pushnumber(lua, seg->a.y);
        lua_pushnumber(lua, seg->b.x);
        lua_pushnumber(lua, seg->b.y);
        lua_call(lua, 4, 0);
    }
}

static int draw_static_segments(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TFUNCTION);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    assert(cur_space && "space is NULL");
    cpBodyEachShape(cpSpaceGetStaticBody(cur_space), on_segment_shape, lua);

    return 0;
}

void on_point_query(
        cpShape *shape, 
        cpVect point, 
        cpFloat distance, 
        cpVect gradient, 
        void *data
) {
    lua_State *lua = (lua_State*)data;

    int index = ((Parts*)(&shape->userData))->regindex_ud;
    lua_rawgeti(lua, LUA_REGISTRYINDEX, index);
    /*lua_pushlightuserdata(lua, shape);*/

    lua_pushnumber(lua, point.x);
    lua_pushnumber(lua, point.y);
    lua_pushnumber(lua, distance);
    lua_pushnumber(lua, gradient.x);
    lua_pushnumber(lua, gradient.x);

    /*stack_dump(lua);*/
    /*printf("1111111111111111111");*/

    lua_call(lua, 6, 0);

    /*stack_dump(lua);*/
    /*printf("222222222222222");*/
}

// Вызывает функцию обратного вызова для фигур под данной точно.
// Не учитывает фильтры.
static int get_shape_under_point(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TNUMBER);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TFUNCTION);

    int top = lua_gettop(lua);
    if (top != 3) {
        lua_pushstring(lua, "Function expect 3 arguments.\n");
        lua_error(lua);
    }

    cpVect point = { 
        .x = lua_tonumber(lua, 1),
        .y = lua_tonumber(lua, 2),
    };

    assert(cur_space && "space is NULL");

    cpSpacePointQuery(cur_space, point, 0, ALL_FILTER, on_point_query, lua);

    return 0;
}

static int get_shape_body(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    
    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    // XXX возврат ?????

    return 1;
}

int get_body_stat(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expects 1 argument.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_touserdata(lua, 1);

    printf("get_body_stat()\n");
    print_body_stat(b);

    // масса
    lua_pushnumber(lua, b->m);
    // момент инерции
    lua_pushnumber(lua, b->i);

    // центр гравитации
    lua_pushnumber(lua, b->cog.x);
    lua_pushnumber(lua, b->cog.y);

    // положение
    lua_pushnumber(lua, b->p.x);
    lua_pushnumber(lua, b->p.y);

    // скорость
    lua_pushnumber(lua, b->v.x);
    lua_pushnumber(lua, b->v.y);

    // сила
    lua_pushnumber(lua, b->f.x);
    lua_pushnumber(lua, b->f.y);

    // угол
    lua_pushnumber(lua, b->a);
    // угловая скорость
    lua_pushnumber(lua, b->w);
    // крутящий момент
    lua_pushnumber(lua, b->t);

    cpVect p = cpBodyGetPosition(b);
    /*cpVect cog = cpBodyGetCenterOfGravity(b);*/
    /*cpVect v = cpBodyGetVelocity(b);*/

    /*printf("mass %f moment %f px %f py %f\n", */
            /*cpBodyGetMass(b), */
            /*cpBodyGetMoment(b),*/
            /*p.x, p.y);*/

    /*printf(*/
        /*"m %f, i %f, cog %f, cog %f, pos %f, pos %f, vel %f, vel %f, "*/
        /*"for %f, for %f, ang %f, w %f, tor %f\n",*/
        /*b->m, b->i, b->cog.x, b->cog.y, b->p.x, b->p.y, b->v.x, b->v.y, */
        /*b->f.x, b->f.y, b->a, b->w, b->t*/
    /*);*/


    return 13;
}

static int set_torque(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 2) {
        lua_pushstring(lua, "Function expects 2 arguments.\n");
        lua_error(lua);
    }

    cpBody *body = (cpBody*)lua_touserdata(lua, 1);
    double torque = lua_tonumber(lua, 2);

    cpBodySetTorque(body, torque);

    return 0;
}

static int get_body_type(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expects 1 argument.\n");
        lua_error(lua);
    }
    
    cpBody *body = (cpBody*)lua_touserdata(lua, 1);
    cpBodyType btype = cpBodyGetType(body);
    double type = -1.;

    if (btype == CP_BODY_TYPE_DYNAMIC)
        type = 1.;
    else if (btype == CP_BODY_TYPE_KINEMATIC)
        type = 2.;
    else if (btype == CP_BODY_TYPE_STATIC)
        type = 3.;

    lua_pushnumber(lua, type);

    return 1;
}

static int get_body_vel(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expects 1 argument.\n");
        lua_error(lua);
    }
    
    cpBody *body = (cpBody*)lua_touserdata(lua, 1);
    cpVect vel = cpBodyGetVelocity(body);

    lua_pushnumber(lua, vel.x);
    lua_pushnumber(lua, vel.y);

    return 2;
}

static int set_body_ang_vel(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 2) {
        lua_pushstring(lua, "Function expects 2 argument.\n");
        lua_error(lua);
    }
    
    cpBody *body = (cpBody*)lua_touserdata(lua, 1);
    double ang_vel = lua_tonumber(lua, 2);
    cpBodySetAngularVelocity(body, ang_vel);

    return 0;
}

static int get_body_ang_vel(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expects 1 argument.\n");
        lua_error(lua);
    }
    
    cpBody *body = (cpBody*)lua_touserdata(lua, 1);
    lua_pushnumber(lua, cpBodyGetAngularVelocity(body));

    return 1;
}

extern int luaopen_wrp(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // создать пространство
        {"init_space", init_space},
        // удалить пространство и все тела на нем
        {"free_space", free_space},
        // шаг симуляции
        {"step", step},

        // вызов функции для всех тел в текущем пространстве
        {"query_all_shapes", query_all_shapes},

        // вызов функции для всех тел в текущем пространстве
        {"query_all_tanks", query_all_tanks},

        // новое тело
        {"new_body", new_body},
        // установить положение тела
        {"set_position", set_position},
        // получить положение тела и угол поворота
        {"get_position", get_position},
        // придать импульс телу
        {"apply_impulse", apply_impulse},
        // приложить силу к телу
        {"apply_force", apply_force},
        // установить вращение тела
        {"set_torque", set_torque},
        {"get_body_type", get_body_type},
        // Возвращает скорость тела
        {"get_body_vel", get_body_vel},
        // Получить угловую скорость тела
        {"get_body_ang_vel", get_body_ang_vel},
        // Установить угловую скорость тела
        {"set_body_ang_vel", set_body_ang_vel},

        // добавить к статическому телу форму - отрезок
        {"new_static_segment", new_static_segment},
        // удалить фигуру статического тела и освободить ее память
        {"free_static_segment", free_static_segment},
        // обратный вызов функции для рисования всех сегментов
        {"draw_static_segments", draw_static_segments},

        // вызвать коллббэк для всех фигур под данной точкой
        {"get_shape_under_point", get_shape_under_point},
        // возвращает тело относящееся к фигуре
        {"get_shape_body", get_shape_body},

        // получить разную информацию по телу
        // используется для отладки
        {"get_body_stat", get_body_stat},

        {NULL, NULL}
    };

    luaL_register(lua, "wrapper", functions);
    printf("wrp module opened\n");
    return 1;
}
