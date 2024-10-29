#!/bin/bash

# Файл для сохранения обработанных прокси
OUTPUT_FILE="output_proxies.txt"

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

# Функция для запроса формата прокси
get_user_format() {
    echo "Введите формат вывода (используйте плейсхолдеры: log, pass, ip, port)"
    echo "Пример: log:pass@ip:port или ip:port"
    read -p "Формат вывода: " user_format

    # Проверка наличия необходимых плейсхолдеров
    REQUIRED_PLACEHOLDERS=("ip" "port")
    for placeholder in "${REQUIRED_PLACEHOLDERS[@]}"; do
        if [[ ! $user_format =~ $placeholder ]]; then
            echo "Ошибка: Формат должен содержать плейсхолдер '$placeholder'. Пожалуйста, попробуйте снова."
            get_user_format
            return
        fi
    done

    echo "$user_format"
}

# Функция для ввода прокси
get_proxies() {
    echo ""
    echo "Вставьте ваши прокси, по одному в строке. Когда закончите, нажмите Ctrl+D (EOF)."
    PROXIES=()
    while IFS= read -r line; do
        # Игнорирование пустых строк
        if [[ -n "$line" ]]; then
            PROXIES+=("$line")
        fi
    done
}

# Функция для обработки прокси
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

        # Проверка наличия аутентификации
        if [[ "$proxy" =~ ^([^:@]+):([^:@]+)@([^:@]+):([^:@]+)$ ]]; then
            log="${BASH_REMATCH[1]}"
            pass="${BASH_REMATCH[2]}"
            ip="${BASH_REMATCH[3]}"
            port="${BASH_REMATCH[4]}"
        elif [[ "$proxy" =~ ^([^:@]+):([^:@]+)$ ]]; then
            ip="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
        else
            echo "Предупреждение: Некорректный формат прокси '$proxy'. Пропускаем."
            continue
        fi

        # Проверка IP и порта
        if ! is_valid_ip "$ip"; then
            echo "Предупреждение: Некорректный IP-адрес '$ip' в прокси '$proxy'. Пропускаем."
            continue
        fi

        if ! is_valid_port "$port"; then
            echo "Предупреждение: Некорректный порт '$port' в прокси '$proxy'. Пропускаем."
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

    echo "${processed[@]}"
    PROCESSED_PROXIES=("${processed[@]}")
}

# Функция для вывода и сохранения прокси
output_proxies() {
    echo ""
    echo "Переработанные прокси:"
    for proxy in "${PROCESSED_PROXIES[@]}"; do
        echo "$proxy"
    done

    # Сохранение в файл
    echo "" > "$OUTPUT_FILE"  # Очищаем файл
    for proxy in "${PROCESSED_PROXIES[@]}"; do
        echo "$proxy" >> "$OUTPUT_FILE"
    done
    echo ""
    echo "Прокси сохранены в файл '$OUTPUT_FILE'"
}

# Главная функция
main() {
    echo "=== Скрипт обработки прокси ==="
    
    # Получение формата от пользователя
    user_format=$(get_user_format)
    echo ""
    echo "Выбранный формат: $user_format"
    
    # Получение прокси от пользователя
    get_proxies

    if [ ${#PROXIES[@]} -eq 0 ]; then
        echo "Прокси не введены. Завершение работы."
        exit 1
    fi

    # Обработка прокси
    processed=$(process_proxies "$user_format" "${PROXIES[@]}")
    
    # Проверка наличия обработанных прокси
    if [ ${#PROCESSED_PROXIES[@]} -eq 0 ]; then
        echo "Нет корректных прокси для сохранения."
        exit 1
    fi

    # Вывод и сохранение прокси
    output_proxies
}

# Запуск главной функции
main
