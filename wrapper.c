#include "chipmunk.h"
#include <lua.h>
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

extern int luaopen_wrapper(lua_State *lua) {
    /*cpSpace *space = cpSpaceNew();*/
    static const struct luaL_Reg functions[2] =
    {
         {"average", average},
         {NULL, NULL}
    };
    lua_register(lua, "wrapper", functions);
    printf("hello from C\n");
    return 1;
}
