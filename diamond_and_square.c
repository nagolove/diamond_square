// vim: set colorcolumn=85
// vim: fdm=marker

/*
// {{{
Попытка переписывания Lua модуля фрактального алгоритма генерации ландшафта.

Применение метода постоянно работающего кода.
Мыслить о задачах "наперед" - не слишком-ли долгое время займет переписывание?
(Дольше чем устройство и запуск Луа модуля как одиночной программы для
генерации кэша ландшафтов)

Возможно добавить вызов корутин для отображения прогресса генерации.
Использование различных проверок на выход на пределы массива и правильность
значений переменных.

Стоит уделять внимание прочитыванию кода всего модуля сверху-вниз. Для языка
типа C это хороший способ увидеть некоторые ошибки невнимательности.

Филосовский вопрос - стоит-ли переписывать модуль?
Практичный ответ - можно узнать итоговые различия в скорости генерации.
// }}}
*/

// {{{ Includes
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <math.h>
#include <stdlib.h>

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
// }}} 

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
    double *map;
    int mapSize;
    int chunkSize, roughness;
    int random_regindex; // LUA_REGISTRYINDEX функции обратного вызова ГПСЧ.
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

// Освобождает внутренние структуры данных если объект больше не будет
// использоваться.
int diamond_and_square_internal_free(lua_State *lua) {
    check_argsnum(lua, 1);
    Context *ctx = luaL_checkudata(lua, 1, "_DiamondSquare");
    if (ctx->map) {
        free(ctx->map);
        ctx->map = NULL;
    }
    return 0;
}

inline double map_set(Context *ctx, int i, int j, double value) {
#ifdef DEBUG
    if (i < 0 || i >= ctx->mapSize) {
        printf("map_set(): i out of range 0..%d\n", ctx->mapSize);
        abort();
    }
    if (j < 0 || j >= ctx->mapSize) {
        printf("map_set(): j out of range 0..%d\n", ctx->mapSize);
        abort();
    }
#endif
    return ctx->map[i * ctx->mapSize + j] = value;
}

inline double map_get(Context *ctx, int i, int j) {
#ifdef DEBUG
    if (i < 0 || i >= ctx->mapSize) {
        printf("map_set(): i out of range 0..%d\n", ctx->mapSize);
        abort();
    }
    if (j < 0 || j >= ctx->mapSize) {
        printf("map_set(): j out of range 0..%d\n", ctx->mapSize);
        abort();
    }
#endif
    return ctx->map[i * ctx->mapSize + j];
}

int diamond_and_square_new(lua_State *lua) {
    // {{{
    check_argsnum(lua, 2);
    luaL_checktype(lua, 1, LUA_TNUMBER);    // field size argument
    luaL_checktype(lua, 2, LUA_TFUNCTION);  // random function callback

    int mapn = ceil(lua_tonumber(lua, 1));

    Context *ctx = lua_newuserdata(lua, sizeof(Context));
    memset(ctx, 0, sizeof(Context));

    ctx->mapSize = pow(2, mapn) + 1;
    ctx->chunkSize = ctx->mapSize - 1;
    ctx->roughness = 2;
    ctx->map = calloc(sizeof(double), ctx->mapSize * ctx->mapSize);

    lua_pushvalue(lua, 2);
    ctx->random_regindex = lua_ref(lua, LUA_REGISTRYINDEX);
    /*lua_rawgeti(lua, LUA_REGISTRYINDEX, ctx->random_regindex);*/

    struct {
        int i, j;
    } corners[4] = {
        { .i = 1, .j = 1},
        { .i = ctx->mapSize, .j = 1},
        { .i = ctx->mapSize, .j = ctx->mapSize},
        { .i = 1, .j = ctx->mapSize},
    };

    LOG("diamond_and_square_new: [%s]\n", stack_dump(lua));

    // XXX Использование константы в сравнеии (i < 4)
    for(int corner_idx = 0; corner_idx < 4; ++corner_idx) {
        int i = corners[corner_idx].i;
        int j = corners[corner_idx].j;

        lua_pushvalue(lua, 2);
        lua_call(lua, 0, 1);
        double value = lua_tonumber(lua, -1);
        value = 0.5 - 0.5 * cos(value * M_PI);
        map_set(ctx, i, j, value);
    }

    LOG("diamond_and_square_new: [%s]\n", stack_dump(lua));

    return 1;
    // }}}
}

void square(Context *ctx) {
    int half = floor(ctx->chunkSize / 2.);
    for(int i = 0; i < ctx->mapSize - 1; i += ctx->chunkSize) {
        for(int j = 0; j < ctx->mapSize - 1; j += ctx->chunkSize) {
            double min = 0., max = 0.;
            /*square_value(ctx, i, j, half, NULL, &min, &max);*/
            double rnd_value = 0.;
            map_set(ctx, i + half, j + half, rnd_value);
        }
    }
}

int diamond_and_square_eval(lua_State *lua) {
    check_argsnum(lua, 1);
    Context *ctx = luaL_checkudata(lua, 1, "_DiamondSquare");

    if (!ctx->map) {
        lua_pushstring(lua, "diamond_and_square_eval: map was deallocated");
        lua_error(lua);
    }

    return 0;
}

int diamond_and_square_get(lua_State *lua) {
    // {{{
    check_argsnum(lua, 3);
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    luaL_checktype(lua, 2, LUA_TNUMBER);
    luaL_checktype(lua, 3, LUA_TNUMBER);
    Context *ctx = luaL_checkudata(lua, 1, "_DiamondSquare");
    int i = ceil(lua_tonumber(lua, 2));
    int j = ceil(lua_tonumber(lua, 3));

    /*
    char err_msg[64] = {0, };
    const char *format_msg = "diamond_and_square_get: '%s' out of range 0..%d";

    if (i < 0 || i >= ctx->mapSize) {
        sprintf(err_msg, format_msg, "i", ctx->mapSize);
        lua_pushstring(lua, err_msg);
    }

    if (j < 0 || j >= ctx->mapSize) {
        sprintf(err_msg, format_msg, "j", ctx->mapSize);
        lua_pushstring(lua, err_msg);
    }
    */

    lua_pushnumber(lua, map_get(ctx, i, j));

    return 1;
    // }}}
}

/*
int diamond_and_square_get_mapsize(lua_State *lua) {
    check_argsnum(lua, 1);
    luaL_checktype(lua, 1, LUA_TUSERDATA);
    Context *ctx = luaL_checkudata(lua, 1, "_DiamondSquare");
    lua_pushnumber(lua, ctx->mapSize);
    return 1;
}
*/

int register_module(lua_State *lua) {
    static const struct luaL_Reg functions[] =
    {
        // {{{
        {"diamond_and_square_new", diamond_and_square_new},
        {NULL, NULL}
        // }}}
    };
    luaL_register(lua, "diamond_and_square", functions);
    return 1;
}

static const struct luaL_Reg DiamondSquare_methods[] =
{
    // {{{
    {"internal_free", diamond_and_square_internal_free},
    {"eval", diamond_and_square_eval},
    {"get", diamond_and_square_get},
    {"get_mapsize", diamond_and_square_get_mapsize},
    {NULL, NULL}
    // }}}
};

extern int luaopen_wrp(lua_State *lua) {
    register_methods(lua, "_DiamondSquare", DiamondSquare_methods);
    printf("diamond&square module was opened [%s]\n", stack_dump(lua));
    return register_module(lua);
}

