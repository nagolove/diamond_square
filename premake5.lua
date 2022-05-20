workspace "wrapper"
    configurations { "Debug", "Release" }

    includedirs { 
        "/usr/include/luajit-2.1",
        --"~/projects/Chipmunk2D/include"
        "/home/nagolove/projects/Chipmunk2D/include",
        "/home/nagolove/myprojects/lua_capi",
    }
    buildoptions { 
        "-fPIC",
        "-Wall",
        "-Werror",
        "-Wno-strict-aliasing",
        --"-Wno-unused-function",
    }
    links { 
        --"luajit-5.1", 
        "lua5.1",
        "chipmunk",
        "mem_guard",
        "lua_tools",
    }
    libdirs { 
        "/home/nagolove/projects/Chipmunk2D/src/",
        "/home/nagolove/myprojects/c_guard",
        "/home/nagolove/myprojects/lua_capi",
    }
    language "C"
    kind "SharedLib"
    --targetdir "bin/%{cfg.buildcfg}"
    --targetdir "bin/%{cfg.buildcfg}"
    targetprefix ""
    targetdir "."

    project "wrp"
        files { "**.h", "wrapper.c" }
        --links { "lua5.1" }
    project "diamond_and_square"
        files { "**.h", "diamond_and_square.c" }
        --links { "lua5.1" }


    filter "configurations:Debug"
    defines { "DEBUG" }
    symbols "On"

    filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "On"
