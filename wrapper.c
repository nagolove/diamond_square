#include "chipmunk.h"
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdint.h>
#include <stdio.h>

/* The function we'll call from the lua script */
static int average(lua_State *L)
{
	/* get number of arguments */
	int n = lua_gettop(L);
	double sum = 0;
	int i;

	/* loop through each argument */
	for (i = 1; i <= n; i++)
	{
		if (!lua_isnumber(L, i)) 
		{
			lua_pushstring(L, "Incorrect argument to 'average'");
			lua_error(L);
		}

		/* total the arguments */
		sum += lua_tonumber(L, i);
	}

	/* push the average */
	lua_pushnumber(L, sum / n);

	/* push the sum */
	lua_pushnumber(L, sum);

	/* return the number of results */
	return 2;
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

typedef struct {
    int i1, i2, i3;
    double d4;
    uint8_t b5;
} Combo;

static int pass_combo(lua_State *lua) {
    Combo *combo = lua_topointer(lua, 1);
    printf("combo.i1 %d\n", combo->i1);
    printf("combo.i2 %d\n", combo->i2);
    printf("combo.i3 %d\n", combo->i3);
    printf("combo.d4 %f\n", combo->d4);
    printf("combo.b5 %d\n", combo->b5);
    return 0;
}

static int init_space(lua_State *lua) {
    int type = lua_type(lua, 1);
    printf("type %d\n", type);

    cur_space = lua_touserdata(lua, 1);
    printf("cur_space (userdata)%p\n", cur_space);

    cur_space = (cpSpace*)lua_topointer(lua, 1);
    printf("cur_space (pointer)%p\n", cur_space);

    return 0;
}

extern int luaopen_wrapper(lua_State *lua) {
    /*cpSpace *space = cpSpaceNew();*/
    static const struct luaL_Reg functions[] =
    {
         {"average", average},
         {"each_body", each_body},
         {"init_space", init_space},
         {"pass_combo", pass_combo},
         {NULL, NULL}
    };
    /*luaL_newlib(lua, functions);*/
    /*luaL_newlib(lua, functions);*/
    /*lua_register(lua, "wrapper", functions);*/
    luaL_register(lua, "wrapper", functions);
    printf("hello from C\n");
    return 1;
}
