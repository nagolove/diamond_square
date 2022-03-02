#include "chipmunk/chipmunk.h"
#include "chipmunk/chipmunk_structs.h"

#include <assert.h>
#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

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
    cpFloat moment = cpMomentForBox(mass, w, h);
    printf("new_box_body\n");
    printf("mass %f moment %f\n", mass, moment);
    cpBody *b = cpBodyNew(mass, moment);

    if (!cur_space) {
        lua_pushstring(lua, "Space pointer is null.\n");
        lua_error(lua);
    }

    cpSpaceAddBody(cur_space, b);
    cpShape *shape = cpBoxShapeNew(b, w, h, 0.f);
    cpSpaceAddShape(cur_space, shape);

    // ссылка на табличку, связанную с телом
    int reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);
    b->userData = (void*)(uint64_t)reg_index;

    lua_pushlightuserdata(lua, b);

    return 1;
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
    stackDump(lua);
    printf("-----------------------\n");
    lua_pushstring(lua, "id");
    lua_gettable(lua, 6);
    stackDump(lua);
    luaL_checktype(lua, 7, LUA_TNUMBER);
    int id = (int)lua_tonumber(lua, 7);
    printf("id = %d\n", id);

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

extern int luaopen_wrp(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
         {"init_space", init_space},
         {"free_space", free_space},
         {"step", step},

         {"query_all_shapes", query_all_shapes},

         {"new_body", new_body},
         {"set_position", set_position},
         {"get_position", get_position},
         {"apply_impulse", apply_impulse},

         {"new_static_segment", new_static_segment},
         {"draw_static_segments", draw_static_segments},

         {NULL, NULL}
    };
    luaL_register(lua, "wrapper", functions);
    printf("wrp module opened\n");
    return 1;
}
