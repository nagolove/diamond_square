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

// FIXME Поддержка win32?
typedef struct {
    int32_t regindex_ud;     // индекс userdata
    int32_t regindex_table;  // индекс для связанной таблицы
} __attribute__((packed)) Parts;

#define SET_USER_DATA_UD(b, reg_index) \
    ((Parts*)(&b->userData))->regindex_ud = reg_index;

#define GET_USER_DATA_UD(b) ((Parts*)(&b->userData))->regindex_ud

#define SET_USER_DATA_TABLE(b, reg_index) \
    ((Parts*)(&b->userData))->regindex_table = reg_index;

#define GET_USER_DATA_TABLE(b) ((Parts*)(&b->userData))->regindex_table

cpShapeFilter ALL_FILTER = { 1, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES };

// Что делает этот фильтр?
#define GRABBABLE_MASK_BIT (1<<31)

#define LOG(...)        \
    term_color_set();   \
    printf(__VA_ARGS__);        \
    term_color_reset(); \

#define LOG_STACK_DUMP(lua) \
    term_color_set();       \
    print_stack_dump(lua);  \
    term_color_reset();     \

#define DENSITY (1.0/10000.0)

void uint64t_to_bitstr(uint64_t value, char *buf) {
    assert(buf && "buf should not be a nil");
    char *last = buf;

    union BitMap {
        struct {
            unsigned char _0: 1;
            unsigned char _1: 1;
            unsigned char _2: 1;
            unsigned char _3: 1;
            unsigned char _4: 1;
            unsigned char _5: 1;
            unsigned char _6: 1;
            unsigned char _7: 1;
        } b[8];
        uint64_t u;
    } bp = { .u = value, };

    for(int i = 0; i < sizeof(value); ++i) {
        last += sprintf(last, "%d", (int)bp.b[i]._0);
        last += sprintf(last, "%d", (int)bp.b[i]._1);
        last += sprintf(last, "%d", (int)bp.b[i]._2);
        last += sprintf(last, "%d", (int)bp.b[i]._3);
        last += sprintf(last, "%d", (int)bp.b[i]._4);
        last += sprintf(last, "%d", (int)bp.b[i]._5);
        last += sprintf(last, "%d", (int)bp.b[i]._6);
        last += sprintf(last, "%d", (int)bp.b[i]._7);
        last += sprintf(last, " ");
    }
}

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

void term_color_set() {
    // cyan color
    printf("\033[36m");
}

void term_color_reset() {
    printf("\033[0m");
}

void print_userData(void *data) {
    int index_ud = ((Parts*)&data)->regindex_ud;
    int index_table = ((Parts*)&data)->regindex_table;
    term_color_set();
    printf("regindex_ud = %d, regindex_table = %d\n", index_ud, index_table);
    term_color_reset();
}

/*
void print_body_stat(cpBody *b) {
    term_color_set();
    printf("mass, inertia %f, %f \n", b->m, b->i);
    printf("cog (%f, %f)\n", b->cog.x, b->cog.y);
    printf("pos (%f, %f)\n", b->p.x, b->p.y);
    printf("vel (%f, %f)\n", b->v.x, b->v.y);
    printf("force (%f, %f)\n", b->f.x, b->f.y);
    printf("a %f\n", b->a);
    printf("w %f\n", b->w);
    printf("t %f\n", b->t);
    term_color_reset();
}
*/

static const char *stack_dump(lua_State *lua) {
    static char ret[1024] = {0, };
    char *ptr = ret;
    int top = lua_gettop(lua);
    for (int i = 1; i <= top; i++) {
        int t = lua_type(lua, i);
        switch (t) {
            case LUA_TSTRING: 
                ptr += sprintf(ptr, "’%s’", lua_tostring(lua, i));
                break;
            case LUA_TBOOLEAN: 
                ptr += sprintf(ptr, lua_toboolean(lua, i) ? "true" : "false");
                break;
            case LUA_TNUMBER: 
                ptr += sprintf(ptr, "%g", lua_tonumber(lua, i));
                break;
            default: 
                ptr += sprintf(ptr, "%s", lua_typename(lua, t));
                break;
        }
        ptr += sprintf(ptr, " "); 
    }
    return ret;
}

static void print_stack_dump (lua_State *lua) {
    printf("%s\n", stack_dump(lua));
}

static cpSpace *cur_space = NULL;

static int init_space(lua_State *lua) {
    // [.. , damping]
    luaL_checktype(lua, 1, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expects 1 argument.\n");
        lua_error(lua);
    }

    LOG("init_space()\n");
    LOG_STACK_DUMP(lua);

    cur_space = lua_newuserdata(lua, sizeof(cpSpace)); // [.. , damping, {ud}]
    memset(cur_space, 0, sizeof(cpSpace));
    cpSpaceInit(cur_space);
    
    printf("stack 1\n");
    print_stack_dump(lua);

    luaL_getmetatable(lua, "_Space");
    // [.., damping, {ud}, {M}]
   
    printf("stack 2\n");
    print_stack_dump(lua);

    lua_setmetatable(lua, -2);
    // [... damping, {ud}]

    // Дублирую значени userdata на стеке т.к. lua_ref() снимает одно значение
    // с верхушки.
    lua_pushvalue(lua, 2); // [.. , damping, {ud}, {ud}]

    int index = luaL_ref(lua, LUA_REGISTRYINDEX); // [.., damping, {ud}]
    SET_USER_DATA_UD(cur_space, index);

    /*SET_USER_DATA_UD(cur_space, luaL_ref(lua, LUA_REGISTRYINDEX));*/
    /*printf("index %d\n", index);*/

    /*printf("userData %d\n", cur_space->userData);*/
    /*printf("ud %d\n", GET_USER_DATA_UD(cur_space));*/
    /*printf("table %d\n", GET_USER_DATA_UD(cur_space));*/

    print_userData(cur_space->userData);

    LOG_STACK_DUMP(lua);

    double damping = lua_tonumber(lua, 1);

    /*lua_pushlightuserdata(lua, cur_space);*/

	/*cpSpaceSetIterations(space, 30);*/
	/*cpSpaceSetGravity(space, cpv(0, -500));*/
	/*cpSpaceSetSleepTimeThreshold(space, 0.5f);*/
	/*cpSpaceSetCollisionSlop(space, 0.5f);*/

    cpSpaceSetDamping(cur_space, damping);

    printf("before return:\n");
    print_stack_dump(lua);

    return 1; // [.., damping, -> {ud}]
}

static void ConstraintFreeWrap(
        cpSpace *space, 
        cpConstraint *constraint, 
        void *data
) {
    lua_State *lua = (lua_State*)data;
    cpSpaceRemoveConstraint(space, constraint);
    int index = GET_USER_DATA_UD(constraint);
    luaL_unref(lua, LUA_REGISTRYINDEX, index);

#ifdef DEBUG
    LOG("constraint regindex_ud = %d\n", index);
#endif

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

    int index = GET_USER_DATA_UD(shape);
    luaL_unref(lua, LUA_REGISTRYINDEX, index);

#ifdef DEBUG
    LOG("constraint regindex_ud = %d\n", index);
#endif

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
    cpSpace *space = (cpSpace*)luaL_checkudata(lua, 1, "_Space");

    struct PostCallbackData data = {
        .space = space,
        .lua = lua,
    };

    cpSpaceEachShape(space, (cpSpaceShapeIteratorFunc)PostShapeFree, &data);
    cpSpaceEachConstraint(
            space, (cpSpaceConstraintIteratorFunc)PostConstraintFree, space
    );

    int index = GET_USER_DATA_UD(space);

    LOG("space regindex_ud = %d\n", index);

    luaL_unref(lua, LUA_REGISTRYINDEX, index);
    /*cpSpaceFree(space);*/
    return 0;
}

// добавить трения для тел так, что-бы они останавливались после приложения
// импульса
static int new_body(lua_State *lua) {
    // [.., type, x, y, w, h, assoc_table]
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

    /*LOG("pozition (%f, %f)\n", pos.x, pos.y);*/
    if (pos.x != pos.x || pos.y != pos.y ) {
        printf("NAN\n");
        abort();
    }

    int w = (int)lua_tonumber(lua, 4);
    int h = (int)lua_tonumber(lua, 5);

    /*printf("new_body\n");*/
    /*print_stack_dump(lua);*/
    /*printf("------------------\n");*/

    // [.., type, x, y, w, h, -> assoc_table]
    int assoc_table_reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);
    // [.., type, x, y, w, h]

    cpFloat mass = w * h * DENSITY;
    cpFloat moment = cpMomentForBox(mass, w, h);
    cpBody *b = lua_newuserdata(lua, sizeof(cpBody));
    cpBodyInit(b, mass, moment);
    // [.., type, x, y, w, h, {ud}]

    luaL_getmetatable(lua, "_Body");
    // [.., type, x, y, w, h, {ud}, {M}]
    lua_setmetatable(lua, -2);
    // [.., type, x, y, w, h, {ud}]

    cpSpaceAddBody(cur_space, b);

    //TODO Проверить как работает дублирование верхнего значения на стеке
    /*lua_pushvalue(lua, lua_gettop(lua));*/
    lua_pushvalue(lua, -1);
    // [.., type, x, y, w, h, {ud}, {ud}]
    
    int body_reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);
    // [.., type, x, y, w, h, {ud}]

    /*printf("before shape ud\n");*/
    /*print_stack_dump(lua);*/
    /*printf("------------------\n");*/

    cpShape *shape = lua_newuserdata(lua, sizeof(cpPolyShape));
    cpBoxShapeInit((cpPolyShape*)shape, b, w, h, 0.f);
    // [.., type, x, y, w, h, {ud}, {ud_shape}]
    SET_USER_DATA_UD(shape, luaL_ref(lua, LUA_REGISTRYINDEX));
    // [.., type, x, y, w, h, {ud}]

    SET_USER_DATA_UD(b, body_reg_index);
    SET_USER_DATA_TABLE(b, assoc_table_reg_index);

    /*LOG("after ref\n");*/
    /*print_stack_dump(lua);*/
    /*printf("------------------\n");*/

    /*cpShapeSetFriction(shape, 10000.);*/
    /*printf("shape friction: %f\n", cpShapeGetFriction(shape));*/
    /*cpShapeSetFriction(shape, 1);*/

    cpSpaceAddShape(cur_space, (cpShape*)shape);
    cpBodySetPosition(b, pos);

    // XXX Debuggig only
    /*cpBodySetVelocity(b, cpvzero);*/
    /*b->cog = cpvzero;*/

    /*print_body_stat(b);*/

    /*printf("before return\n");*/
    /*print_stack_dump(lua);*/

    // Удалить все предшествующие возвращаемому значению элементы стека.
    // Не уверен в нужности вызова.
    /*printf("lua_gettop() = %d\n", lua_gettop(lua));*/

    top = lua_gettop(lua);
    for(int i = 0; i <= top - 2; i++) {
        lua_remove(lua, 1);
        print_stack_dump(lua);
    }
    // [.., {ud}]

    /*printf("-----------------------\n");*/
    /*print_stack_dump(lua);*/

    // [.., -> {ud}]
    return 1;
}

// Как обеспечить более быструю рисовку?
// Вариант решения - вызывать функцию обратного вызова только если с момента
// прошлого рисования произошло изменению положения, более чем на 0.5px
// Как хранить данные о прошлом положении?
void on_each_tank(cpBody *body, void *data) {
    lua_State *lua = (lua_State*)data;

    // TODO Убрать лишние операции со стеком, получать таблицу связанную с 
    // телом один раз.

    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)body->userData);*/
    /*lua_pushstring(lua, "id");*/
    /*lua_gettable(lua, -2);*/
    /*const char *id = lua_tostring(lua, -1);*/
    /*lua_remove(lua, -1);*/
    /*lua_remove(lua, -1);*/
    /*printf("tank id = %s\n", id);*/

    int table_reg_index = GET_USER_DATA_TABLE(body);

    /*LOG("table_reg_index %d\n", table_reg_index);*/

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
        lua_rawgeti(lua, LUA_REGISTRYINDEX, GET_USER_DATA_TABLE(body));
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
    CHECK_SPACE;
    luaL_checktype(lua, 1, LUA_TFUNCTION);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

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
    /*print_stack_dump(lua);*/
    /*printf("exit(2)\n");*/
    /*exit(2);*/

    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    // Как проверить действительный тип данных?
    // Можно передать не тот тип userdata, а ошибки не произойдет.
    cpBody *b = (cpBody*)luaL_checkudata(lua, 1, "_Body");
    /*printf("b %p\n", b);*/
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

    cpBody *b = (cpBody*)luaL_checkudata(lua, 1, "_Body");
    double x = lua_tonumber(lua, 2);
    double y = lua_tonumber(lua, 3);
    cpVect pos = { .x = x, .y = y};
    /*printf("pos %f, %f\n", pos.x, pos.y);*/
    cpBodySetPosition(b, pos);

    /*print_body_stat(b);*/
    
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

    cpBody *b = (cpBody*)luaL_checkudata(lua, 1, "_Body");

    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)b->userData);*/

    // {{{
    /*print_stack_dump(lua);*/
    /*printf("-----------------------\n");*/
    /*lua_pushstring(lua, "id");*/
    /*lua_gettable(lua, 6);*/
    /*print_stack_dump(lua);*/
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

    cpBody *b = (cpBody*)luaL_checkudata(lua, 1, "_Body");

    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)b->userData);*/

    // {{{
    /*print_stack_dump(lua);*/
    /*printf("-----------------------\n");*/
    /*lua_pushstring(lua, "id");*/
    /*lua_gettable(lua, 6);*/
    /*print_stack_dump(lua);*/
    /*luaL_checktype(lua, 7, LUA_TNUMBER);*/
    /*int id = (int)lua_tonumber(lua, 7);*/
    // печатать порядковый номер объекта
    /*printf("id = %d\n", id);*/
    // }}}
    
    cpBodyApplyImpulseAtLocalPoint(b, impulse, point);

    return 0;
}

static int new_static_segment(lua_State *lua) {
    // [.., x1, y1, x2, y2]
    luaL_checktype(lua, 1, LUA_TNUMBER);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    luaL_checktype(lua, 4, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 4) {
        lua_pushstring(lua, "Function expect 4 arguments.\n");
        lua_error(lua);
    }

    CHECK_SPACE;

    cpVect p1 = { .x = lua_tonumber(lua, 1), .y = lua_tonumber(lua, 2), };
    cpVect p2 = { .x = lua_tonumber(lua, 3), .y = lua_tonumber(lua, 4), };

    cpBody *static_body = cpSpaceGetStaticBody(cur_space);

    /*cpBody *static_body = cpBodyNew(10000.f, 1.);*/
    /*cpSpaceAddBody(cur_space, static_body);*/

    cpShape *shape = lua_newuserdata(lua, sizeof(cpSegmentShape));
    cpSegmentShapeInit((cpSegmentShape*)shape, static_body, p1, p2, 0.0f);

    // [.., x1, y1, x2, y2, ud]
    luaL_getmetatable(lua, "_Segment");
    // [.., x1, y1, x2, y2, ud, M]
    lua_setmetatable(lua, -2);
    // [.., x1, y1, x2, y2, ud]
    lua_pushvalue(lua, -1);
    // [.., x1, y1, x2, y2, ud, ud]
    SET_USER_DATA_UD(shape, luaL_ref(lua, LUA_REGISTRYINDEX));
    // [.., x1, y1, x2, y2, ud]

    cpSpaceAddShape(cur_space, shape);
    cpShapeSetElasticity(shape, 1.0f);
    cpShapeSetFriction(shape, 1.0f);

    // что дает установка следующего фильтра?
    cpShapeSetFilter(shape, NOT_GRABBABLE_FILTER);

    /*lua_pushlightuserdata(lua, shape);*/

    // [.., x1, y1, x2, y2, -> ud]
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

    cpShape *shape = (cpShape*)luaL_checkudata(lua, 1, "_Segment");
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

    CHECK_SPACE;

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

    // XXX Костыли или нет? Функция иногда вызывается с пустой фигурой.
    if (!shape) {
        return;
    }

    // TODO Использовать тело вместо формы в lua коллбэке 
    // cpBody *b = shape->body;

    LOG("stack 1: [%s]\n", stack_dump(lua));

    /*int index = ((Parts*)(&shape->userData))->regindex_ud;*/
    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, index);*/

    lua_rawgeti(lua, LUA_REGISTRYINDEX, GET_USER_DATA_UD(shape));
    LOG("stack 2: [%s]\n", stack_dump(lua));

    if (lua_isnil(lua, -1)) {
        return;
    }

    printf("shape->userData = %p\n", shape->userData);
    printf("ud %d\n", GET_USER_DATA_UD(shape));
    printf("table %d\n", GET_USER_DATA_TABLE(shape));

    /*lua_getmetatable(lua, -1);*/
    // print(REGISTRY[ud])
    /*lua_rawget(lua, LUA_REGISTRYINDEX);*/
    LOG("stack 3: [%s]\n", stack_dump(lua));

    void *ud = luaL_checkudata(lua, -1, "_Shape");
    LOG("stack 4: [%s]\n", stack_dump(lua));
    /*void *ud = lua_touserdata(lua, lua_gettop(lua));*/
    if (!ud) {
        lua_pushstring(lua, "no shape\n");
        lua_error(lua);
    }

    /*lua_pushlightuserdata(lua, shape);*/

    lua_pushnumber(lua, point.x);
    lua_pushnumber(lua, point.y);
    lua_pushnumber(lua, distance);
    lua_pushnumber(lua, gradient.x);
    lua_pushnumber(lua, gradient.x);

    /*print_stack_dump(lua);*/
    /*printf("1111111111111111111");*/

    lua_call(lua, -6, 0);

    /*print_stack_dump(lua);*/
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
        lua_pushstring(lua, "Function expects 3 arguments.\n");
        lua_error(lua);
    }

    CHECK_SPACE;

    cpVect point = { 
        .x = lua_tonumber(lua, 1),
        .y = lua_tonumber(lua, 2),
    };
    cpSpacePointQuery(cur_space, point, 0, ALL_FILTER, on_point_query, lua);

    return 0;
}

void print_shape_filter(cpShapeFilter filter) {
    printf("sizeof(cpGroup) = %ld\n", sizeof(cpGroup));
    printf("sizeof(cpBitmask) = %ld\n", sizeof(cpBitmask));
    LOG("cpShapeFilter {\n");

    /*LOG("   group       %u\n", filter.group);*/
    /*LOG("   categories  %s\n", categories);*/
    /*LOG("   mask        %s\n", mask);*/

    LOG("}\n");
}

static int shape_print_filter(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    cpShape *shape = (cpShape*)luaL_checkudata(lua, 1, "_Shape");
    print_shape_filter(shape->filter);

    return 0;
}

static int get_shape_body(lua_State *lua) {
    // [.., shape]
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    
    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    LOG("get_shape_body: [%s]\n", stack_dump(lua));
    exit(20);

    cpShape *shape = luaL_checkudata(lua, 1, "_Shape");
    lua_rawgeti(lua, LUA_REGISTRYINDEX, GET_USER_DATA_UD(shape->body));
    // [.., -> ud]

    LOG("return get_shape_body: [%s]\n", stack_dump(lua));
    return 1;
}

int get_body_stat(lua_State *lua) {
    printf("get_body_stat() %s\n", stack_dump(lua));
    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expects 1 argument.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)luaL_checkudata(lua, 1, "_Body");

    /*printf("get_body_stat()\n");*/
    /*print_body_stat(b);*/

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

    if (isnan(b->p.x) || isnan(b->p.y)) {
        lua_pushstring(lua, "Position vector component hash NaN value.\n");
        lua_error(lua);
    }

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

    /*cpVect p = cpBodyGetPosition(b);*/
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

    printf("return from get_body_stat() %s\n", stack_dump(lua));
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

    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Body");
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
    
    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Body");
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
    
    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Body");
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
    
    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Body");
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
    
    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Body");
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
        {"shape_print_filter", shape_print_filter},

        {NULL, NULL}
    };

    luaL_newmetatable(lua, "_Body");
    luaL_newmetatable(lua, "_Shape");
    luaL_newmetatable(lua, "_Space");
    /*luaL_newmetatable(lua, "_Segment");*/

    luaL_register(lua, "wrapper", functions);
    printf("wrp module opened\n");
    return 1;
}
