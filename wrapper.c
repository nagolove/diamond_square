// vim: set colorcolumn=85
// vim: fdm=marker

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>

#include "chipmunk/chipmunk.h"
#include "chipmunk/chipmunk_structs.h"

#include "lua_tools.h"

// Проверить указатель на текущее физическое пространство.
// Вызвать ошибку Lua в случае пустого указателя.
#define CHECK_SPACE \
if (!cur_space) {                                       \
    lua_pushstring(lua, "cur_space pointer is null.\n");\
    lua_error(lua);                                     \
}                                                       \

typedef enum {
    OBJT_TANK,
    OBJT_BULLET,
    OBJT_SEGMENT, // Отрезок, ограничивающиц движение
} ObjType;

typedef struct {
    ObjType type;
} Object;

typedef struct {
    Object obj;

    // Не дает башне вертется при движении шасси.
    cpConstraint *turret_motor;
    // Отключает turret_motor на время поворота башни.
    bool has_turret_motor;

    cpBody *body;
    cpBody *turret;

    // Точка к которой прикладывается сила для поворота башни.
    cpVect turret_rot_point;

    // индекс userdata на табличку связанную с танком
    int assoc_table_reg_index;
    // индекс userdata на танк
    int reg_index;
} Tank;

typedef struct {
    Object obj;
} Bullet;

typedef struct {
    Object obj;
    int assoc_table_reg_index;
} Segment;

typedef struct {
    cpSpace *space;
    int reg_index;
} Space;

static Space *cur_space = NULL;

cpShapeFilter ALL_FILTER = { 
    CP_NO_GROUP, 
    CP_ALL_CATEGORIES, 
    CP_ALL_CATEGORIES 
};

// Что делает этот фильтр?
#define GRABBABLE_MASK_BIT (1<<31)

#ifdef DEBUG

#define LOG(...)        \
    term_color_set();   \
    printf(__VA_ARGS__);        \
    term_color_reset(); \

#define LOG_STACK_DUMP(lua) \
    term_color_set();       \
    print_stack_dump(lua);  \
    term_color_reset();     \

#else
#define LOG(...) \
    do {} while(0)
#define LOG_STACK_DUMP(lua) \
    do {} while(0)
#endif

#define DENSITY (1.0/4000.0)

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

/*
void print_userData(void *data) {
    int index_ud = ((Parts*)&data)->regindex_ud;
    int index_table = ((Parts*)&data)->regindex_table;
    term_color_set();
    printf("regindex_ud = %d, regindex_table = %d\n", index_ud, index_table);
    term_color_reset();
}
*/

void print_body_stat(cpBody *b) {
    term_color_set();
    printf("body %p {\n", b);
    printf("    mass, inertia %f, %f \n", b->m, b->i);
    printf("    cog (%f, %f)\n", b->cog.x, b->cog.y);
    printf("    pos (%f, %f)\n", b->p.x, b->p.y);
    printf("    vel (%f, %f)\n", b->v.x, b->v.y);
    printf("    force (%f, %f)\n", b->f.x, b->f.y);
    printf("    a %f\n", b->a);
    printf("    w %f\n", b->w);
    printf("    t %f\n", b->t);
    printf("}\n");
    term_color_reset();
}

#ifdef DEBUG
static void print_stack_dump(lua_State *lua) {
    printf("[%s]\n", stack_dump(lua));
}
#endif

void check_argsnum(lua_State *lua, int num) {
    static char formated_msg[64] = {0, };
    const char *msg = "Function should receive only %d argument(s).\n";
    snprintf(formated_msg, sizeof(formated_msg), msg, num);

    int top = lua_gettop(lua);
    if (top != num) {
        lua_pushstring(lua, formated_msg);
        lua_error(lua);
    }
}

static int space_new(lua_State *lua) {
    // [.. , damping]
    luaL_checktype(lua, 1, LUA_TNUMBER);
    check_argsnum(lua, 1);

    LOG("space_new\n");
    LOG_STACK_DUMP(lua);

    Space *space = lua_newuserdata(lua, sizeof(Space)); 
    // [.. , damping, {ud}]
    memset(space, 0, sizeof(Space));

    luaL_getmetatable(lua, "_Space");
    // [.., damping, {ud}, {M}]
    lua_setmetatable(lua, -2);
    // [... damping, {ud}]

    space->space = cpSpaceNew();

    // Дублирую значени userdata на стеке т.к. lua_ref() снимает одно значение
    // с верхушки.
    lua_pushvalue(lua, 2); 
    // [.. , damping, {ud}, {ud}]
    space->reg_index = luaL_ref(lua, LUA_REGISTRYINDEX); 
    // [.., damping, {ud}]
    double damping = luaL_checknumber(lua, 1);

	/*cpSpaceSetIterations(space, 30);*/
	/*cpSpaceSetGravity(space, cpv(0, -500));*/
	/*cpSpaceSetSleepTimeThreshold(space, 0.5f);*/
	/*cpSpaceSetCollisionSlop(space, 0.5f);*/

    cpSpaceSetDamping(space->space, damping);

    LOG_STACK_DUMP(lua);

     // [.., damping, -> {ud}]
    return 1;
}

static void ConstraintFreeWrap(
        cpSpace *space, 
        cpConstraint *constraint, 
        void *data
) {
    /*lua_State *lua = (lua_State*)data;*/
    cpSpaceRemoveConstraint(space, constraint);
    /*int index = GET_USER_DATA_UD(constraint);*/
    /*luaL_unref(lua, LUA_REGISTRYINDEX, index);*/
    cpConstraintFree(constraint);
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
	cpSpaceRemoveShape(space, shape);
    cpShapeFree(shape);
}

static void PostShapeFree(cpShape *shape, struct PostCallbackData *data){
    cpSpaceAddPostStepCallback(
            data->space, 
            (cpPostStepFunc)ShapeFreeWrap, 
            shape, 
            data->lua
    );
}

// Как грамотно удалять пространство?
static int space_free(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    Space *space = (Space*)luaL_checkudata(lua, 1, "_Space");

    struct PostCallbackData data = {
        .space = space->space,
        .lua = lua,
    };

    cpSpaceEachShape(
            space->space, (cpSpaceShapeIteratorFunc)PostShapeFree, &data
    );
    cpSpaceEachConstraint(
            space->space, (cpSpaceConstraintIteratorFunc)PostConstraintFree, 
            space
    );

    /*int index = GET_USER_DATA_UD(space);*/
    /*LOG("space regindex_ud = %d\n", index);*/
    /*luaL_unref(lua, LUA_REGISTRYINDEX, index);*/
    luaL_unref(lua, LUA_REGISTRYINDEX, space->reg_index);
    cpSpaceFree(space->space);
    return 0;
}

void tank_check_type(lua_State *lua, 
        const char *given, 
        const char *should_be
) {
    if (strcmp(given, should_be) != 0) {
        char buf[64] = {0, };
        snprintf(buf, 
                sizeof(buf), 
                "Unknown object type literal '%s'\n", 
                given);
        lua_pushstring(lua, buf);
        lua_error(lua);
    }
}

// Кладет в стек таблицу с вершинами из фигуры вида {x1, y1, x2, y2, ..}
/*#define PUSH_SHAPE_VERTICES*/
void push_shape_vertices(cpBody *body, cpShape *shape, void *data) {
    lua_State *lua = data;
    assert(shape);
#ifdef PUSH_SHAPE_VERTICES
    LOG("push_shape_vertices\n");
#endif
    if (shape->klass->type != CP_POLY_SHAPE) {
        return;
    }
    lua_newtable(lua);
    int top = lua_gettop(lua);
    int index = 1;
    for (int i = 0; i < cpPolyShapeGetCount(shape); ++i) {
        cpVect vert = cpPolyShapeGetVert(shape, i);
        lua_pushnumber(lua, vert.x);
        lua_rawseti(lua, top, index++);
        lua_pushnumber(lua, vert.y);
        lua_rawseti(lua, top, index++);
    }
}
#undef PUSH_SHAPE_VERTICES

/*
Создать физическое тело для башни.
Функция оставляет Lua стек без изменений.
В связанной с танком таблице устанавливается поле _turret с userdata башни.
*/
#define TANK_TURRET_NEW
void tank_turret_new(
        lua_State *lua, 
        Tank *tank, 
        int collision_group, 
        int init_table_index
) {

#ifdef TANK_TURRET_NEW
    LOG("tank_turret_new: [%s]\n", stack_dump(lua));
#endif
    // [.., tank_ud]
    lua_pushvalue(lua, init_table_index);
    // [.., tank_ud, init_table]

    cpFloat mass = 0.0001;
    cpFloat w = 0., h = 0;

    lua_pushstring(lua, "turret_w");
    lua_gettable(lua, -2);
    w = (int)lua_tonumber(lua, -1);
    if (lua_isnil(lua, -1)) {
        LOG("tank_turret_new: turret_w is nil\n");
        exit(1);
    }
    lua_remove(lua, -1);

    lua_pushstring(lua, "turret_h");
    lua_gettable(lua, -2);
    h = (int)lua_tonumber(lua, -1);
    if (lua_isnil(lua, -1)) {
        LOG("tank_turret_new: turret_h is nil\n");
        exit(1);
    }
    lua_remove(lua, -1);

    LOG("tank_turret_new: w = %f\n", w);
    LOG("tank_turret_new: h = %f\n", h);

    cpFloat hw = w / 2.0, hh = h / 2.0;
    cpVect verts[] = {
        {w - hw, h - hh},
        {w - hw, 0. - hh},
        {0. - hw, 0. - hh},
        {0. - hw, h - hh},
    };
    int verts_num = sizeof(verts) / sizeof(verts[0]);

    cpVect poly_offset = cpvzero;
    cpFloat moment = cpMomentForPoly(
            mass, verts_num, 
            verts, poly_offset, 
            0.0f
    );

#ifdef TANK_TURRET_NEW
    LOG("tank_turret_new: turret moment %f\n", moment);
#endif

    tank->turret = cpBodyNew(mass, moment);
    tank->turret->userData = NULL;

    cpShape *shape = cpPolyShapeNew(
            tank->turret, 
            verts_num, 
            verts, cpTransformIdentity, 
            0.f
    );
    shape->userData = NULL;

    cpShapeFilter filter = {
        collision_group, 
        CP_ALL_CATEGORIES, 
        CP_ALL_CATEGORIES
    };
    cpShapeSetFilter(shape, filter);

    cpVect turret_offset = { .x = 0., .y = 0. };

    lua_pushstring(lua, "turret_dx");
    lua_gettable(lua, -2);
    turret_offset.x = (int)lua_tonumber(lua, -1);
    if (lua_isnil(lua, -1)) {
        LOG("tank_turret_new: turret_dx is nil\n");
        exit(1);
    }
    lua_remove(lua, -1);

    lua_pushstring(lua, "turret_dy");
    lua_gettable(lua, -2);
    turret_offset.y = (int)lua_tonumber(lua, -1);
    if (lua_isnil(lua, -1)) {
        LOG("tank_turret_new: turret_dy is nil\n");
        exit(1);
    }
    lua_remove(lua, -1);

    LOG("tank_turret_new: turret_dx = %f\n", turret_offset.x);
    LOG("tank_turret_new: turret_dy = %f\n", turret_offset.y);

    /*cpVect pos = cpvadd(tank->body->p, turret_offset);*/
    cpVect pos = { .x = 0, .y = 0. };
    pos.x += tank->body->p.x + turret_offset.x;
    pos.y += tank->body->p.y + turret_offset.y;
    cpBodySetPosition(tank->turret, pos);

    cpSpaceAddBody(cur_space->space, tank->turret);
    cpSpaceAddShape(cur_space->space, shape);

    // [.., tank_ud, init_table]
    lua_remove(lua, -1);
    // [.., tank_ud]

#ifdef TANK_TURRET_NEW
    LOG("tank_turret_new: return [%s]\n", stack_dump(lua));
#endif

}
#undef TANK_TURRET_NEW

// Таблица инициализации танка должна быть на вершине стека!
void fill_achor(lua_State *lua, const char *field_name, cpVect *anchor) {
    // [.., tank_ud, {init_table}]
    lua_pushstring(lua, field_name);
    lua_gettable(lua, -2);
    // [.., tank_ud, {init_table}, {anchorA}]

    if (!lua_isnil(lua, -1)) {
        // [.., tank_ud, {init_table}, {anchor}]
        lua_rawgeti(lua, -1, 1);
        // [.., tank_ud, {init_table}, {anchor}, anchor[1] ]
        anchor->x = lua_tonumber(lua, -1);
        lua_remove(lua, -1);

        // [.., tank_ud, {init_table}, {anchor}]]
        lua_rawgeti(lua, -1, 2);
        // [.., tank_ud, {init_table}, {anchor}, anchor[2] ]
        anchor->y = lua_tonumber(lua, -1);
        lua_remove(lua, -1);

        // [.., tank_ud, {init_table}, {anchor}]
        lua_remove(lua, -1);
        // [.., tank_ud, {init_table}]
    }
}

void tank_setup_constraints(Tank *tank, lua_State *lua, int init_table_index) {
    cpConstraint *joint = cpPivotJointNew(tank->body, tank->turret, cpvzero);

    cpVect anchorA = { 0., 0. };
    cpVect anchorB = { 0., 0. };

    // [.., tank_ud]
    lua_pushvalue(lua, init_table_index);
    // [.., tank_ud, init_table]
    
    fill_achor(lua, "anchorA", &anchorA);
    fill_achor(lua, "anchorB", &anchorB);

    lua_remove(lua, -1);
    // [.., tank_ud]

    cpPivotJointSetAnchorA(joint, anchorA);
    cpPivotJointSetAnchorB(joint, anchorB);
    cpSpaceAddConstraint(cur_space->space, joint);

    cpFloat offset = 0.;
    tank->turret_motor = cpSimpleMotorNew(tank->body, tank->turret, offset);
    tank->has_turret_motor = true;
    cpSpaceAddConstraint(cur_space->space, tank->turret_motor);
}

// Кладет на стек таблицу таблиц с вершинами фигур танка.
void tank_push_debug_vertices(lua_State *lua, const Tank *tank) {
    lua_newtable(lua);
    int table_index = lua_gettop(lua);

    cpBodyEachShape(tank->body, push_shape_vertices, lua);
    lua_rawseti(lua, table_index, 1);

    cpBodyEachShape(tank->turret, push_shape_vertices, lua);
    lua_rawseti(lua, table_index, 2);
}

// Добавить трения для тел так, что-бы они останавливались после приложения
// импульса
#define LOG_TANK_NEW
#define PUSH_DEBUG_TANK_VERTICES
static int tank_new(lua_State *lua) {
    // [.., type, x, y, w, h, assoc_table]
    CHECK_SPACE;
    check_argsnum(lua, 2);

    const int init_table_index = 1;
    luaL_checktype(lua, 1, LUA_TTABLE);  // init table
    luaL_checktype(lua, 2, LUA_TTABLE);  // associated(self) table

#ifdef LOG_TANK_NEW
    LOG("tank_new: 1 [%s]\n", stack_dump(lua));
#endif

    // Получить id танка
    lua_pushstring(lua, "id");
    // [.., init_table, assoc_table, "id"]
    lua_gettable(lua, -2);
    // [.., init_table, assoc_table, {id}]
    // Группа столкновений для корпуса и башни устанавливается из id танка.
    int collision_group = lua_tonumber(lua, -1);
    if (lua_isnil(lua, -1)) {
        LOG("tank_new: there is no 'id' value\n");
        exit(1);
    }
    lua_remove(lua, -1);
    
#ifdef LOG_TANK_NEW
    LOG("tank_new: collision_group = %d\n", collision_group);
#endif

#ifdef LOG_TANK_NEW
    LOG("tank_new: 2 [%s]\n", stack_dump(lua));
#endif

    // [.., init_table, assoc_table]
    lua_pushvalue(lua, -2);
    // [.., init_table, assoc_table, init_table]
    
    lua_pushstring(lua, "type");
    lua_gettable(lua, -2);
    // [.., init_table, assoc_table, init_table, type_value]
    const char *type = lua_tostring(lua, -1);
    tank_check_type(lua, type, "tank");
    lua_remove(lua, -1);
    // [.., init_table, assoc_table, init_table]

    cpVect pos = { .x = 0, .y = 0 };

    lua_pushstring(lua, "x");
    lua_gettable(lua, -2);
    pos.x = (int)lua_tonumber(lua, -1);
    lua_remove(lua, -1);

    lua_pushstring(lua, "y");
    lua_gettable(lua, -2);
    pos.y = (int)lua_tonumber(lua, -1);
    lua_remove(lua, -1);

    cpVect turret_rot_point = { .x = 0., .y = 0. };

    // [.., init_table, assoc_table, init_table]
    lua_pushstring(lua, "turret_rot_point");
    lua_gettable(lua, -2);
    // [.., init_table, assoc_table, init_table, {turret_rot_point}]

    lua_rawgeti(lua, -1, 1);
    turret_rot_point.x = (int)lua_tonumber(lua, -1);
    lua_remove(lua, -1);

    lua_rawgeti(lua, -1, 2);
    turret_rot_point.y = (int)lua_tonumber(lua, -1);
    lua_remove(lua, -1);

    lua_remove(lua, -1);
    // [.., init_table, assoc_table, init_table]

    LOG("tank_new: x, y = (%f, %f)\n", pos.x, pos.y);

    if (pos.x != pos.x || pos.y != pos.y ) {
        LOG("tank_new: NaN in pos vector\n");
        exit(1);
    }

    int w = 0, h = 0;

    lua_pushstring(lua, "w");
    lua_gettable(lua, -2);
    w = (int)lua_tonumber(lua, -1);
    lua_remove(lua, -1);

    lua_pushstring(lua, "h");
    lua_gettable(lua, -2);
    h = (int)lua_tonumber(lua, -1);
    lua_remove(lua, -1);

    LOG("tank_new: w, h = (%d, %d)\n", w, h);

    // [.., init_table, assoc_table, init_table]
    lua_remove(lua, -1);
    // [.., init_table, assoc_table]

    lua_pushvalue(lua, -1);
    // [.., type, x, y, w, h, assoc_table, assoc_table]
    int assoc_table_reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);
    // [.., type, x, y, w, h]

    cpFloat mass = w * h * DENSITY;
    cpFloat moment = cpMomentForBox(mass, w, h);

    Tank *tank = lua_newuserdata(lua, sizeof(Tank));
    memset(tank, 0, sizeof(Tank));
    tank->obj.type = OBJT_TANK;

    // [.., type, x, y, w, h, {ud}]
    luaL_getmetatable(lua, "_Tank");
    // [.., type, x, y, w, h, {ud}, {M}]
    lua_setmetatable(lua, -2);
    // [.., type, x, y, w, h, {ud}]

    lua_pushvalue(lua, -1);
    // [.., type, x, y, w, h, {ud}, {ud}]
    int body_reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);
    // [.., type, x, y, w, h, {ud}]
    
    tank->body = cpSpaceAddBody(cur_space->space, cpBodyNew(mass, moment));
    tank->body->userData = tank;
    tank->turret_rot_point = turret_rot_point;

    cpShape *shape = cpBoxShapeNew(tank->body, w, h, 0.f);
    cpShapeFilter filter = { 
        collision_group, 
        CP_ALL_CATEGORIES, 
        CP_ALL_CATEGORIES
    };
    cpShapeSetFilter(shape, filter);

    tank->reg_index = body_reg_index;
    tank->assoc_table_reg_index = assoc_table_reg_index;

#ifdef LOG_TANK_NEW
    LOG(
        "tank_new: reg_index = %d, assoc_table_reg_index = %d\n", 
        tank->reg_index, tank->assoc_table_reg_index
    );
#endif

    /*cpShapeSetFriction(shape, 10000.);*/
    /*cpShapeSetFriction(shape, 1);*/

    cpSpaceAddShape(cur_space->space, shape);
    cpBodySetPosition(tank->body, pos);

#ifdef LOG_TANK_NEW
    print_body_stat(tank->body);
    LOG("tank_new: before turret_new [%s]\n", stack_dump(lua));
#endif

    tank_turret_new(lua, tank, collision_group, init_table_index);
    LOG("tank_new: after turret_new [%s]\n", stack_dump(lua));

    tank_setup_constraints(tank, lua, init_table_index);

    // Удалить все предшествующие возвращаемому значению элементы стека.
    // Не уверен в нужности вызова.
    int top = lua_gettop(lua);
    for(int i = 0; i <= top - 2; i++) {
        lua_remove(lua, 1);
    }
    // [.., {ud}]

#ifdef PUSH_DEBUG_TANK_VERTICES
    tank_push_debug_vertices(lua, tank);
    LOG("tank_new: return [%s]\n", stack_dump(lua));
    // [.., -> {ud}, -> {table}]
    return 2;
#else
    LOG("tank_new: return [%s]\n", stack_dump(lua));
    // [.., -> {ud}]
    return 1;
#endif
}
#undef LOG_TANK_NEW
#undef PUSH_DEBUG_TANK_VERTICES

// Как обеспечить более быструю рисовку?
// Вариант решения - вызывать функцию обратного вызова только если с момента
// прошлого рисования произошло изменению положения, более чем на 0.5px
// Как хранить данные о прошлом положении?
/*#define LOG_ON_EACH_TANK_T*/
void on_each_tank_t(cpBody *body, void *data) {
    lua_State *lua = (lua_State*)data;

#ifdef LOG_ON_EACH_TANK_T
    LOG_STACK_DUMP(lua);
#endif

    Tank *tank = (Tank*)body->userData;

    if (!tank) {
        return;
    }
    if (tank->assoc_table_reg_index == 0) {
        return;
    }

#ifdef LOG_ON_EACH_TANK_T
    LOG(
        "on_each_tank_t: assoc_table_reg_index = %d\n", 
        tank->assoc_table_reg_index
    );
#endif

#ifdef LOG_ON_EACH_TANK_T
    LOG_STACK_DUMP(lua);
#endif

    /*
    lua_rawgeti(lua, LUA_REGISTRYINDEX, tank->assoc_table_reg_index);

    lua_pushstring(lua, "_prev_x");
    lua_gettable(lua, -2);
    double prev_x = lua_tonumber(lua, -1);
    lua_remove(lua, -1); // remove last result

    lua_pushstring(lua, "_prev_y");
    lua_gettable(lua, -2);
    double prev_y = lua_tonumber(lua, -1);
    lua_remove(lua, -1); // remove last result
    lua_remove(lua, -1); // body->userData table
    */

#ifdef LOG_ON_EACH_TANK_T
    LOG_STACK_DUMP(lua);
#endif

#ifdef LOG_ON_EACH_TANK_T
    /*LOG("on_each_tank_t: prev_x, prev_y %.3f, %.3f \n", prev_x, prev_y);*/
#endif

    /*
    double epsilon = 0.001;
    double dx = fabs(prev_x - body->p.x);
    double dy = fabs(prev_y - body->p.y);
    */

    // Добавить проверку не только на движение, но и на изменение угла поворота
    // башни.
    /*if (dx > epsilon || dy > epsilon) {*/
    if (1) {
        lua_pushvalue(lua, 1); // callback function

        lua_pushnumber(lua, body->p.x);
        lua_pushnumber(lua, body->p.y);
        lua_pushnumber(lua, body->a);

        /*LOG("reg_index = %d\n", tank->reg_index);*/

        /*lua_rawgeti(lua, LUA_REGISTRYINDEX, tank->reg_index);*/
        lua_rawgeti(lua, LUA_REGISTRYINDEX, tank->assoc_table_reg_index);

        cpBody *turret = tank->turret;
        lua_pushnumber(lua, turret->p.x);
        lua_pushnumber(lua, turret->p.y);
        lua_pushnumber(lua, turret->a);

#ifdef LOG_ON_EACH_TANK_T
        LOG("on_each_tank_t: before call 1 [%s]\n", stack_dump(lua));
        tank_push_debug_vertices(lua, tank);
        LOG("on_each_tank_t: before call 2 [%s]\n", stack_dump(lua));
        lua_call(lua, 8, 0);
#else
        lua_call(lua, 7, 0);
#endif

    }

#ifdef LOG_ON_EACH_TANK_T
    LOG_STACK_DUMP(lua);
#endif

    /*
    lua_rawgeti(lua, LUA_REGISTRYINDEX, tank->reg_index);

    lua_pushstring(lua, "_prev_x"); //key
    lua_pushnumber(lua, body->p.x); //value
    lua_settable(lua, -3);

    lua_pushstring(lua, "_prev_y"); //key
    lua_pushnumber(lua, body->p.y); //value
    lua_settable(lua, -3);

    lua_remove(lua, -1);
    */

#ifdef LOG_ON_EACH_TANK_T
    LOG("on_each_tank_t: [%s]\n", stack_dump(lua));
#endif

}
#undef LOG_ON_EACH_TANK_T

// Как обеспечить более быструю рисовку?
// Вариант решения - вызывать функцию обратного вызова только если с момента
// прошлого рисования произошло изменению положения, более чем на 0.5px
// Как хранить данные о прошлом положении?
/*#define LOG_ON_EACH_TANK*/
/*
void on_each_tank(cpBody *body, void *data) {
    lua_State *lua = (lua_State*)data;

#ifdef LOG_ON_EACH_TANK
    LOG_STACK_DUMP(lua);
#endif

    // TODO Убрать лишние операции со стеком, получать таблицу связанную с 
    // телом один раз.

    int table_reg_index = GET_USER_DATA_TABLE(body);

    if (table_reg_index == 0) {
        return;
    }

    lua_rawgeti(lua, LUA_REGISTRYINDEX, table_reg_index);

#ifdef LOG_ON_EACH_TANK
    LOG_STACK_DUMP(lua);
#endif

    lua_pushstring(lua, "_prev_x");
    lua_gettable(lua, -2);
    double prev_x = lua_tonumber(lua, -1);
    lua_remove(lua, -1); // remove last result

    lua_pushstring(lua, "_prev_y");
    lua_gettable(lua, -2);
    double prev_y = lua_tonumber(lua, -1);
    lua_remove(lua, -1); // remove last result

#ifdef LOG_ON_EACH_TANK
    LOG_STACK_DUMP(lua);
#endif

    lua_remove(lua, -1); // body->userData table

#ifdef LOG_ON_EACH_TANK
    LOG("on_each_tank: prev_x, prev_y %.3f, %.3f \n", prev_x, prev_y);
#endif

    double epsilon = 0.001;
    double dx = fabs(prev_x - body->p.x);
    double dy = fabs(prev_y - body->p.y);

    // TODO Получить assoc_table
    // Из assoc_table получить пользовательские данные _turret башни.
    // Из данных башни получить ее координаты, угол и т.д.

    // Добавить проверку не только на движение, но и на изменение угла поворота
    // башни.
    if (dx > epsilon || dy > epsilon) {
        lua_pushvalue(lua, 1); // callback function
        lua_pushnumber(lua, body->p.x);
        lua_pushnumber(lua, body->p.y);
        lua_pushnumber(lua, body->a);
        lua_rawgeti(lua, LUA_REGISTRYINDEX, GET_USER_DATA_TABLE(body));
        lua_call(lua, 4, 0);
    }

#ifdef LOG_ON_EACH_TANK
    LOG_STACK_DUMP(lua);
#endif

    lua_rawgeti(lua, LUA_REGISTRYINDEX, table_reg_index);

    lua_pushstring(lua, "_prev_x"); //key
    lua_pushnumber(lua, body->p.x); //value
    lua_settable(lua, -3);

    lua_pushstring(lua, "_prev_y"); //key
    lua_pushnumber(lua, body->p.y); //value
    lua_settable(lua, -3);

    lua_remove(lua, -1);

#ifdef LOG_ON_EACH_TANK
    LOG("on_each_tank: [%s]\n", stack_dump);
#endif

}
#undef LOG_ON_EACH_TANK
*/

/*
void on_each_body(cpBody *body, void *data) {
    lua_State *lua = (lua_State*)data;

    lua_pushvalue(lua, 1); // callback function
    lua_pushnumber(lua, body->p.x);
    lua_pushnumber(lua, body->p.y);
    lua_pushnumber(lua, body->a);
    //int table_reg_index = ((Parts*)(&body->userData))->table;

    int table_reg_index = GET_USER_DATA_TABLE(body);
    printf("table_reg_index = %d\n", table_reg_index);
    lua_rawgeti(lua, LUA_REGISTRYINDEX, table_reg_index);

    lua_call(lua, 4, 0);

    printf("on_each_body\n");
}
*/

void print_space_info(cpSpace *space) {
    printf("iterations %d\n", space->iterations);
    printf("damping %f\n", space->damping);
    printf("data %p\n", space->userData);
    printf("curr_dt %f\n", space->curr_dt);
    printf("stamp %d\n", space->stamp);
}

void on_bb_query(cpShape *shape, void *data) {
    lua_State *lua = data;
    if (shape->body->userData) {
        /*lua_pushvalue(lua, 5); // callback function*/
        cpBody *body = shape->body;
        Tank *tank = (Tank*)body->userData;

        lua_pushnumber(lua, body->p.x);
        lua_pushnumber(lua, body->p.y);
        lua_pushnumber(lua, body->a);

        lua_rawgeti(lua, LUA_REGISTRYINDEX, tank->assoc_table_reg_index);

        cpBody *turret = tank->turret;
        lua_pushnumber(lua, turret->p.x);
        lua_pushnumber(lua, turret->p.y);
        lua_pushnumber(lua, turret->a);

        lua_call(lua, 7, 0);
    }
}

#define SPACE_QUERY_BB
static int space_query_bb(lua_State *lua) {
    CHECK_SPACE;
    check_argsnum(lua, 5);
    luaL_checktype(lua, 1, LUA_TNUMBER); // x
    luaL_checktype(lua, 2, LUA_TNUMBER); // y
    luaL_checktype(lua, 3, LUA_TNUMBER); // w
    luaL_checktype(lua, 4, LUA_TNUMBER); // h
    luaL_checktype(lua, 5, LUA_TFUNCTION);

    cpShapeFilter filter = {
        CP_NO_GROUP,
        CP_ALL_CATEGORIES, 
        CP_ALL_CATEGORIES 
    };

    cpBB bb = {0, };
    bb.l = lua_tonumber(lua, 1);
    bb.t = lua_tonumber(lua, 2);
    bb.r = bb.l + lua_tonumber(lua, 3);
    bb.b = bb.t + lua_tonumber(lua, 4);

    cpSpaceBBQuery(cur_space->space, bb, filter, on_bb_query, lua);

    return 0;
}
#undef SPACE_QUERY_BB

/*#define LOG_QUERY_ALL_TANKS_T*/
static int query_all_tanks_t(lua_State *lua) {
    CHECK_SPACE;
    luaL_checktype(lua, 1, LUA_TFUNCTION);
    check_argsnum(lua, 1);

#ifdef LOG_QUERY_ALL_TANKS_T
    LOG("query_all_tanks_t: [%s]\n", stack_dump(lua));
#endif

    cpSpaceEachBody(cur_space->space, on_each_tank_t, lua);

#ifdef LOG_QUERY_ALL_TANKS_T
    LOG("query_all_tanks_t: return [%s]\n", stack_dump(lua));
#endif
    return 0;
}
#undef LOG_QUERY_ALL_TANKS_T

/*
//#define LOG_QUERY_ALL_TANKS
static int query_all_tanks(lua_State *lua) {
    CHECK_SPACE;
    luaL_checktype(lua, 1, LUA_TFUNCTION);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

#ifdef LOG_QUERY_ALL_TANKS
    LOG("query_all_tanks: [%s]\n", stack_dump(lua));
#endif
    cpSpaceEachBody(cur_space, on_each_tank, lua);
#ifdef LOG_QUERY_ALL_TANKS
    LOG("query_all_tanks: return [%s]\n", stack_dump(lua));
#endif
    return 0;
}
#undef LOG_QUERY_ALL_TANKS
*/

/*
static int query_all_shapes(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TFUNCTION);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Space pointer is null.\n");
        lua_error(lua);
    }

    //printf("cur_space %p\n", cur_space);
    //print_space_info(cur_space);
    assert(cur_space && "space is NULL");

    //cpSpaceEachBody(cur_space, on_each_body, lua);

    return 0;
}
*/

static int space_set(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    cur_space = (Space*)luaL_checkudata(lua, 1, "_Space");
    return 0;
}

static int space_step(lua_State *lua) {
    CHECK_SPACE;
    luaL_checktype(lua, 1, LUA_TNUMBER);
    double dt = luaL_checknumber(lua, 1);
    cpSpaceStep(cur_space->space, dt);
    return 0;
}

static int body_position_get(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    check_argsnum(lua, 1);

    Tank *tank = (Tank*)luaL_checkudata(lua, 1, "_Tank");
    lua_pushnumber(lua, tank->body->p.x);
    lua_pushnumber(lua, tank->body->p.y);
    lua_pushnumber(lua, tank->body->a);

    return 3;
}

/*#define BODY_POSITION_SET*/
static int body_position_set(lua_State *lua) {
#ifdef BODY_POSITION_SET
    LOG("body_position_set: [%s]\n", stack_dump(lua));
#endif
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);

    check_argsnum(lua, 1);

    Tank *tank = (Tank*)luaL_checkudata(lua, 1, "_Tank");
    double x = lua_tonumber(lua, 2);
    double y = lua_tonumber(lua, 3);
    cpVect pos = { .x = x, .y = y};

    if (pos.x != pos.x || pos.y != pos.y) {
        LOG("body_position_set: NaN in pos vector.\n");
    }

    cpBodySetPosition(tank->body, pos);

    /*print_body_stat(b);*/
    
    return 0;
}
#undef BODY_POSITION_SET

static int apply_force(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    luaL_checktype(lua, 4, LUA_TNUMBER);
    luaL_checktype(lua, 5, LUA_TNUMBER);
    check_argsnum(lua, 5);

    cpVect force = { 
        .x = lua_tonumber(lua, 2),
        .y = lua_tonumber(lua, 3),
    };

    cpVect point = { 
        .x = lua_tonumber(lua, 4),
        .y = lua_tonumber(lua, 5),
    };

    Tank *tank = (Tank*)luaL_checkudata(lua, 1, "_Tank");
    cpBodyApplyForceAtLocalPoint(tank->body, force, point);

    return 0;
}

static int apply_impulse(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    luaL_checktype(lua, 4, LUA_TNUMBER);
    luaL_checktype(lua, 5, LUA_TNUMBER);
    check_argsnum(lua, 5);

    cpVect impulse = { 
        .x = lua_tonumber(lua, 2),
        .y = lua_tonumber(lua, 3),
    };

    cpVect point = { 
        .x = lua_tonumber(lua, 4),
        .y = lua_tonumber(lua, 5),
    };

    Tank *tank = (Tank*)luaL_checkudata(lua, 1, "_Tank");
    cpBodyApplyImpulseAtLocalPoint(tank->body, impulse, point);
    if (!tank->has_turret_motor) {
        cpSpaceAddConstraint(cur_space->space, tank->turret_motor);
        tank->has_turret_motor = true;
    }

    return 0;
}

static int static_segment_new(lua_State *lua) {
    CHECK_SPACE;
    // [.., x1, y1, x2, y2]
    luaL_checktype(lua, 1, LUA_TNUMBER);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    luaL_checktype(lua, 4, LUA_TNUMBER);
    check_argsnum(lua, 4);

    cpVect p1 = { .x = lua_tonumber(lua, 1), .y = lua_tonumber(lua, 2), };
    cpVect p2 = { .x = lua_tonumber(lua, 3), .y = lua_tonumber(lua, 4), };

    cpBody *static_body = cpSpaceGetStaticBody(cur_space->space);

    /*cpBody *static_body = cpBodyNew(10000.f, 1.);*/
    /*cpSpaceAddBody(cur_space, static_body);*/

    cpShape *shape = cpSegmentShapeNew(static_body, p1, p2, 0.0f);
    cpShapeSetElasticity(shape, 1.0f);
    cpShapeSetFriction(shape, 1.0f);
    // что дает установка следующего фильтра?
    cpShapeSetFilter(shape, NOT_GRABBABLE_FILTER);
    cpSpaceAddShape(cur_space->space, shape);

    // [.., x1, y1, x2, y2, -> ud]
    return 1;
}

/*
static int static_segment_free(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    assert(cur_space && "space is NULL");

    //cpShape *shape = (cpShape*)luaL_checkudata(lua, 1, "_Segment");
    //cpSpaceRemoveShape(cur_space->space, shape);
    //luaL_unref( lua, LUA_REGISTRYINDEX, ((Parts*)(&shape->userData))->regindex_ud);
    //cpShapeFree(shape);

    return 0;
}
*/

void on_segment_shape(cpBody *body, cpShape *shape, void *data) {
    lua_State *lua = (lua_State*)data;
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

static int static_segments_draw(lua_State *lua) {
    CHECK_SPACE;
    luaL_checktype(lua, 1, LUA_TFUNCTION);
    check_argsnum(lua, 1);
    cpBody *static_body = cpSpaceGetStaticBody(cur_space->space);
    cpBodyEachShape(static_body, on_segment_shape, lua);
    return 0;
}

/*#define LOG_ON_POINT_QUERY*/
void on_point_query(
        cpShape *shape, 
        cpVect point, 
        cpFloat distance, 
        cpVect gradient, 
        void *data
) {
    lua_State *lua = (lua_State*)data;

#ifdef LOG_ON_POINT_QUERY
    LOG("on_point_query\n");
#endif

    // XXX Костыли или нет? Функция иногда вызывается с пустой фигурой.
    if (!shape) {
        return;
    }

#ifdef LOG_ON_POINT_QUERY
    LOG("stack 1: [%s]\n", stack_dump(lua));
#endif

    /*int index = ((Parts*)(&shape->userData))->regindex_ud;*/
    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, index);*/

    cpBody *body = shape->body;
    if (!body) {
        return;
    }
    if (shape->klass->type != CP_POLY_SHAPE) {
        return;
    }
    Tank *tank = (Tank*)body->userData;
    if (!tank) {
        return;
    }
    if (tank->reg_index == 0) {
        LOG("on_point_query: tank->reg_index == 0");
        return;
    }
    lua_rawgeti(lua, LUA_REGISTRYINDEX, tank->reg_index);

#ifdef LOG_ON_POINT_QUERY
    LOG("stack 2: [%s]\n", stack_dump(lua));
#endif

    if (lua_isnil(lua, -1)) {
        LOG("on_point_query: lua_isnil(lua, -1) == true\n");
        return;
    }

    /*printf("body->userData = %p\n", body->userData);*/
    /*printf("ud %d\n", GET_USER_DATA_UD(body));*/
    /*printf("table %d\n", GET_USER_DATA_TABLE(body));*/

#ifdef LOG_ON_POINT_QUERY
    LOG("stack 3: [%s]\n", stack_dump(lua));
#endif

    // XXX Изменить проверку типа объекта для других типов.
    void *ud = luaL_checkudata(lua, -1, "_Tank");

#ifdef LOG_ON_POINT_QUERY
    LOG("stack 4: [%s]\n", stack_dump(lua));
#endif

    /*void *ud = lua_touserdata(lua, lua_gettop(lua));*/
    if (!ud) {
        lua_pushstring(lua, "no shape\n");
        lua_error(lua);
    }

    lua_pushnumber(lua, point.x);
    lua_pushnumber(lua, point.y);
    lua_pushnumber(lua, distance);
    lua_pushnumber(lua, gradient.x);
    lua_pushnumber(lua, gradient.x);

    /*print_stack_dump(lua);*/
    /*printf("1111111111111111111");*/

    /*LOG("stack 5: [%s]\n", stack_dump(lua));*/
    lua_call(lua, 6, 0);

    /*print_stack_dump(lua);*/
    /*printf("222222222222222");*/
    /*LOG("on_point_query: [%s]\n", stack_dump(lua));*/
}

// Вызывает функцию обратного вызова для фигур под данной точно.
// Не учитывает фильтры.
static int get_body_under_point(lua_State *lua) {
    CHECK_SPACE;
    luaL_checktype(lua, 1, LUA_TNUMBER);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TFUNCTION);
    check_argsnum(lua, 3);

    cpVect point = { 
        .x = lua_tonumber(lua, 1),
        .y = lua_tonumber(lua, 2),
    };
    cpSpacePointQuery(
            cur_space->space, point, 0, ALL_FILTER, on_point_query, lua
    );

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

/*
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
*/

#define TANK_BODY_STAT_GET
int tank_body_stat_get(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    check_argsnum(lua, 1);

    Tank *tank = (Tank*)luaL_checkudata(lua, 1, "_Tank");
    cpBody *b = tank->body;

#ifdef TANK_BODY_STAT_GET
    printf("get_body_stat: [%s]\n", stack_dump(lua));
    print_body_stat(b);
#endif

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

    LOG("return from tank_body_stat_get() %s\n", stack_dump(lua));
    return 13;
}

#define TANK_TURRET_STAT_GET
int tank_turret_stat_get(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    check_argsnum(lua, 1);

    Tank *tank = (Tank*)luaL_checkudata(lua, 1, "_Tank");
    cpBody *b = tank->turret;

#ifdef TANK_TURRET_STAT_GET
    printf("get_body_stat: [%s]\n", stack_dump(lua));
    print_body_stat(b);
#endif
    /*printf("get_body_stat()\n");*/

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

    LOG("return tank_turret_stat_get() %s\n", stack_dump(lua));
    return 13;
}

static int set_torque(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    check_argsnum(lua, 2);

    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Tank");
    double torque = lua_tonumber(lua, 2);

    cpBodySetTorque(body, torque);

    return 0;
}

static int get_body_type(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    check_argsnum(lua, 1);
    
    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Tank");
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
    check_argsnum(lua, 1);
    
    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Tank");
    cpVect vel = cpBodyGetVelocity(body);

    lua_pushnumber(lua, vel.x);
    lua_pushnumber(lua, vel.y);

    return 2;
}

static int set_body_ang_vel(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    check_argsnum(lua, 2);
    
    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Tank");
    double ang_vel = lua_tonumber(lua, 2);
    cpBodySetAngularVelocity(body, ang_vel);

    return 0;
}

static int get_body_ang_vel(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    check_argsnum(lua, 1);
    cpBody *body = (cpBody*)luaL_checkudata(lua, 1, "_Tank");
    lua_pushnumber(lua, cpBodyGetAngularVelocity(body));
    return 1;
}

/*
static const struct luaL_Reg Turret_methods[] =
{
    // установить положение тела
    {"set_position", body_position_set},
    // получить положение тела и угол поворота
    {"get_position", body_position_get},
    // придать импульс телу
    {"apply_impulse", apply_impulse},
    // приложить силу к телу
    {"apply_force", apply_force},
    // установить вращение тела
    {"set_torque", set_torque},
    // возвращает число 1..3 - тип тела: DYNAMIC, KINEMATIC, STATIC
    {"get_type", get_body_type},
    // Возвращает скорость тела
    {"get_vel", get_body_vel},
    // Получить угловую скорость тела
    {"get_ang_vel", get_body_ang_vel},
    // Установить угловую скорость тела
    {"set_ang_vel", set_body_ang_vel},

    // получить разную информацию по телу
    // используется для отладки
    {"get_stat", get_body_stat},
    //{"shape_print_filter", shape_print_filter},

    {NULL, NULL}
};
*/

int get_turret_position(lua_State *lua) {
    // [.., ud]
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    check_argsnum(lua, 1);
    Tank *tank = (Tank*)luaL_checkudata(lua, 1, "_Tank");
    lua_pushnumber(lua, tank->turret->p.x);
    lua_pushnumber(lua, tank->turret->p.y);
    lua_pushnumber(lua, tank->turret->a);
    return 3;
}

int turret_rotate(lua_State *lua) {
    Tank *tank = luaL_checkudata(lua, 1, "_Tank");
    double k = luaL_checknumber(lua, 2);
    cpVect point = tank->turret_rot_point;
    /*LOG("turret_rotate: point(%f, %f)\n", point.x, point.y);*/
    cpVect impulse = {
        .x = k / 50000.,
        .y = 0.,
    };
    if (tank->has_turret_motor) {
        cpSpaceRemoveConstraint(cur_space->space, tank->turret_motor);
        tank->has_turret_motor = false;
    }
    cpBodyApplyImpulseAtLocalPoint(tank->turret, impulse, point);
    return 0;
}

#define SPACE_QUERY_SEGMENT_FIRST
int space_query_segment_first(lua_State *lua) {
    CHECK_SPACE;
    check_argsnum(lua, 6);

    cpVect start = {0, }, end = {0, };
    cpShapeFilter filter = {
        luaL_checknumber(lua, 1),
        CP_ALL_CATEGORIES, 
        CP_ALL_CATEGORIES 
    };

    start.x = luaL_checknumber(lua, 2);
    start.y = luaL_checknumber(lua, 3);
    end.x = luaL_checknumber(lua, 4);
    end.y = luaL_checknumber(lua, 5);
    luaL_checktype(lua, 6, LUA_TFUNCTION);
    cpFloat radius = 1.;
    cpSegmentQueryInfo info = {0, };

#ifdef SPACE_QUERY_SEGMENT_FIRST
    LOG("space_query_segment_first: [%s]\n", stack_dump(lua));
#endif
    cpSpaceSegmentQueryFirst(
            cur_space->space,
            start, end,
            radius,
            filter,
            &info
    );

    if (info.shape && info.shape->body->userData) {
        Tank *tank = info.shape->body->userData;
        lua_rawgeti(lua, LUA_REGISTRYINDEX, tank->reg_index);
        lua_pushnumber(lua, info.point.x);
        lua_pushnumber(lua, info.point.y);
        lua_pushnumber(lua, info.normal.x);
        lua_pushnumber(lua, info.normal.y);
        lua_pushnumber(lua, info.alpha);
        lua_call(lua, 6, 0);
    }

    return 0;
}
#undef SPACE_QUERY_SEGMENT_FIRST

static const struct luaL_Reg Tank_methods[] =
{
    // {{{
    /*{"query_segment_first", tank_query_segment_first},*/
    {"turret_rotate", turret_rotate},
    {"turret_get_pos", get_turret_position},

    // установить положение тела
    {"set_position", body_position_set},
    // получить положение тела и угол поворота
    {"get_position", body_position_get},
    // придать импульс телу
    {"apply_impulse", apply_impulse},
    // приложить силу к телу
    {"apply_force", apply_force},
    // установить вращение тела
    {"set_torque", set_torque},
    // возвращает число 1..3 - тип тела: DYNAMIC, KINEMATIC, STATIC
    {"get_type", get_body_type},
    // Возвращает скорость тела
    {"get_vel", get_body_vel},
    // Получить угловую скорость тела
    {"get_ang_vel", get_body_ang_vel},
    // Установить угловую скорость тела
    {"set_ang_vel", set_body_ang_vel},

    // получить разную информацию по телу используется для отладки
    {"get_body_stat", tank_turret_stat_get},
    {"get_turret_stat", tank_body_stat_get},
    /*{"shape_print_filter", shape_print_filter},*/

    {NULL, NULL}
    // }}}
};

/*#define DBG_DRAWCIRCLE*/
void dbg_drawCircle(
        cpVect pos, 
        cpFloat angle, 
        cpFloat radius, 
        cpSpaceDebugColor outlineColor, 
        cpSpaceDebugColor fillColor, 
        cpDataPointer data
) {
    lua_State *lua = data;
#ifdef DBG_DRAWCIRCLE
    LOG("dbg_drawCircle: [%s]\n", stack_dump(lua));
#endif
    lua_pushvalue(lua, 1);
    lua_pushnumber(lua, pos.x);
    lua_pushnumber(lua, pos.y);
    lua_pushnumber(lua, radius);
    lua_call(lua, 3, 0);
    lua_remove(lua, -1);
}
#undef DBG_DRAWCIRCLE

/*#define DBG_DRAWSEGMENT*/
void dbg_drawSegment(
        cpVect a, 
        cpVect b, 
        cpSpaceDebugColor color, 
        cpDataPointer data
) {
    lua_State *lua = data;
#ifdef DBG_DRAWSEGMENT
    LOG("dbg_drawSegment: [%s]\n", stack_dump(lua));
#endif
    lua_pushvalue(lua, 2);
    lua_pushnumber(lua, a.x);
    lua_pushnumber(lua, a.y);
    lua_pushnumber(lua, b.x);
    lua_pushnumber(lua, b.y);
    lua_call(lua, 4, 0);
    lua_remove(lua, -1);
}
#undef DBG_DRAWSEGMENT

/*#define DBG_DRAWFATSEGMENT*/
void dbg_drawFatSegment(
        cpVect a, 
        cpVect b, 
        cpFloat radius, 
        cpSpaceDebugColor outlineColor, 
        cpSpaceDebugColor fillColor, 
        cpDataPointer data
) {
    lua_State *lua = data;
#ifdef DBG_DRAWFATSEGMENT
    LOG("dbg_drawFatSegment: [%s]\n", stack_dump(lua));
#endif
    lua_pushvalue(lua, 3);
    lua_pushnumber(lua, a.x);
    lua_pushnumber(lua, a.y);
    lua_pushnumber(lua, b.x);
    lua_pushnumber(lua, b.y);
    lua_pushnumber(lua, radius);
    lua_call(lua, 5, 0);
}
#undef DBG_DRAWFATSEGMENT

/*#define DBG_DRAWPOLYGON*/
void dbg_drawPolygon(
        int count, 
        const cpVect *verts, 
        cpFloat radius, 
        cpSpaceDebugColor outlineColor, 
        cpSpaceDebugColor fillColor, 
        cpDataPointer data
) {
    lua_State *lua = data;
#ifdef DBG_DRAWPOLYGON
    LOG("dbg_drawPolygon: [%s]\n", stack_dump(lua));
#endif
    lua_pushvalue(lua, 4);
    lua_newtable(lua);
    int table_index = lua_gettop(lua);
    int arr_index = 1;
    for (int i = 0; i < count; ++i) {
        lua_pushnumber(lua, verts[i].x);
        lua_rawseti(lua, table_index, arr_index++);
        lua_pushnumber(lua, verts[i].y);
        lua_rawseti(lua, table_index, arr_index++);
    }
    lua_pushnumber(lua, radius);
    lua_call(lua, 2, 0);
    /*lua_remove(lua, -1);*/
}
#undef DBG_DRAWPOLYGON

/*#define DBG_DRAWDOT*/
void dbg_drawDot(
        cpFloat size, 
        cpVect pos, 
        cpSpaceDebugColor color, 
        cpDataPointer data
) {
    lua_State *lua = data;
#ifdef DBG_DRAWDOT
    LOG("dbg_drawDot: [%s]\n", stack_dump(lua));
#endif
    lua_pushvalue(lua, 5);
    /*const char *s = lua_tostring(lua, -1);*/
    /*LOG("S = %s\n", s);*/
    lua_pushnumber(lua, size);
    lua_pushnumber(lua, pos.x);
    lua_pushnumber(lua, pos.y);
    lua_call(lua, 3, 0);
    /*lua_remove(lua, -1);*/
}
#undef DBG_DRAWDOT

cpSpaceDebugColor DebugDrawColorForShape(cpShape *shape, cpDataPointer data) {
    cpSpaceDebugColor c = {1., 1., 1., 1.};
    return c;
}

/*#define SPACE_DEBUG_DRAW*/
static int space_debug_draw(lua_State *lua) {
    CHECK_SPACE;
    check_argsnum(lua, 5);

    luaL_checktype(lua, 1, LUA_TFUNCTION); // circle
    luaL_checktype(lua, 2, LUA_TFUNCTION); // segment
    luaL_checktype(lua, 3, LUA_TFUNCTION); // fatsegment
    luaL_checktype(lua, 4, LUA_TFUNCTION); // polygon
    luaL_checktype(lua, 5, LUA_TFUNCTION); // dot

#ifdef SPACE_DEBUG_DRAW
    LOG("space_set_debug_draw: [%s]\n", stack_dump(lua));
#endif

    cpSpaceDebugDrawOptions options = {
        .drawCircle = dbg_drawCircle,
        .drawSegment = dbg_drawSegment,
        .drawFatSegment = dbg_drawFatSegment,
        .drawPolygon = dbg_drawPolygon,
        .drawDot = dbg_drawDot,
        .flags = CP_SPACE_DEBUG_DRAW_SHAPES | 
            CP_SPACE_DEBUG_DRAW_CONSTRAINTS |
            CP_SPACE_DEBUG_DRAW_COLLISION_POINTS,

        .shapeOutlineColor = {1., 1., 1., 1.},
        .colorForShape = DebugDrawColorForShape,
        .constraintColor = {1., 1., 1., 1.},
        .collisionPointColor = {1., 1., 1., 1.},
        .data = lua,
    };

    cpSpaceDebugDraw(cur_space->space, &options);

    return 0;
}
#undef SPACE_DEBUG_DRAW

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        
        // создать пространство
        {"space_new", space_new},
        // удалить пространство и все тела на нем
        {"space_free", space_free},
        // шаг симуляции
        {"space_step", space_step},
        {"space_set", space_set},
        {"space_debug_draw", space_debug_draw},
        {"space_query_segment_first", space_query_segment_first},
        {"space_query_bb", space_query_bb},

        // вызов функции для всех тел в текущем пространстве
        /*{"query_all_shapes", query_all_shapes},*/

        // вызов функции для всех танков в текущем пространстве
        /*{"query_all_tanks", query_all_tanks},*/

        // Вызов функции для всех танков в текущем пространстве с учетом башни.
        {"query_all_tanks_t", query_all_tanks_t},

        // новое танк
        {"tank_new", tank_new},

        // добавить к статическому телу форму - отрезок
        {"static_segment_new", static_segment_new},

        // удалить фигуру статического тела и освободить ее память
        /*{"static_segment_free", static_segment_free},*/

        // обратный вызов функции для рисования всех сегментов
        {"static_segments_draw", static_segments_draw},

        // вызвать коллббэк для всех фигур под данной точкой
        {"get_body_under_point", get_body_under_point},
        // возвращает тело относящееся к фигуре
        /*{"get_shape_body", get_shape_body},*/

        // получить разную информацию по телу используется для отладки
        /*{"get_body_stat", get_body_stat},*/
        {"shape_print_filter", shape_print_filter},

        {NULL, NULL}
        // }}}
    };
    luaL_register(lua, "wrapper", functions);
    return 1;
}

extern int luaopen_wrp(lua_State *lua) {
    register_methods(lua, "_Tank", Tank_methods);
    /*register_methods(lua, "_Turret", Turret_methods);*/
    luaL_newmetatable(lua, "_Space");
    printf("wrp module opened [%s]\n", stack_dump(lua));
    return register_module(lua);
}
