#!/bin/bash

# ====================================================================
# Скрипт для обработки прокси-серверов с заданным форматом вывода
# ====================================================================

# Файл для сохранения обработанных прокси
OUTPUT_FILE="output_proxies.txt"

# ====================================================================
# Цветовые коды для улучшения вывода
# ====================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ====================================================================
# Функция для вывода стилизованной надписи "CAPTAIN PEPE"
# ====================================================================
print_logo() {
    echo -e "${CYAN}"
    echo "   _____            _        ____        _   _          _  _  _  "
    echo "  / ____|          | |      |  _ \      | | | |        | || | | "
    echo " | |     ___  _ __ | |_ __ _| |_) | ___ | |_| | ___  __| || | | "
    echo " | |    / _ \| '_ \| __/ _\` |  _ < / _ \| __| |/ _ \/ _\` || | | "
    echo " | |___| (_) | | | | || (_| | |_) | (_) | |_| |  __/ (_| || |_| "
    echo "  \_____\___/|_| |_|\__\__,_|____/ \___/ \__|_|\___|\__,_| \___/ "
    echo ""
    echo -e "${NC}"
}

# ====================================================================
# Функции для проверки корректности IP-адреса и порта
# ====================================================================

# Функция для проверки корректности IP-адреса
is_valid_ip() {
    local ip=$1
    local IFS='.'
    local -a octets=($ip)

    # Проверка, что IP состоит из 4 октетов
    if [ ${#octets[@]} -ne 4 ]; then
        return 1
    fi

    for octet in "${octets[@]}"; do
        # Проверка, что октет является числом
        if ! [[ $octet =~ ^[0-9]+$ ]]; then
            return 1
        fi
        # Проверка диапазона октета
        if (( octet < 0 || octet > 255 )); then
            return 1
        fi
    done

    return 0
}

# Функция для проверки корректности порта
is_valid_port() {
    local port=$1
    if ! [[ $port =~ ^[0-9]+$ ]]; then
        return 1
    fi
    if (( port < 1 || port > 65535 )); then
        return 1
    fi
    return 0
}

# ====================================================================
# Функция для запроса формата прокси от пользователя
# ====================================================================

get_user_format() {
    while true; do
        echo -e "${BLUE}==================================================${NC}"
        echo -e "${BLUE}          Скрипт обработки прокси-серверов         ${NC}"
        echo -e "${BLUE}==================================================${NC}"
        echo ""
        echo -e "${YELLOW}Введите формат вывода прокси, используя следующие переменные:${NC}"
        echo "  - log   : Логин (username)"
        echo "  - pass  : Пароль (password)"
        echo "  - ip    : IP-адрес прокси"
        echo "  - port  : Порт прокси"
        echo ""
        echo -e "${YELLOW}Примеры форматов вывода:${NC}"
        echo "  1. С аутентификацией (логин и пароль):"
        echo -e "     ${GREEN}log:pass@ip:port${NC}"
        echo "     Пример: user1:password1@192.168.1.1:8080"
        echo ""
        echo "  2. Без аутентификации:"
        echo -e "     ${GREEN}ip:port${NC}"
        echo "     Пример: 192.168.1.1:8080"
        echo ""
        echo -e "${YELLOW}Введите формат вывода и пример (например, log:pass@ip:port):${NC}"
        read -p "Формат вывода: " user_format

        # Проверка наличия обязательных плейсхолдеров
        REQUIRED_PLACEHOLDERS=("ip" "port")
        missing=()
        for placeholder in "${REQUIRED_PLACEHOLDERS[@]}"; do
            if [[ ! $user_format =~ $placeholder ]]; then
                missing+=("$placeholder")
            fi
        done

        if [ ${#missing[@]} -ne 0 ]; then
            echo -e "${RED}Ошибка:${NC} Формат должен содержать плейсхолдеры: ${missing[*]}. Пожалуйста, попробуйте снова."
            echo ""
        else
            break
        fi
    done

    echo "$user_format"
}

# ====================================================================
# Функция для ввода прокси от пользователя
# ====================================================================

get_proxies() {
    echo ""
    echo -e "${YELLOW}Вставьте ваши прокси, по одному в строке.${NC}"
    echo "Примеры прокси с аутентификацией и без неё:"
    echo -e "  ${GREEN}user1:password1@192.168.1.1:8080${NC}"
    echo -e "  ${GREEN}192.168.1.2:3128${NC}"
    echo ""
    echo "Когда закончите, нажмите ${GREEN}Ctrl+D${NC} (EOF)."
    PROXIES=()
    while IFS= read -r line; do
        # Игнорирование пустых строк
        if [[ -n "$line" ]]; then
            PROXIES+=("$line")
        fi
    done
}

# ====================================================================
# Функция для обработки прокси
# ====================================================================

process_proxies() {
    local format="$1"
    shift
    local proxies=("$@")
    local processed=()

    for proxy in "${proxies[@]}"; do
        local log=""
        local pass=""
        local ip=""
        local port=""

        # Проверка наличия аутентификации (логин:пароль@ip:port)
        if [[ "$proxy" =~ ^([^:@]+):([^:@]+)@([^:@]+):([^:@]+)$ ]]; then
            log="${BASH_REMATCH[1]}"
            pass="${BASH_REMATCH[2]}"
            ip="${BASH_REMATCH[3]}"
            port="${BASH_REMATCH[4]}"
        # Проверка прокси без аутентификации (ip:port)
        elif [[ "$proxy" =~ ^([^:@]+):([^:@]+)$ ]]; then
            ip="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
        else
            echo -e "${RED}Предупреждение:${NC} Некорректный формат прокси '${proxy}'. Пропускаем."
            continue
        fi

        # Проверка IP и порта
        if ! is_valid_ip "$ip"; then
            echo -e "${RED}Предупреждение:${NC} Некорректный IP-адрес '${ip}' в прокси '${proxy}'. Пропускаем."
            continue
        fi

        if ! is_valid_port "$port"; then
            echo -e "${RED}Предупреждение:${NC} Некорректный порт '${port}' в прокси '${proxy}'. Пропускаем."
            continue
        fi

        # Замена плейсхолдеров
        local formatted="$format"
        formatted="${formatted//log/$log}"
        formatted="${formatted//pass/$pass}"
        formatted="${formatted//ip/$ip}"
        formatted="${formatted//port/$port}"

        processed+=("$formatted")
    done

    # Сохранение обработанных прокси в глобальную переменную
    PROCESSED_PROXIES=("${processed[@]}")
}

# ====================================================================
# Функция для вывода и сохранения прокси
# ====================================================================

output_proxies() {
    echo ""
    echo -e "${GREEN}Переработанные прокси:${NC}"
    echo "-----------------------"
    for proxy in "${PROCESSED_PROXIES[@]}"; do
        echo "$proxy"
    done

    # Проверка существования файла
    if [ -f "$OUTPUT_FILE" ]; then
        echo -e "${YELLOW}Файл '$OUTPUT_FILE' уже существует. Перезаписать? (y/n):${NC}"
        read -p "Ваш выбор: " overwrite_choice
        case "$overwrite_choice" in
            y|Y )
                echo "" > "$OUTPUT_FILE"
                ;;
            n|N )
                read -p "Введите новое имя файла: " new_output
                OUTPUT_FILE="$new_output"
                ;;
            * )
                echo -e "${RED}Некорректный выбор. Используется стандартное имя файла.${NC}"
                ;;
        esac
    fi

    # Сохранение в файл
    for proxy in "${PROCESSED_PROXIES[@]}"; do
        echo "$proxy" >> "$OUTPUT_FILE"
    done
    echo ""
    echo -e "${GREEN}Прокси сохранены в файл '${OUTPUT_FILE}'${NC}"
}

# ====================================================================
# Главная функция скрипта
# ====================================================================

main() {
    echo ""

    # Вывод логотипа
    print_logo

    # Получение формата от пользователя
    user_format=$(get_user_format)
    echo ""
    echo -e "${GREEN}Выбранный формат:${NC} $user_format"
    echo ""

    # Получение прокси от пользователя
    get_proxies

    if [ ${#PROXIES[@]} -eq 0 ]; then
        echo -e "${RED}Прокси не введены. Завершение работы.${NC}"
        exit 1
    fi

    # Обработка прокси
    process_proxies "$user_format" "${PROXIES[@]}"

    # Проверка наличия обработанных прокси
    if [ ${#PROCESSED_PROXIES[@]} -eq 0 ]; then
        echo -e "${RED}Нет корректных прокси для сохранения.${NC}"
        exit 1
    fi

    # Вывод и сохранение прокси
    output_proxies
}

# Запуск главной функции
main
