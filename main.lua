--konfiguracja gry
local block_size = 30 -- rozmiar pojedynczego bloczku w pikselach
local columns = 10 -- liczba kolumn na planszy
local rows = 20 -- liczba wierszy na planszy
local speed = 100 -- szybkosc opadania klockow

--rozmiar okna
local windowWidth = (columns * block_size) + 200 -- szerokosc okna
local windowHeight = rows * block_size -- wysokosc okna

-- zmienne
local currentBlockX = 90
local currentBlockY = 90
local board = {} -- towrzenie planszy do gry
local currentBlock
local score = 0
local font
local gameOver = false


local blocks = { -- definiowanie ksztaltow bloczkow zlozonych z czterech kwadratow
    block_O = {
        shape = {
            {1, 1},
            {1, 1}
        },
        color = {1, 1, 0} -- zolty
    },
    block_I = {
        shape = {
            {1, 1, 1, 1}
        }, 
        color = {0, 1, 1} -- turkus
    },
    block_L = {
        shape = {
            {1, 0, 0},
            {1, 1, 1}
        },
        color = {0, 0, 1} -- niebeiski
    },
    block_L2 = {
        shape = {
            {0, 0, 1},
            {1, 1, 1}
        },
        color = {1, 0.5, 0} -- pomarancz
    },
    block_T = {
        shape = {
            {1, 1, 1},
            {0, 1, 0}
        },
        color = {0.5, 0, 1} -- fiolet
    },
    block_S = {
        shape = {
            {0, 1, 1},
            {1, 1, 0}
        },
        color = {0, 1, 0} -- zielony
    },
    block_Z = {
        shape = {
            {1, 1, 0},
            {0, 1, 1}
        },
        color = {1, 0, 0} -- czerwony
    }
}

local function getRandomBlock()
    local blockNames = {"block_O", "block_I", "block_L", "block_L2", "block_T", "block_S", "block_Z"}
    local randomName = blockNames[math.random(1, #blockNames)]
    return blocks[randomName]
end

local function drawBlocks(block, offsetX, offsetY) -- funkcja rysujaca bloczki
    love.graphics.setColor(block.color)
    for row = 1, #block.shape do
        for col = 1, #block.shape[row] do
            if block.shape[row][col] == 1 then
                local x = offsetX + (col-1) * block_size
                local y = offsetY + (row-1) * block_size
                love.graphics.rectangle("fill", x, y, block_size, block_size)
            end
        end
    end
end

function love.load()
    -- Ustawienia okna na podstawie planszy
    love.window.setMode(windowWidth, windowHeight)  -- Ustawia wymiary okna
    love.window.setTitle("Tetris")  -- Ustawia tytuł okna

    for y = 1, rows do
        board[y] = {}
        for x = 1, columns do
            board[y][x] = 0
        end
    end

    font = love.graphics.newFont(24) -- Rozmiar czcionki 24
    love.graphics.setFont(font)

    currentBlock = getRandomBlock()
end

local function checkCollision(block, offsetX, offsetY)
    for row = 1, #block.shape do
        for col = 1, #block.shape[row] do
            if block.shape[row][col] == 1 then
                local x = offsetX + (col - 1) * block_size
                local y = offsetY + (row - 1) * block_size

                -- Sprawdzenie kolizji z granicami planszy
                if x < 0 or x >= columns * block_size or y >= rows * block_size then
                    return true
                end

                -- Sprawdzenie kolizji z innymi blokami
                local boardX = math.floor(x / block_size) + 1
                local boardY = math.floor(y / block_size) + 1
                if board[boardY] and board[boardY][boardX] == 1 then
                    return true
                end
            end
        end
    end
    return false
end

local function isRowFull(row)
    for x = 1, columns do
        if board[row][x] == 0 then
            return false
        end
    end
    return true
end

local function clearFullRows()
    local rowsCleared = 0
    for y = rows, 1, -1 do -- Sprawdzamy od dołu planszy
        if isRowFull(y) then
            rowsCleared = rowsCleared + 1
            -- Usuń rząd i przesuń pozostałe w dół
            for pullY = y, 2, -1 do
                for x = 1, columns do
                    board[pullY][x] = board[pullY - 1][x]
                end
            end
            -- Wyczyszczenie górnego rzędu
            for x = 1, columns do
                board[1][x] = 0
            end
            y = y + 1 -- Sprawdź jeszcze raz ten sam rząd (bo wszystko się przesunęło)
        end
    end
    score = score + rowsCleared -- Dodaj punkty
end

local function updateBlockPosition(dt)
    if gameOver then 
        return
    end

    local newY = currentBlockY + speed * dt
    if not checkCollision(currentBlock, currentBlockX, newY) then
        currentBlockY = newY
    else
        -- Klocek dotknął dna, zapisz go na planszy
        for row = 1, #currentBlock.shape do
            for col = 1, #currentBlock.shape[row] do
                if currentBlock.shape[row][col] == 1 then
                    local x = currentBlockX + (col - 1) * block_size
                    local y = currentBlockY + (row - 1) * block_size
                    -- Jeśli x i y mieszczą się w granicach planszy
                    if math.floor(y / block_size) + 1 <= rows and math.floor(x / block_size) + 1 <= columns then
                        board[math.floor(y / block_size) + 1][math.floor(x / block_size) + 1] = 1
                    end
                end
            end
        end
        clearFullRows()
        -- Po zatrzymaniu, rozpoczynamy opadanie nowego klocka
        if board[1] and board[1][math.floor(currentBlockX / block_size) + 1] == 1 then
            gameOver = true
        else
        currentBlockX = math.floor(columns / 2) * block_size
        currentBlockY = 0

        currentBlock = getRandomBlock() -- Możesz zmienić na losowy klocek
        end
    end
end

local function rotateBlock(block)
    local newShape = {}
    for col = 1, #block.shape[1] do
        newShape[col] = {}
        for row = #block.shape, 1, -1 do
            newShape[col][#block.shape - row + 1] = block.shape[row][col]
        end
    end
    block.shape = newShape
end

function love.update(dt)
    updateBlockPosition(dt)
end

function love.keypressed(key)
    if gameOver then return end -- blokuje ruchy po zakonczeniu gry
    if key == "left" then
        currentBlockX = currentBlockX - block_size -- idzie w lewo
    elseif key == "right" then
        currentBlockX = currentBlockX + block_size -- idzie w prawo
    elseif key == "down" then
        currentBlockY = currentBlockY + block_size -- idzie szybciej w dol
    elseif key == "up" then
        rotateBlock(currentBlock)
    end
end

function love.draw()
    love.graphics.setColor(220/255, 220/255, 220/255)  -- kolor kratki planszy ustawilam na szary
    for y = 0, rows - 1 do
        for x = 0, columns - 1 do
            -- Rysujemy pojedynczy blok (siatka)
            love.graphics.rectangle("line", x * block_size, y * block_size, block_size, block_size)
        end
    end
    drawBlocks(currentBlock, currentBlockX, currentBlockY)
    
    for y = 1, rows do
        for x = 1, columns do
            if board[y][x] == 1 then
                love.graphics.setColor(0.5, 0.5, 0.5)  -- szary kolor zatrzymanych klocków
                love.graphics.rectangle("fill", (x - 1) * block_size, (y - 1) * block_size, block_size, block_size)
            end
        end
    end
    love.graphics.setColor(1, 1, 1) -- Biały kolor
    love.graphics.print("Score: " .. score, columns * block_size + 20, 20)

    if gameOver then
        love.graphics.setFont(love.graphics.newFont(34))
        love.graphics.setColor(1, 0, 0) -- Czerwony kolor napisu
        love.graphics.printf("GAME OVER", 0, windowHeight / 2, windowWidth, "center")
    end
end



