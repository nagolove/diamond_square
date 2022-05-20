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

/*#include "chipmunk/chipmunk.h"*/
/*#include "chipmunk/chipmunk_structs.h"*/
/*#include "chipmunk/chipmunk_private.h"*/

/*#include "cpVect.h"*/
#include "lua_tools.h"

// Проверить указатель на текущее физическое пространство.
// Вызвать ошибку Lua в случае пустого указателя.
#define CHECK_SPACE \
if (!cur_space) {                                       \
    lua_pushstring(lua, "cur_space pointer is null.\n");\
    lua_error(lua);                                     \
}                                                       \

typedef struct {
    // {{{
    double **map;
    int mapSize;
    int chunkSize, roughness;
    // }}}
} Context;

#ifdef DEBUG
// {{{

#define LOG(...)        \
    printf(__VA_ARGS__);\

#else

#define LOG(...) \
    do {} while(0);

// }}}
#endif // DEBUG

void uint64t_to_bitstr(uint64_t value, char *buf) {
    // {{{
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
    // }}}
}

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
 
int diamond_and_square_new(lua_State *lua) {
    return 0;
}

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"diamond_and_square_new", diamond_and_square_new},
        {NULL, NULL}
        // }}}
    };
    luaL_register(lua, "wrapper", functions);
    return 1;
}

static const struct luaL_Reg DiamondSquare_methods[] =
{
    // {{{
    /*{"new", bulletpool_new},*/
    {NULL, NULL}
    // }}}
};

extern int luaopen_wrp(lua_State *lua) {
    register_methods(lua, "_DiamondSquare", DiamondSquare_methods);
    printf("diamond&square module was opened [%s]\n", stack_dump(lua));
    return register_module(lua);
}

