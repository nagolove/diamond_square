-- vim: fdm=marker
-- vim: set colorcolumn=85

return {
    language = "Русский",
    ru = {
        -- move tank
        mtleft = "двигаться танком вправо",
        mtright = "двигаться танком влево",
        mtforward = "двигаться танком вперед",
        mtbackward = "двигаться танком назад",

        -- move camera
        mcleft = "камеру влево",
        mcright = "камеру вправо",
        mcup = "камеру вверх",
        mcdown = "камеру вниз",

        commandmode = "перейти в командый режим",
        cam2tank = "переместитьт камеру к танку игрока",
        konsole = "скрыть или показать консоль",
        fire = "вести огонь",

        resetVelocities = "сбросить скорость",

        inserhangarmode = 'включить режим расстановки Ангаров',

        effecteditor = 'редактор эффектов',

        --[[
        -- {{{
        pos = "Положение", -- пространство
        position = "Положение", 
        sound = "Звук",
        form = "Форма",
        color = "Цвет",

        stat = "Статистика",
        mainMenu = {
            play = "Играть",
            viewProgress = "Смотреть прогресс",
            help = "Помощь",
            exit = "Выйти",
        },
        setupMenu = {
            start = "Начать",
            expTime = "Время экспозиции ",
            expTime_sec = " секунд",
            diffLevel = "Уровень сложности: ",
            dimLevel = "Размер поля:", -- разница между размерностью и размером поля.

            expTime_plural = {
                one = "Время экспозиции %{count} секунда",
                two = "Время экспозиции %{count} секунды",
                few = "Время экспозиции %{count} секунды",
                many = "Время экспозиции %{count} секунд",
                other = "Время экспозиции %{count} секунд",
            },
        },

        waitFor = {
            one = "Ждите %d секунду",
            few = "Ждите %d секунды",
            many = "Ждите %d секунд",
        },

        levelInfo1 = "Уровень %d Экспозиция %d секунд",
        levelInfo2 = "Продолжительность %d минут %d секунд",
        settingsBtn = "Настройки",
        backToMainMenu = "Вернуться в меню",
        quitBtn = "Закончить",

        nodata = "Пока нету законченных игр. Попробуйте сыграть.",
        today = "сегодня",
        yesterday = "вчера",
        twoDays = "два дня назад",
        threeDays = "три дня назад",
        fourDays = "четыре дня назад",
        fiveDays = "пять дней назад",
        sixDays = "шесть дней назад",
        lastWeek = "на прошлой неделе",
        lastTwoWeek = "две недели назад",
        lastMonth = "в прошлом месяце",
        lastYear = "в прошлом году",
        moreTime = "более года назад",


        levelInfo1_part1 = {
            one = "Продолжительность %{count} минута", 
            few = "Продолжительность %{count} минуты",
            many = "Продолжительность %{count} минут",
            other = "Продолжительность %{count} минут",
        },
        levelInfo1_part2 = {
            one = "%{count} секунда",
            few = "%{count} секунды",
            many = "%{count} секунд",
            other = "%{count} секунд",
        },

        levelInfo2_part1 = "Сложность %{count}",
        levelInfo2_part2 = {
            one = "Экспозиция %{count} секунда",
            few = "Экспозиция %{count} секунды",
            many = "Экспозиция %{count} секунд",
            other = "Экспозиция %{count} секунд",
        },

        help = {
            backButton = "Вернуться в меню",
        },
--]]
-- }}}

    },
}
