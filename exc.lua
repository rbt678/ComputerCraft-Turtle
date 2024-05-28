local pontoRetorno = {}
local posicaoAtual = {}
local ultimaPosicaoSalva = {}
local ultimaPosicaoTrabalho = {}
local arquivoUltimaPosicao = "ultimaPosicao.txt"
local arquivolistaCombustiveis = "listaCombustiveis.txt"
local combustiveisAceitos = {"coal", "log", "wood", "coke"}
local todasAsFalhas = {}
local tArgs = { ... }
local intensao = {voltando=false}
-- local fs,turtle,textutils,sleep,read,term

local function limparTela()
    term.clear()
    term.setCursorPos(1,1)
end

local function mensagemCentralizada(msg, apagarTela)
    -- Obter o tamanho da tela
    local largura, altura = term.getSize()
    local larguraAtual, alturaAtual = term.getCursorPos()
            
    -- Calcular o centro da tela
    local centroX = math.floor(largura / 2) - math.floor(#msg / 2)
    local centroY = (apagarTela) and (math.floor(altura / 2)) or (alturaAtual)
    
    -- Limpar a tela e posicionar o cursor no centro
    if apagarTela then term.clear() end
    term.setCursorPos(centroX, centroY)
    print(msg)
end

local function pressionarParaContinuar(mensagem)
    -- Exibe a mensagem, se fornecida
    if mensagem then
        print(mensagem)
    end
    -- Mostra a instrução para pressionar qualquer tecla
    print("\n\nPress any key...")
    -- Espera pelo evento de pressionar uma tecla
    os.pullEvent("key")
end

local function gerenciamentoDeArquivos()
    function SalvarUltimaPosicao()
        local file = fs.open(arquivoUltimaPosicao, "w")
        file.writeLine(textutils.serialize(posicaoAtual))
        file.close()
    end

    function CarregarUltimaPosicao()
        if fs.exists(arquivoUltimaPosicao) then
            local file = fs.open(arquivoUltimaPosicao, "r")
            ultimaPosicaoSalva = textutils.unserialize(file.readAll())
            file.close()
        else
            print(arquivoUltimaPosicao .. " não encontrado.")
        end
    end

    function SalvarListaCombustiveis(add)
        local add = add or false
        local modoDaEscrita = "w"
        if add then
            modoDaEscrita = "a"
        end
        local file = fs.open(arquivolistaCombustiveis, modoDaEscrita)
        local listaCombustiveis = {}
        
        local function getItemDetail()
            local item = turtle.getItemDetail()
            if item then
                table.insert(listaCombustiveis, item.name)
            end
        end
        OlharTodoOInventario(getItemDetail)
        
        file.writeLine(textutils.serialize(listaCombustiveis))
        file.close()
    end

    function CarregarListaCombustiveis()
        if fs.exists(arquivolistaCombustiveis) then
            local file = fs.open(arquivolistaCombustiveis, "r")
            combustiveisAceitos = textutils.unserialize(file.readAll())
            file.close()
        else
            print(arquivolistaCombustiveis .. " não encontrado.")
        end
    end
end
gerenciamentoDeArquivos()

local function salvarRazao(msg, razao)
    table.insert(todasAsFalhas, msg..(razao or ""))
    if razao then
        if string.find(razao,"unbreakable block") then
            print('\nBloco inquebrável encontrado. \nVoltando para o Ponto Retorno...')
            if RetornarAoPontoRetorno() then
                DroparItens()
            end
        end
    end
end

local function compararItemsComCombustiveisAceitos()
    for _, combustivel in ipairs(combustiveisAceitos) do
        local intemDetail = turtle.getItemDetail()
        if intemDetail then
            if string.find(intemDetail.name, combustivel) then
                return true
            end
        end
    end
    return false
end

function OlharTodoOInventario(funcaoDesejada)
    local sucesso = false
    for slot = 1, 16 do
        turtle.select(slot)
        local slotSucesso = funcaoDesejada()
        if slotSucesso then
            sucesso = true
        end
    end
    turtle.select(1)
    return sucesso
end

function DroparItens()
    local function drop()
        for _, value in ipairs(combustiveisAceitos) do
            if not compararItemsComCombustiveisAceitos() then
                turtle.drop()
            end
        end
    end
    OlharTodoOInventario(drop)
end

local function verificarCombustivel()
    local function procurarCombustivelNoinventario()
        local function reabastecer()
            local sucesso, razao = false, nil
            if compararItemsComCombustiveisAceitos() then
                sucesso, razao = turtle.refuel()
                if not sucesso then salvarRazao("procurarCombustivelNoinventario(): ", razao) end
            end
            return sucesso
        end
        return OlharTodoOInventario(reabastecer)
    end

    local function voltarParaOTrabalho()
        local sucesso, razao = false, nil
        sucesso, razao = MoverPara({x=ultimaPosicaoTrabalho.x, y=ultimaPosicaoTrabalho.y, z=ultimaPosicaoTrabalho.z, direcao=ultimaPosicaoTrabalho.direcao})
        if not sucesso then salvarRazao("voltarParaOTrabalho(): ", razao) end
        return sucesso
    end

    local combustivelNecessario = (math.abs(posicaoAtual.x - pontoRetorno.x)) + (math.abs(posicaoAtual.y - pontoRetorno.y)) + (math.abs(posicaoAtual.z - pontoRetorno.z)) + 2
    
    if turtle.getFuelLevel() <= combustivelNecessario then
        print('\nIrei ficar sem combustivel! \nProcurando algum no inventário...')
        if procurarCombustivelNoinventario() then
            print('\nEncontrei. \nVoltando a trabalho...')
        else
            print('\nNão encontrei. \nVou voltar ao Ponto de Retorno...')
            if not intensao.voltando then
                ultimaPosicaoTrabalho.x = posicaoAtual.x
                ultimaPosicaoTrabalho.y = posicaoAtual.y
                ultimaPosicaoTrabalho.z = posicaoAtual.z
                ultimaPosicaoTrabalho.direcao = posicaoAtual.direcao

                intensao.voltando = true
            end
            if RetornarAoPontoRetorno() then
                DroparItens()

                local combustivelNecessarioParaVoltarAoTrabalho = (math.abs(posicaoAtual.x - ultimaPosicaoTrabalho.x)) + (math.abs(posicaoAtual.y - ultimaPosicaoTrabalho.y)) + (math.abs(posicaoAtual.z - ultimaPosicaoTrabalho.z))
                print('\nPorfavor, adicione algum combustivel.')
                while (turtle.getFuelLevel() <= combustivelNecessarioParaVoltarAoTrabalho*3) do
                    if procurarCombustivelNoinventario() then
                        print(string.format('\nCombustivel atual: %d \nCombustivel mínimo necessário: %d', turtle.getFuelLevel(), combustivelNecessarioParaVoltarAoTrabalho*3))
                    end
                end

                print('\nTanque abastecido. Voltando ao trabalho...')
                if voltarParaOTrabalho() then
                    print('\nVoltei ao ponto do trabalho')
                    intensao.voltando = false
                end
            end
        end
    end
end

local function mudarPosicao(args)
    if (not args.pularVerificacaoCombustivel) and (not intensao.voltando) then
            verificarCombustivel()
    end

    args = args or {}
    local x = args.x or posicaoAtual.x
    local y = args.y or posicaoAtual.y
    local z = args.z or posicaoAtual.z
    local direcao = args.direcao or posicaoAtual.direcao

    posicaoAtual.x = x
    posicaoAtual.y = y
    posicaoAtual.z = z
    posicaoAtual.direcao = direcao

    SalvarUltimaPosicao()
end

local function movimentacao()
    function Virar(difDir)
        -- norte é igual a -z no mundo
        -- sul é igual a +z no mundo
        -- leste é igual a +x no mundo
        -- oeste é igual a -x no mundo

        -- Tabela que mapeia direções opostas
        local direcoesOpostas = {
            norte = "sul",
            sul = "norte",
            leste = "oeste",
            oeste = "leste"
        }
    
        -- Tabela que mapeia os comandos de rotação
        local comandosRotacao = {
            norte = {leste = "turnRight", oeste = "turnLeft"},
            sul = {leste = "turnLeft", oeste = "turnRight"},
            leste = {norte = "turnLeft", sul = "turnRight"},
            oeste = {norte = "turnRight", sul = "turnLeft"}
        }
    
        -- Função para girar a tartaruga para uma direção especificada
        local function girarPara(direcao)
            local sucesso, razao = true, nil
            local comando = comandosRotacao[posicaoAtual.direcao][direcao]
            mudarPosicao({direcao = direcao})
            sucesso, razao = turtle[comando]()
            if not sucesso then salvarRazao("girarPara(): ", razao) end
            
            if not sucesso then
                mudarPosicao({direcao = posicaoAtual.direcao})
            end
            return sucesso
        end

        local sucesso, razao = true, nil
        -- Mantem a posicao
        if posicaoAtual.direcao == difDir then
            sucesso = true

        elseif difDir == direcoesOpostas[posicaoAtual.direcao] then
            -- Girar 180 graus
            local primeiraRotacao = (posicaoAtual.direcao == "norte" or posicaoAtual.direcao == "sul") and "leste" or "norte"
            sucesso, razao = girarPara(primeiraRotacao)
            if not sucesso then salvarRazao("Virar(): ", razao) end
            if sucesso then
                sucesso, razao = girarPara(difDir)
                if not sucesso then salvarRazao("Virar(): ", razao) end
            end
        else
            -- Girar 90 graus
            sucesso, razao = girarPara(difDir)
            if not sucesso then salvarRazao("Virar(): ", razao) end
        end

        return sucesso
    end

    -- Função auxiliar para mover a tartaruga
    local function mover(eixo, delta, moverFunc, digFunc, atualizarPosicao, voltarDirecao)
        local sucesso, razao = true, nil
        local posicaoOriginal = posicaoAtual[eixo]
        local direcaoOriginal = posicaoAtual.direcao

        -- Atualiza a posição
        mudarPosicao({[eixo] = posicaoOriginal + delta})
        sucesso, razao = turtle[moverFunc]()
        if not sucesso then salvarRazao("mover(): ", razao) end
        if not sucesso then
            -- Reverte a posição se o movimento falhar
            mudarPosicao({[eixo] = posicaoOriginal})

            -- Apenas para a funcao Voltar()
            if voltarDirecao then
                sucesso, razao = Virar(voltarDirecao)
                if not sucesso then salvarRazao("mover(): ", razao) end
            end

            sucesso, razao = turtle[digFunc]()
            if not sucesso then salvarRazao("mover(): ", razao) end
            if not sucesso then
                sucesso = false
            else
                -- Tenta mover novamente após cavar
                sucesso, razao = mover(eixo, delta, (voltarDirecao) and "forward" or moverFunc, digFunc, atualizarPosicao)
                if not sucesso then salvarRazao("mover(): ", razao) end
            end

            -- Apenas para a funcao Voltar()
            if voltarDirecao then
                sucesso, razao = Virar(direcaoOriginal)
                if not sucesso then salvarRazao("mover(): ", razao) end
            end
        end
        return sucesso
    end

    -- Funções de movimentação
    function Subir()
        return mover('y', 1, 'up', 'digUp', mudarPosicao)
    end

    function Descer()
        return mover('y', -1, 'down', 'digDown', mudarPosicao)
    end

    function Avancar()
        local direcaoDelta = {
            norte = {eixo = 'z', delta = -1},
            sul = {eixo = 'z', delta = 1},
            leste = {eixo = 'x', delta = 1},
            oeste = {eixo = 'x', delta = -1}
        }
        local direcaoAtual = direcaoDelta[posicaoAtual.direcao]
        return mover(direcaoAtual.eixo, direcaoAtual.delta, 'forward', 'dig', mudarPosicao)
    end

    function Voltar()
        local direcaoDelta = {
            norte = {eixo = 'z', delta = 1, voltarDirecao = 'sul'},
            sul = {eixo = 'z', delta = -1, voltarDirecao = 'norte'},
            leste = {eixo = 'x', delta = -1, voltarDirecao = 'oeste'},
            oeste = {eixo = 'x', delta = 1, voltarDirecao = 'leste'}
        }
        local direcaoAtual = direcaoDelta[posicaoAtual.direcao]
        return mover(direcaoAtual.eixo, direcaoAtual.delta, 'back', 'dig', mudarPosicao, direcaoAtual.voltarDirecao)
    end

    function MoverPara(args) -- Fazer com que aceite argumentos especificos
        local x = args.x or posicaoAtual.x
        local y = args.y or posicaoAtual.y
        local z = args.z or posicaoAtual.z
        local direcao = args.direcao or posicaoAtual.direcao

        local function mover(dif, direcaoPositiva, direcaoNegativa)
            local sucesso, razao = true, nil

            for i = 1, math.abs(dif) do
                if dif >= 0 then
                    if direcaoPositiva == nil then
                        sucesso, razao = Subir()
                        if not sucesso then salvarRazao("MoverPara(): ", razao) end
                    else
                        Virar(direcaoPositiva)
                        sucesso, razao = Avancar()
                        if not sucesso then salvarRazao("MoverPara(): ", razao) end
                    end
                    if not sucesso then return sucesso end
                else
                    if direcaoPositiva == nil then
                        sucesso, razao = Descer()
                        if not sucesso then salvarRazao("MoverPara(): ", razao) end
                    else
                        Virar(direcaoNegativa)
                        sucesso, razao = Avancar()
                        if not sucesso then salvarRazao("MoverPara(): ", razao) end
                    end
                    if not sucesso then return sucesso end
                end
            end
            return sucesso
        end

        -- Cálculo das diferenças
        local difX = tonumber(x) - posicaoAtual.x
        local difY = tonumber(y) - posicaoAtual.y
        local difZ = tonumber(z) - posicaoAtual.z
        local distanciaTotal = difX+difY+difZ

        -- Movimentação vertical
        local sucesso, razao = mover(difY)
        if not sucesso then salvarRazao("MoverPara(): ", razao) end
        if not sucesso then return sucesso end

        -- Movimentação horizontal em X
        sucesso, razao = mover(difX, "leste", "oeste")
        if not sucesso then salvarRazao("MoverPara(): ", razao) end
        if not sucesso then return sucesso end

        -- Movimentação horizontal em Z
        sucesso, razao = mover(difZ, "sul", "norte")
        if not sucesso then salvarRazao("MoverPara(): ", razao) end
        if not sucesso then return sucesso end

        -- Ajusta a direção finalw
        Virar(direcao)
        return sucesso
    end

    function RetornarAoPontoRetorno()
        local sucesso, razao = false, nil
        sucesso, razao = MoverPara({x=pontoRetorno.x, y=pontoRetorno.y, z=pontoRetorno.z, direcao=pontoRetorno.direcao})
        if not sucesso then salvarRazao("RetornarAoPontoRetorno(): ", razao) end
        return sucesso
    end
end
movimentacao()

local function usarUltimaPosicaoComoPosicaoAtual()
    posicaoAtual.x=ultimaPosicaoSalva.x
    posicaoAtual.y=ultimaPosicaoSalva.y
    posicaoAtual.z=ultimaPosicaoSalva.z
    posicaoAtual.direcao=ultimaPosicaoSalva.direcao
end

local function menuInterativo(args)
    local titulo = args.titulo or "MENU"
    local texto = args.texto or ""
    local opcoes = args.opcoes or {}
    local acoes = args.acoes or {}
    local tratarResposta = args.tratarResposta or nil
    local respostaValida = false
    
    while not respostaValida do
        limparTela()
        mensagemCentralizada("### "..titulo.." ###",false)
        print(texto)
        
        for key, opcao in pairs(opcoes) do
            print(string.format("<%s> - %s", string.upper(key), opcao))
        end
        
        local resposta = read()
        local indice = string.lower(resposta)
        
        if tratarResposta then
            respostaValida = tratarResposta(resposta)
        elseif indice and acoes[indice] then
            respostaValida = true
            acoes[indice]()
        else
            mensagemCentralizada('Resposta inválida', true)
            sleep(1)
        end
    end
    return true
end

local function tratarPosicao(resposta, estrutura, posicao, permitirVazio)
    local function respostaIncorreta()
        term.clear()
        print(string.format("%s\nResposta incorreta.\n\nA resposta deve seguir a seguinte estrutura: \t\t%s", resposta, estrutura))
        pressionarParaContinuar()
        return false
    end
    
    if permitirVazio and resposta == "" then
        return true
    end
    
    local posicaoTabela = {}
    for pos in resposta:gmatch("([^,]+),?") do
        local valor = tonumber(pos)
        if valor then
            table.insert(posicaoTabela, valor)
        elseif (pos == "norte") or (pos == "sul") or (pos == "leste") or (pos == "oeste") then
            table.insert(posicaoTabela, pos)
        else
            return respostaIncorreta()
        end
    end
    
    if #posicaoTabela ~= 4 then
        return respostaIncorreta()
    end
    
    posicao.x = posicaoTabela[1]
    posicao.y = posicaoTabela[2]
    posicao.z = posicaoTabela[3]
    posicao.direcao = posicaoTabela[4]
    return true
end

local function definirPosicaoAtual()
    CarregarUltimaPosicao()
    local titulo = "Posição Atual do Turtle"

    local function definirManualmente()
        local estrutura = "<X,Y,Z,DIRECAO>\n direcao = 'norte', 'sul', 'leste' ou 'oeste'"
        local texto = "Por favor, digite a posição atual do Turtle: \n\n\t\t"..estrutura.."\n"
    
        local function tratarResposta(resposta)
            local posicao = {}
            local sucesso = tratarPosicao(resposta, estrutura, posicao, false)
            if sucesso then
                mudarPosicao({x = posicao.x, y = posicao.y, z = posicao.z, direcao = posicao.direcao, pularVerificacaoCombustivel = true})
            end
            return sucesso
        end
    
        return menuInterativo({titulo = titulo, texto=texto, tratarResposta = tratarResposta})
    end

    local function usarUltimaPosicao()
        local texto = string.format('Posição atual do Turtle é essa? \n\n\t\tX: %d \n\t\tY: %d \n\t\tZ: %d \n\t\tDirecao: %s\n', ultimaPosicaoSalva.x,ultimaPosicaoSalva.y,ultimaPosicaoSalva.z,ultimaPosicaoSalva.direcao)
        local opcoes = {S = "Sim", N = "Não"}
        local acoes = {
            ['s'] = function() usarUltimaPosicaoComoPosicaoAtual() end,
            ['n'] = function() definirManualmente() end
        }
        return menuInterativo({titulo=titulo, texto=texto,opcoes=opcoes,acoes=acoes})
    end
    

    if ultimaPosicaoSalva.x then
        for key, value in pairs(ultimaPosicaoSalva) do
            print(key, value)
        end
        return usarUltimaPosicao()
    else
        return definirManualmente()
    end
end

local function definirPontoRetorno()
    local titulo = "Definir Ponto de Retorno"
    local estrutura = "<X,Y,Z,DIRECAO>\n direcao = 'norte', 'sul', 'leste' ou 'oeste'"
    local texto = "Por favor, digite o ponto de retorno do Turtle: \n\n\t\t"..estrutura.."\nDeixe vazio para usar a posição atual: "

    local function tratarResposta(resposta)
        if resposta == "" then
            pontoRetorno.x = posicaoAtual.x
            pontoRetorno.y = posicaoAtual.y
            pontoRetorno.z = posicaoAtual.z
            pontoRetorno.direcao = posicaoAtual.direcao
            return true
        else
            return tratarPosicao(resposta, estrutura, pontoRetorno, false)
        end
    end

    return menuInterativo({titulo = titulo, texto=texto, tratarResposta = tratarResposta})
end

local function extrairPosicaodeString(string)
    local sucesso = true
    local msgErro = ""

    local function validarDirecao(direcao)
        return direcao == "norte" or direcao == "sul" or direcao == "leste" or direcao == "oeste"
    end
    
    local function validarNumero(valor)
        return tonumber(valor) ~= nil
    end
    
    local function adicionarValor(tabela, chave, valor)
        if chave == "direcao" then
            if validarDirecao(valor) then
                tabela[chave] = valor
            else
                msgErro = "Valor inválido para direcao"
                sucesso=false
                mensagemCentralizada(msgErro,true)
                sleep(1)
            end
        elseif chave == "x" or chave == "y" or chave == "z" then
            if validarNumero(valor) then
                tabela[chave] = tonumber(valor)
            else
                msgErro = "Valor inválido para " .. chave
                sucesso=false
                mensagemCentralizada(msgErro,true)
                sleep(1)
            end
        else
            msgErro = "Chave inválida: " .. chave
            sucesso=false
            mensagemCentralizada(msgErro,true)
            sleep(1)
        end
    end
    
    local posicao = {}

    if string:find("=") then
        -- Se a string contém "=", assume que é no formato chave=valor
        for key, value in string:gmatch("(%w+)=([^,]+)") do
            adicionarValor(posicao, key, value)
        end
    else
        -- Caso contrário, assume que é no formato valores diretos separados por vírgulas
        local chaves = {"x", "y", "z", "direcao"}
        local valores = {}
        for valor in string:gmatch("([^,]+)") do
            table.insert(valores, valor)
        end

        for i, valor in ipairs(valores) do
            if i > #chaves then
                msgErro="Número excessivo de valores fornecidos"
                sucesso=false
                mensagemCentralizada(msgErro,true)
                sleep(1)
                break
            end
            adicionarValor(posicao, chaves[i], valor)
        end
    end

    return sucesso, posicao
end

local function moverTurtleUser()
    local estrutura = "<X,Y,Z,DIRECAO>\n direcao = 'norte', 'sul', 'leste' ou 'oeste'"
    local titulo = "Mover Para"
    local texto = "Por favor, digite a posição para onde o Turtle deve ir: "
    
    local function tratarResposta(resposta)
        local sucesso, posicao = extrairPosicaodeString(resposta)
        if sucesso then
            MoverPara(posicao)
        end
        return sucesso
    end

    menuInterativo({titulo=titulo, texto=texto, tratarResposta=tratarResposta})
end

local function interface()
    local texto = "Olá, oque deseja fazer?"
    local opcoes = {"Virar", "Filtrar Combustiveis", "Mover"}
    local acoes = {
        ['1']=function() Virar('sul') end,
        ['2']=function() SalvarListaCombustiveis() CarregarListaCombustiveis() end,
        ['3']=function() moverTurtleUser() end
    }

    return menuInterativo({texto=texto, opcoes=opcoes, acoes=acoes})
end

local function main()
    limparTela()
    if definirPosicaoAtual() then
        if definirPontoRetorno() then
            interface()
        end
    end
end

main()