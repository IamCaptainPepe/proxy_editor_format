#!/bin/bash

# Файл для сохранения обработанных прокси
OUTPUT_FILE="output_proxies.txt"

# Функция для выбора типа прокси
choose_proxy_type() {
    echo "============================"
    echo "   Proxy Type Selection Menu   "
    echo "============================"
    echo "1. HTTP"
    echo "2. SOCKS"
    echo "3. No prefix"
    echo "============================"

    while true; do
        read -p "Choose proxy type (1 for HTTP, 2 for SOCKS, 3 for No prefix): " choice
        case $choice in
            1) prefix="http"; break ;;
            2) prefix="socks"; break ;;
            3) prefix=""; break ;;
            *) echo "Error: Please enter 1, 2, or 3." ;;
        esac
    done
}

# Функция для выбора порта
choose_port_option() {
    echo "============================"
    echo "   Port Selection Menu   "
    echo "============================"
    echo "1. Use the port specified in each proxy"
    echo "2. Set a custom port for all proxies"
    echo "3. Specify port manually if missing in proxy"
    echo "============================"

    while true; do
        read -p "Choose port option (1, 2, or 3): " port_choice
        case $port_choice in
            1) use_default_port=true; manual_port=false; break ;;
            2)
                read -p "Enter your custom port: " custom_port
                if ! [[ "$custom_port" =~ ^[0-9]+$ ]] || [ "$custom_port" -le 0 ] || [ "$custom_port" -gt 65535 ]; then
                    echo "Invalid port number. Please enter a valid port."
                else
                    use_default_port=false
                    manual_port=false
                    break
                fi
                ;;
            3) use_default_port=false; manual_port=true; break ;;
            *) echo "Error: Please enter 1, 2, or 3." ;;
        esac
    done
}

# Функция для выбора формата вывода
get_proxy_format() {
    echo "============================"
    echo "   Proxy Output Format   "
    echo "============================"
    echo "Available placeholders: log, pass, ip, port."
    echo "Example format: log:pass@ip:port or ip:port"
    echo "============================"
    read -p "Enter your custom output format: " format
    if ! [[ "$format" =~ "ip" && "$format" =~ "port" ]]; then
        echo "Error: The format must include 'ip' and 'port'. Using default format 'ip:port'."
        format="ip:port"
    fi
}

# Функция для обработки прокси, вводимых в терминале
process_proxies() {
    echo "Paste your list of proxies (each on a new line), and press Ctrl+D to finish input:"
    > "$OUTPUT_FILE"

    # Пауза и пустая строка перед началом вывода
    sleep 1
    echo ""

    # Чтение прокси из терминала
    while IFS= read -r proxy; do
        log=""; pass=""; ip=""; port=""

        # Парсинг прокси на части
        if [[ $proxy =~ ^([^:]+):([^:]+):([^:]+):([^:]+)$ ]]; then
            ip="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
            log="${BASH_REMATCH[3]}"
            pass="${BASH_REMATCH[4]}"
        elif [[ $proxy =~ ^([^:]+):([^@]+)@([^:]+):([0-9]+)$ ]]; then
            log="${BASH_REMATCH[1]}"
            pass="${BASH_REMATCH[2]}"
            ip="${BASH_REMATCH[3]}"
            port="${BASH_REMATCH[4]}"
        elif [[ $proxy =~ ^([^@]+)@([^:]+):([0-9]+)$ ]]; then
            log="${BASH_REMATCH[1]}"
            ip="${BASH_REMATCH[2]}"
            port="${BASH_REMATCH[3]}"
        elif [[ $proxy =~ ^([^:]+):([0-9]+)$ ]]; then
            ip="${BASH_REMATCH[1]}"
            port="${BASH_REMATCH[2]}"
        elif [[ $proxy =~ ^([^:]+)$ ]]; then
            ip="${BASH_REMATCH[1]}"
            port=""
        else
            echo "Invalid proxy format: $proxy" >&2
            continue
        fi

        # Определение порта
        if [ "$use_default_port" = true ]; then
            port="${port:-8080}"
        elif [ "$manual_port" = true ] && [[ -z "$port" ]]; then
            read -p "Enter port for $ip: " port
            if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -le 0 ] || [ "$port" -gt 65535 ]; then
                echo "Invalid port number. Skipping this proxy."
                continue
            fi
        else
            port="$custom_port"
        fi

        # Замена плейсхолдеров и вывод
        formatted_proxy="$format"
        formatted_proxy="${formatted_proxy//log/$log}"
        formatted_proxy="${formatted_proxy//pass/$pass}"
        formatted_proxy="${formatted_proxy//ip/$ip}"
        formatted_proxy="${formatted_proxy//port/$port}"
        
        # Удаление лишних пробелов, вывод и сохранение прокси
        formatted_proxy=$(echo "$formatted_proxy" | tr -s ' ')
        if [[ -n "$prefix" ]]; then
            echo "$prefix://$formatted_proxy" | tee -a "$OUTPUT_FILE"
        else
            echo "$formatted_proxy" | tee -a "$OUTPUT_FILE"
        fi
    done

    echo "Processing completed. Results saved in $OUTPUT_FILE"
}

# Запуск функций
choose_proxy_type
choose_port_option
get_proxy_format
process_proxies
