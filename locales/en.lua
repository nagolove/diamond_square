-- vim: fdm=marker
-- vim: set colorcolumn=85

return {
    language = "English",
    en = {
        mtleft = "move tank left",
        mtright = "move tank right",
        mtforward = "move tank forward",
        mtbackward = "move tank backward",

        mcleft = "move camera left",
        mcright = "move camera right",
        mcup = "move camera up",
        mcdown = "move camera down",
        commandmode = "go to command mode",

        --[[
        -- {{{
        pos = "Position", -- пространство(??)
        position = "Position",
        sound = "Sound",
        form = "Form",
        color = "Color",

        stat = "Statistic",
        mainMenu = {
            play = "play",
            viewProgress = "view progress",
            help = "help",
            exit = "exit",
        },
        setupMenu = {
            start = "Start",
            expTime = "Exposition time ",
            expTime_sec = " sec.",
            diffLevel = "Difficulty level: ",
            dimLevel = "Dim level: ", -- разница между размерностью и размером поля.

            expTime_plural = {
                one = "Exposition time %{count} second",
                two = "Exposition time %{count} seconds",
                few = "Exposition time %{count} seconds",
                many = "Exposition time %{count} seconds",
                other = "Exposition time %{count} seconds",
            },
        },

        waitFor = {
            one = "Wait for %d second",
            few = "Wait for %d seconds",
            many = "Wait for %d seconds",
        },

        levelInfo1 = "Уровень %d Экспозиция %d секунд",
        levelInfo2 = "Продолжительность %d минут %d секунд",
        settingsBtn = "Settings",
        backToMainMenu = "Back to menu",
        quitBtn = "Back to main", -- лучше назвать - "в главное меню?"

        nodata = "No fineshed games yet. Try to play.",
        today = "today",
        yesterday = "yesterday",
        twoDays = "two days ago",
        threeDays = "three days ago",
        fourDays = "four days ago",
        fiveDays = "five days ago",
        sixDays = "six days ago",
        lastWeek = "last week",
        lastTwoWeek = "last two week",
        lastMonth = "last month",
        lastYear = "last year",
        moreTime = "more year ago",

        levelInfo1_part1 = {
            one = "Duration %{count} minute",
            few = "Duration %{count} minutes",
            many = "Duration %{count} minutes",
            other = "Duration %{count} minutes",
        },
        levelInfo1_part2 = {
            one = "%{count} second",
            few = "%{count} seconds",
            many = "%{count} seconds",
            other = "%{count} seconds",
        },

        levelInfo2_part1 = "Level %{count}",
        levelInfo2_part2 = {
            one = "Exposition %{count} second",
            few = "Exposition %{count} seconds",
            many = "Exposition %{count} seconds",
            other = "Exposition %{count} seconds",
        },

        help = {
            backButton = "Back to main menu",
        },
        --]]
        -- }}}

    },
}

