#!/bin/bash

# Файл для сохранения обработанных прокси
OUTPUT_FILE="output_proxies.txt"

# Функция для отображения меню и выбора формата прокси
get_proxy_format() {
    echo "============================"
    echo "   Proxy Format Selection Menu   "
    echo "============================"
    echo "1. With authentication (log:pass@ip:port)"
    echo "2. Without authentication (ip:port)"
    echo "3. Custom format"
    echo ""
    echo "Example custom format: log:pass@ip:port or ip:port"
    echo "Available placeholders: log, pass, ip, port."
    echo "Ensure your format includes 'ip' and 'port'."
    echo "============================"

    while true; do
        read -p "Choose proxy format (1-3): " choice
        case $choice in
            1)
                format="log:pass@ip:port"
                break
                ;;
            2)
                format="ip:port"
                break
                ;;
            3)
                read -p "Enter your custom format (e.g., log:pass@ip:port): " format
                if [[ "$format" =~ "ip" && "$format" =~ "port" ]]; then
                    break
                else
                    echo "Error: The format must include 'ip' and 'port'. Please try again."
                fi
                ;;
            *)
                echo "Error: Enter a number between 1 and 3."
                ;;
        esac
    done
}

# Функция для обработки прокси, вводимых в терминале
process_proxies() {
    echo "Paste your list of proxies (each on a new line), and press Ctrl+D to finish input:"
    > "$OUTPUT_FILE"  # Очистить или создать output файл

    # Чтение прокси из терминала
    while IFS= read -r proxy; do
        # Разбор прокси на части: log, pass, ip, и port
        if [[ $proxy =~ ^([^:]+):([^@]+)@(.+):([0-9]+)$ ]]; then
            log="${BASH_REMATCH[1]}"
            pass="${BASH_REMATCH[2]}"
            ip="${BASH_REMATCH[3]}"
            port="${BASH_REMATCH[4]}"
        elif [[ $proxy =~ ^(.+):([0-9]+)$ ]]; then
            ip="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
            log=""
            pass=""
        fi

        # Заменяем плейсхолдеры в формате на реальные значения
        formatted_proxy="${format/log/$log}"
        formatted_proxy="${formatted_proxy/pass/$pass}"
        formatted_proxy="${formatted_proxy/ip/$ip}"
        formatted_proxy="${formatted_proxy/port/$port}"
        
        # Сохраняем результат в файл и выводим в консоль
        echo "$formatted_proxy" | tee -a "$OUTPUT_FILE"
    done

    echo "Processing completed. Results saved in $OUTPUT_FILE"
}

# Запуск функции для выбора формата прокси и обработки
echo "============================"
echo "   Proxy Processing Script   "
echo "============================"
get_proxy_format
process_proxies
