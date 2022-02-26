#include "chipmunk/chipmunk.h"
#include "chipmunk/chipmunk_structs.h"
#include <assert.h>
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdint.h>
#include <stdio.h>

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
    return 1;
}

static int free_space(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);
    cpSpace *space = (cpSpace*)lua_topointer(lua, 1);
    cpSpaceFree(space);
}

#define DENSITY (1.0/10000.0)

static int new_box_body(lua_State *lua) {
    // in: ширина, высота, таблица с инфой

    int top = lua_gettop(lua);
    if (top != 3) {
        lua_pushstring(lua, "Function should receive only 3 arguments.\n");
        lua_error(lua);
    }

    luaL_checktype(lua, 1, LUA_TNUMBER);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TTABLE);

    int w = (int)lua_tonumber(lua, 1);
    int h = (int)lua_tonumber(lua, 2);

    cpFloat mass = w * h * DENSITY;
    cpFloat moment = cpMomentForBox(mass, w, h);
    cpBody *b = cpBodyNew(mass, moment);

    if (!cur_space) {
        lua_pushstring(lua, "Space pointer is null.\n");
        lua_error(lua);
    }

    cpSpaceAddBody(cur_space, b);

    // ссылка на табличку, связанную с телом
    int reg_index = luaL_ref(lua, LUA_REGISTRYINDEX);
    b->userData = (void*)(uint64_t)reg_index;

    lua_pushlightuserdata(lua, b);

    return 1;
}

void on_each_body(cpBody *body, void *data) {
    printf("on_each_body\n");
}

void print_space_info(cpSpace *space) {
    printf("iterations %d\n", space->iterations);
    printf("damping %f\n", space->damping);
    printf("data %p\n", space->userData);
    printf("curr_dt %f\n", space->curr_dt);
    printf("stamp %d\n", space->stamp);
}

static int query_all_shapes(lua_State *lua) {
    printf("cur_space %p\n", cur_space);
    print_space_info(cur_space);
    assert(cur_space);

    printf("C: query_all_shapes\n");

    luaL_checktype(lua, 1, LUA_TFUNCTION);

    cpSpaceEachBody(cur_space, on_each_body, NULL);
    /*cpSpaceEachBody(cur_space, NULL, NULL);*/

    printf("C: query_all_shapes after\n");
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
    cpSpaceStep(cur_space, dt);

    return 0;
}

static int set_position(lua_State *lua) {
    luaL_checktype(lua, 1, LUA_TLIGHTUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);

    int top = lua_gettop(lua);
    if (top != 3) {
        lua_pushstring(lua, "Function expect 3 argument.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_topointer(lua, 1);
    double x = lua_tonumber(lua, 1);
    double y = lua_tonumber(lua, 2);
    cpVect pos = { .x = x, .y = y};
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
        lua_pushstring(lua, "Function expect 5 argument.\n");
        lua_error(lua);
    }

    cpBody *b = (cpBody*)lua_topointer(lua, 1);
    cpBodyApplyImpulseAtLocalPoint(b, impulse, point);

    return 0;
}

extern int luaopen_wrp(lua_State *lua) {
    /*cpSpace *space = cpSpaceNew();*/
    static const struct luaL_Reg functions[] =
    {
         {"init_space", init_space},
         {"free_space", free_space},
         {"step", step},

         {"query_all_shapes", query_all_shapes},

         {"new_box_body", new_box_body},
         {"set_position", set_position},
         {"apply_impulse", apply_impulse},

         {NULL, NULL}
    };
    /*luaL_newlib(lua, functions);*/
    /*luaL_newlib(lua, functions);*/
    /*lua_register(lua, "wrapper", functions);*/
    luaL_register(lua, "wrapper", functions);
    printf("hello from C\n");
    return 1;
}
