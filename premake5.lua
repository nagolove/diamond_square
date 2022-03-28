workspace "wrapper"
    configurations { "Debug", "Release" }

    project "wrp"
        kind "SharedLib"
        language "C"
        
        --targetdir "bin/%{cfg.buildcfg}"
        --targetdir "bin/%{cfg.buildcfg}"
        
        targetprefix ""
        targetdir "."

        files { "**.h", "**.c" }
        includedirs { 
            "/usr/include/luajit-2.1",
            --"~/projects/Chipmunk2D/include"
            "/home/nagolove/projects/Chipmunk2D/include",
            "/home/nagolove/myprojects/c_guard" 
        }
        buildoptions { 
            "-fPIC",
            "-Wall",
            "-Werror",
            "-Wno-strict-aliasing",
        }
        links { 
            "luajit-5.1", 
            "chipmunk",
            "mem_guard",
        }
        libdirs { 
            "/home/nagolove/projects/Chipmunk2D/src/",
            "/home/nagolove/myprojects/c_guard" 
        }
        --links { "lua5.1" }

    filter "configurations:Debug"
    defines { "DEBUG" }
    symbols "On"

    filter "configurations:Release"
    defines { "NDEBUG" }
    optimize "On"
