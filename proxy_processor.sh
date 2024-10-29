get_user_format() {
    while true; do
        echo -e "${BLUE}==================================================${NC}"
        echo -e "${BLUE}          Скрипт обработки прокси-серверов         ${NC}"
        echo -e "${BLUE}==================================================${NC}"
        echo ""
        echo -e "${YELLOW}Выберите тип формата прокси:${NC}"
        echo "1. С аутентификацией (log:pass@ip:port)"
        echo "2. Без аутентификации (ip:port)"
        echo "3. Пользовательский формат"
        read -p "Выбор (1-3): " format_choice

        case "$format_choice" in
            1)
                user_format="log:pass@ip:port"
                echo -e "${GREEN}Выбран формат: log:pass@ip:port${NC}"
                break
                ;;
            2)
                user_format="ip:port"
                echo -e "${GREEN}Выбран формат: ip:port${NC}"
                break
                ;;
            3)
                echo -e "${YELLOW}Введите пользовательский формат вывода:${NC}"
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
                    echo -e "${GREEN}Выбран пользовательский формат: $user_format${NC}"
                    break
                fi
                ;;
            *)
                echo -e "${RED}Некорректный выбор. Пожалуйста, выберите 1, 2 или 3.${NC}"
                ;;
        esac
    done

    echo "$user_format"
}
