#include "chipmunk/chipmunk.h"
#include "chipmunk/chipmunk_structs.h"

#include <assert.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

cpShapeFilter ALL_FILTER = { 1, CP_ALL_CATEGORIES, CP_ALL_CATEGORIES };

// Что делает этот фильтр?
#define GRABBABLE_MASK_BIT (1<<31)
cpShapeFilter GRAB_FILTER = {CP_NO_GROUP, GRABBABLE_MASK_BIT, GRABBABLE_MASK_BIT};
cpShapeFilter NOT_GRABBABLE_FILTER = {CP_NO_GROUP, ~GRABBABLE_MASK_BIT, ~GRABBABLE_MASK_BIT};

static void stackDump (lua_State *L) {
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

static int each_body(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TFUNCTION);
    int call_count = (int)lua_tonumber(lua, 2);
    printf("call_count %d\n", call_count);
    for (int i = 0; i < call_count; i++) {
        /*lua_call(lua, 1, 0);*/
        lua_pushvalue(lua, 1);
        lua_pushnumber(lua, i);
        lua_call(lua, 1, 0);
    }
    return 0;
}

static cpSpace *cur_space = NULL;

static int init_space(lua_State *lua) {
    /*int type = lua_type(lua, 1);*/
    /*printf("type %d\n", type);*/
    /*cur_space = (cpSpace*)lua_topointer(lua, 1);*/
    cur_space = cpSpaceNew();
    lua_pushlightuserdata(lua, cur_space);

	/*cpSpaceSetIterations(space, 30);*/
	/*cpSpaceSetGravity(space, cpv(0, -500));*/
	/*cpSpaceSetSleepTimeThreshold(space, 0.5f);*/
	/*cpSpaceSetCollisionSlop(space, 0.5f);*/

    return 1;
}

static void ConstraintFreeWrap(cpSpace *space, cpConstraint *constraint, void *unused){
    cpSpaceRemoveConstraint(space, constraint);
    cpConstraintFree(constraint);
}

static void PostConstraintFree(cpConstraint *constraint, cpSpace *space){
    cpSpaceAddPostStepCallback(space, (cpPostStepFunc)ConstraintFreeWrap, constraint, NULL);
}

static void ShapeFreeWrap(cpSpace *space, cpShape *shape, void *unused){
	cpSpaceRemoveShape(space, shape);
	cpShapeFree(shape);
}

static void PostShapeFree(cpShape *shape, cpSpace *space){
    cpSpaceAddPostStepCallback(space, (cpPostStepFunc)ShapeFreeWrap, shape, NULL);
}

static int free_space(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);
    cpSpace *space = (cpSpace*)lua_topointer(lua, 1);

    cpSpaceEachShape(space, (cpSpaceShapeIteratorFunc)PostShapeFree, space);
    cpSpaceEachConstraint(space, (cpSpaceConstraintIteratorFunc)PostConstraintFree, space);

    cpSpaceFree(space);
}

#define DENSITY (1.0/10000.0)

// добавить трения для тел так, что-бы они останавливались после приложения
// импульса
static int new_body(lua_State *lua) {
    // in: ширина, высота, таблица с инфой

    int top = lua_gettop(lua);
    if (top != 4) {
        lua_pushstring(lua, "Function should receive only 3 arguments.\n");
        lua_error(lua);
    }

    luaL_checktype(lua, 1, LUA_TSTRING);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    luaL_checktype(lua, 4, LUA_TTABLE);

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

    int w = (int)lua_tonumber(lua, 2);
    int h = (int)lua_tonumber(lua, 3);

    cpFloat mass = w * h * DENSITY;

    printf("mass %.3f\n", mass);

    cpFloat moment = cpMomentForBox(mass, w, h);
    /*printf("mass %f moment %f\n", mass, moment);*/
    cpBody *b = cpBodyNew(mass, moment);

    if (!cur_space) {
        lua_pushstring(lua, "Space pointer is null.\n");
        lua_error(lua);
    }

    cpSpaceAddBody(cur_space, b);
    cpShape *shape = cpBoxShapeNew(b, w, h, 0.f);

    cpShapeSetFriction(shape, 10000.);
    printf("shape friction: %f\n", cpShapeGetFriction(shape));
    /*cpShapeSetFriction(shape, 1);*/
    cpSpaceAddShape(cur_space, shape);

    // ссылка на табличку, связанную с телом
    int reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);
    b->userData = (void*)(uint64_t)reg_index;

    cpBodySetMass(b, mass);

    lua_pushlightuserdata(lua, b);

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

    lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)body->userData);

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

    lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)body->userData);

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
    lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)body->userData);
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

    /*printf("C: query_all_shapes\n");*/

    cpSpaceEachBody(cur_space, on_each_body, lua);
    /*cpSpaceEachBody(cur_space, NULL, NULL);*/

    /*printf("C: query_all_shapes after\n");*/
    /*printf("C: query_all_shapes after\n");*/

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
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_topointer(lua, 1);
    lua_pushnumber(lua, b->p.x);
    lua_pushnumber(lua, b->p.y);
    lua_pushnumber(lua, b->a);

    return 3;
}

static int set_position(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 3) {
        lua_pushstring(lua, "Function expect 3 arguments.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_topointer(lua, 1);
    double x = lua_tonumber(lua, 2);
    double y = lua_tonumber(lua, 3);
    cpVect pos = { .x = x, .y = y};
    /*printf("pos %f, %f\n", pos.x, pos.y);*/
    cpBodySetPosition(b, pos);
    
    return 0;
}

static int apply_impulse(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);
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

    cpBody *b = (cpBody*)lua_topointer(lua, 1);

    lua_rawgeti(lua, LUA_REGISTRYINDEX, (uint64_t)b->userData);
    /*stackDump(lua);*/
    /*printf("-----------------------\n");*/
    /*lua_pushstring(lua, "id");*/
    /*lua_gettable(lua, 6);*/
    /*stackDump(lua);*/
    /*luaL_checktype(lua, 7, LUA_TNUMBER);*/
    /*int id = (int)lua_tonumber(lua, 7);*/
    // печатать порядковый номер объекта
    /*printf("id = %d\n", id);*/

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

    cpShape *shape = cpSpaceAddShape(
            cur_space, 
            cpSegmentShapeNew(static_body, p1, p2, 0.0f)
        );
    cpShapeSetElasticity(shape, 1.0f);
    cpShapeSetFriction(shape, 1.0f);
    // что дает установка следующего фильтра?
    cpShapeSetFilter(shape, NOT_GRABBABLE_FILTER);

    lua_pushlightuserdata(lua, shape);

    return 1;
}

static int free_static_segment(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    assert(cur_space && "space is NULL");

    cpShape *shape = (cpShape*)lua_topointer(lua, 1);
    cpSpaceRemoveShape(cur_space, shape);
    cpShapeFree(shape);

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

void on_point_query(cpShape *shape, cpVect point, cpFloat distance, cpVect gradient, void *data) {
    lua_State *lua = (lua_State*)data;

    lua_pushlightuserdata(lua, shape);
    lua_pushnumber(lua, point.x);
    lua_pushnumber(lua, point.y);
    lua_pushnumber(lua, distance);
    lua_pushnumber(lua, gradient.x);
    lua_pushnumber(lua, gradient.x);

    /*stackDump(lua);*/
    /*printf("1111111111111111111");*/

    lua_call(lua, 6, 0);

    /*stackDump(lua);*/
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
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);
    
    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    return 1;
}

int get_body_stat(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expect 1 argument.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_topointer(lua, 1);

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

/*
 *    cpVect p = cpBodyGetPosition(b);
 *    cpVect cod = cpBodyGetCenterOfGravity(b);
 *    cpVect v = cpBodyGetVelocity(b);
 *    printf("mass %f moment %f px %f py %f\n", 
 *            cpBodyGetMass(b), 
 *            cpBodyGetMoment(b),
 *            cpBodyGetVelLimit
 *            cpBodyGetRotation(b),
 *            p.x, p.y);
 *
 *    printf(
 *        "m %f, i %f, cog %f, cog %f, pos %f, pos %f, vel %f, vel %f, "
 *        "for %f, for %f, ang %f, w %f, tor %f\n",
 *        b->m, b->i, b->cog.x, b->cog.y, b->p.x, b->p.y, b->v.x, b->v.y, 
 *        b->f.x, b->f.y, b->a, b->w, b->t
 *    );
 *
 */

    return 13;
}

static int set_torque(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 2) {
        lua_pushstring(lua, "Function expects 2 arguments.\n");
        lua_error(lua);
    }

    cpBody *body = (cpBody*)lua_topointer(lua, 1);
    double torque = lua_tonumber(lua, 2);

    cpBodySetTorque(body, torque);

    return 0;
}

static int get_body_type(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);

    int top = lua_gettop(lua);
    if (top != 1) {
        lua_pushstring(lua, "Function expects 1 argument.\n");
        lua_error(lua);
    }
    
    cpBody *body = (cpBody*)lua_topointer(lua, 1);
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
        // установить вращение тела
        {"set_torque", set_torque},
        {"get_body_type", get_body_type},

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
