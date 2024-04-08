#!/bin/bash

# Gobal variables
fileStatus=()
fileList=()
numberOfFilesWithSensitiveData=0
folder=$(dirname "$(pwd)")
OPENAI_API_PROMPT="Valide se o seguinte código contém menções a dados sensíveis segundo a LGPD \
(Lei Geral de Proteção de Dados). Sua resposta deve ser 'OK - Não foram encontrados dados sensíveis' no ca\
so de não haver dados sensíveis. Caso contrário, deve ser 'Atenção - (listar quais dados sensíveis foram m\
encionados no código, separados por vírgula e entre parenteses na frente de cada um dos dados insira a inf\
ormação de presença de processo criptografia do dado). (Exemplo: Atenção - CPF (Não criptografado), RG (Cri\
ptografado))'. Sua resposta deve ser apenas ao que eu indiquei e nada mais, Segue o código em HEX, desconverta-o:"

# Text formating variables
BOLD="\e[1m"
RESET="\e[0m"

banner(){
    echo
    echo "***************************************************************************************"
    echo
    echo "  _      _____ _____  _____              _____     _____ _               _             "
    echo " | |    / ____|  __ \|  __ \       /\   |_   _|   / ____| |             | |            "
    echo " | |   | |  __| |__) | |  | |     /  \    | |    | |    | |__   ___  ___| | _____ _ __ "
    echo " | |   | | |_ |  ___/| |  | |    / /\ \   | |    | |    | '_ \ / _ \/ __| |/ / _ \ '__|"
    echo " | |___| |__| | |    | |__| |   / ____ \ _| |_   | |____| | | |  __/ (__|   <  __/ |   "
    echo " |______\_____|_|    |_____/   /_/    \_\_____|   \_____|_| |_|\___|\___|_|\_\___|_|   "
    echo "                                                                                       "
}

# "hexadecimals to the rescue"
fileToHex() {
    local file="$codeFile"
    local hex=""
    
    if [ -f "$file" ]; then
        hex=$(xxd -p "$file")
    else
        echo "Arquivo '$file' não encontrado."
        return 1
    fi
    
    hexString=""
    while IFS= read -r line; do
        hexString="$hexString$line"
    done <<< "$hex"
}

checkValidAPIAnswer(){
    # Uncomment if in need to debug
    #echo "API Anwser:"
    #echo "$apiAnswer"

    if ! [ $? ]; then
        echo -e "❌ ${BOLD}Erro: Falha ao enviar '$codeFile'${RESET}"
        exit 1
    fi

    if grep -q "invalid_api_key" <<< "$apiAnswer"; then
        echo -e "❌ ${BOLD}Erro: Chave de API inválida ${RESET}"
        exit 1
    fi

    if grep -q "unknown_url" <<< "$apiAnswer"; then
        echo -e "❌ ${BOLD}Erro: URL do endpoint inválida ${RESET}"
        exit 1
    fi
}

sendMessage() {
    fileToHex

    apiAnswer=$(curl -s -X POST "$OPENAI_API_ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d '{
            "model": "'"$OPENAI_API_MODEL"'",
            "messages": [
            {
                "role": "user",
                "content": "'"$OPENAI_API_PROMPT"' '"$hexString"'"
            }
            ]
        }'
    )

    checkValidAPIAnswer
}

saveAPIAnswer(){
    fileList+=("$codeFile")
    fileStatus+=("$(jq -r '.choices[0].message.content' <<< "$apiAnswer")")
}

generateLog(){
    if [[ ! "${fileStatus[i]}" =~ "Atenção" ]]; then
        echo -e "Arquivo: '${fileList[i]}'"
        echo -e "Status: '${fileStatus[i]}'\n"
    else
        echo -e "⚠️  ${BOLD} Arquivo: '${fileList[i]}' ${RESET}"
        echo -e "⚠️  ${BOLD} Status: '${fileStatus[i]}' ${RESET}\n"
    fi
}

checkIfSensitiveDataIsFound() {
    local status="${fileStatus[$i]}"  # Captura o elemento do array na posição $i
    if [[ $status == "Atenção"* ]]; then
        ((numberOfFilesWithSensitiveData++))
    fi
}

successCenario(){
    echo -e "✅ ${BOLD}Não foram encontrados arquivos com menções a dados sensiveis relativos a LGPD.${RESET}\n\n"
    
    exit 0
}

warningCenario(){
    echo -e "⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️"
    echo -e "⚠️"
    echo -e "⚠️  ${BOLD}Foram encontrados $numberOfFilesWithSensitiveData arquivo(s) com menções a dados sensiveis relativos a LGPD, veja o log acima para mais detalhes.${RESET}"
    echo -e "⚠️"
    echo -e "⚠️  Certifique-se de realizar o tratamento adequado dos dados de acordo com a:"
    echo -e "⚠️  🌐 ${BOLD}\e]8;;https://www.planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709.htm\a[LINK] LEI Nº 13.709, DE 14 DE AGOSTO DE 2018 🌐\e]8;;\a${RESET}"
    echo -e "⚠️"
    echo -e "⚠️  Veja esse artigo da SERPRO.GOV com mais detalhes sobre como conduzir o processo de tratamento adequado: "
    echo -e "⚠️  🌐 ${BOLD}\e]8;;https://www.serpro.gov.br/menu/noticias/noticias-2023/dados-pessoais-sensiveis-e-nao-sensiveis\a[LINK] Como as empresas devem tratar os dados pessoais sensíveis e não sensíveis? 🌐\e]8;;\a${RESET}"
    echo -e "⚠️"
    echo -e "⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️ ⚠️\n\n"
    
    exit 0
}

checkNumberOfFilesWithSensitiveDataFound() {
    if [[ $numberOfFilesWithSensitiveData -eq 0 ]]; then
        successCenario
    else
        warningCenario 
    fi 
}

findFiles() {
    i=0
    echo -e "\nIniciando escaneamento e enviando arquivos para API\n"
    
    while read -r codeFile; do
        sendMessage
        saveAPIAnswer
        generateLog
        checkIfSensitiveDataIsFound

        ((i++))
    done < <(find "$folder" -type f \( -name "*.json" -o -name "*.java" -o -name "*.c" -o -name "*.cpp" -o -name "*.h" -o -name "*.hpp" -o -name "*.go" -o -name "*.js" -o -name "*.sql" -o -name "*.properties" -o -name "*.py" -o -name "*.yml" -o -name "*.yaml" \))
    
    if (( i == 0 )); then
        echo -e "❌ ${BOLD}Erro: Não foram encontrados arquivos para escanear${RESET}\n\n"
        exit 1
    fi
}

main() {
    banner
    findFiles
    checkNumberOfFilesWithSensitiveDataFound
}