#!/bin/bash

# =============================================================================
# СКРИПТ РЕЗЕРВНОГО КОПИРОВАНИЯ
# Автор: kwiten
# =============================================================================


if [[ "$1" == "--auto" ]]; then
    CONFIG_FILE="$HOME/.backup.conf"
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"   # Загружаем переменные из конфига
        AUTO_MODE=1
        echo "Запуск в автоматическом режиме. Используется конфиг: $CONFIG_FILE"
    else
        echo "Ошибка: не найден конфиг $CONFIG_FILE"
        exit 1
    fi
fi


echo "Текущая директория: $PWD"
read -e -p "Введите путь директории в которой находится файл/папка, для которой нужно сделать бэкап [Enter для текущей]: " -i "$PWD" BACKUP_DIR
BACKUP_DIR=${BACKUP_DIR:-$PWD}
echo "Выбранный путь: $BACKUP_DIR"

cd "$BACKUP_DIR" || { echo "Ошибка: Директория '$BACKUP_DIR' не существует!"; exit 1; }

while true; do
    read -e -p "Выберите файл/папку для бэкапа: " TARGET_FILE

    if [ ! -e "$TARGET_FILE" ]; then
        echo "Ошибка: '$TARGET_FILE' не существует в '$BACKUP_DIR'. Попробуйте снова."
        continue   # возвращаемся в начало цикла и снова просим ввод
    fi
    break
done
echo "Вы выбради файл/папку $TARGET_FILE"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║            РЕЖИМ АРХИВАЦИИ                   ║"
echo "╠══════════════════════════════════════════════╣"
echo "║ 1. Создать временную директорию для архива   ║"
echo "║ 2. Указать свою директорию для архива        ║"
echo "║ 3. Не создавать локальный архив              ║"
echo "║    (архивировать перед передачей по SCP)     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

while true; do
    read -p "Выберите вариант (1-3): " archive_choice

    case $archive_choice in
        1) 
            while true; do
                read -e -p "Введите путь к директории, в которой будет создан временный архив [Enter для текущей]: " -i "$PWD" ARCHIVE_DIR
                
                if [ ! -e "$ARCHIVE_DIR" ]; then
                    echo "Ошибка: '$ARCHIVE_DIR' не существует"
                    read -p "Хотите создать директорию по этому пути '$ARCHIVE_DIR'? (Y/n): " ANSWER
                    
                    if [ "$ANSWER" = "Y" ] || [ "$ANSWER" = "y" ]; then
                        mktemp -d -p "$ARCHIVE_DIR"
                        echo "Директория для временного архива создана!"
                        break
                    elif [ "$ANSWER" = "N" ] || [ "$ANSWER" = "n" ]; then
                        continue
                    else
                        echo "Введите Y или n"
                        continue
                    fi
                fi
                break
            done

            ;;
        2)
            while true; do
                read -e -p "Введите путь к директории, в которую вы хотите сохранить архив [Enter для текущей]: " -i "$PWD" ARCHIVE_DIR_STABLE
                
                if [ ! -e "$ARCHIVE_DIR_STABLE" ]; then
                    echo "Ошибка: '$ARCHIVE_DIR_STABLE' не существует"
                    read -p "Хотите создать директорию по этому пути '$ARCHIVE_DIR_STABLE'? (Y/n): " ANSWER
                    
                    if [ "$ANSWER" = "Y" ] || [ "$ANSWER" = "y" ]; then
                        mkdir -p "$ARCHIVE_DIR_STABLE"
                        echo "Директория для архива создана!"
                        break
                    elif [ "$ANSWER" = "N" ] || [ "$ANSWER" = "n" ]; then
                        continue
                    else
                        echo "Введите Y или n"
                        continue         ARCHIVE_CMD="tar -czf"
                        ARCHIVE_EXT=".tar.gz"
                        echo "Выбран: tar.gz архив"
                    fi
                fi
                break
            done
            ;;
        3)
            ARCHIVE_DIR=""
            echo "Локальный архив создаваться не будет."
            ;;
        *)
            echo "Неверный выбор! Введите 1, 2 или 3."
            ;;
    esac
    break
done




echo ""
echo "╔═══════════════════════════════════════════════╗"
echo "║           ВЫБОР ТИПА АРХИВА                   ║"
echo "╠═══════════════════════════════════════════════╣"
echo "║ 1. tar.gz - стандартный gzip архив            ║"
echo "║ 2. zip - ZIP архив                            ║"
echo "║ 3. 7z - высокое сжатие 7-Zip                  ║"
echo "║ 4. rar - RAR архив                            ║"
echo "╚═══════════════════════════════════════════════╝"
echo ""


while true; do
    read -p "Выберите тип архива (1-4): " archive_choice
    
    case $archive_choice in
        1)
            while true; do
                    if command -v tar >/dev/null 2>&1; then
                        ARCHIVE_TYPE="tar.gz"
                        ARCHIVE_CMD="tar -czf"
                        ARCHIVE_EXT=".tar.gz"
                        echo "Выбран: tar.gz архив"
                    else
                        echo "tar не найден"
                        read -e -p "Хотите его установить? (Y/n)" ANSWER
                            if [ "$ANSWER" = "Y" ] || [ "$ANSWER" = "y" ]; then
                                sudo apt update && sudo apt upgrade -y
                                sudo apt install tar -y
                                echo "tar скачен!"
                                ARCHIVE_TYPE="tar.gz"
                                ARCHIVE_CMD="tar -czf"
                                ARCHIVE_EXT=".tar.gz"
                            elif [ "$ANSWER" = "N" ] || [ "$ANSWER" = "n" ]; then
                                continue
                            else
                                echo "Введите Y или n"
                                continue        
                            fi
                    fi
                    break
            done
            ;;
        2)
            while true; do
                        if command -v zip >/dev/null 2>&1; then
                            ARCHIVE_TYPE="zip"
                            ARCHIVE_CMD="zip -r"
                            ARCHIVE_EXT=".zip"
                            echo "Выбран: ZIP архив"
                        else
                            echo "zip не найден"
                            read -e -p "Хотите его установить? (Y/n)" ANSWER
                                if [ "$ANSWER" = "Y" ] || [ "$ANSWER" = "y" ]; then
                                    sudo apt update && sudo apt upgrade -y
                                    sudo apt install zip unzip -y
                                    echo "zip скачен!"
                                    ARCHIVE_TYPE="zip"
                                    ARCHIVE_CMD="zip -r"
                                    ARCHIVE_EXT=".zip"
                                    echo "Выбран: ZIP архив"
                                elif [ "$ANSWER" = "N" ] || [ "$ANSWER" = "n" ]; then
                                    continue
                                else
                                    echo "Введите Y или n"
                                    continue        
                                fi
                        fi
                        break
                done
                ;;
        3)
                while true; do
                        if command -v 7z >/dev/null 2>&1; then
                                ARCHIVE_TYPE="7z"
                                ARCHIVE_CMD="7z a"
                                ARCHIVE_EXT=".7z"
                                echo "Выбран: 7z архив"   
                        else
                            echo "7z не найден"
                            read -e -p "Хотите его установить? (Y/n)" ANSWER
                                if [ "$ANSWER" = "Y" ] || [ "$ANSWER" = "y" ]; then
                                    sudo apt update && sudo apt upgrade -y
                                    sudo apt install p7zip-full p7zip-rar -y
                                    echo "7z скачен!"
                                    ARCHIVE_TYPE="7z"
                                    ARCHIVE_CMD="7z a"
                                    ARCHIVE_EXT=".7z"
                                    echo "Выбран: 7z архив"
                                elif [ "$ANSWER" = "N" ] || [ "$ANSWER" = "n" ]; then
                                    continue
                                else
                                    echo "Введите Y или n"
                                    continue        
                                fi
                        fi
                        break
                done
                ;;
       4)
                while true; do
                        if command -v rar >/dev/null 2>&1; then
                            ARCHIVE_TYPE="rar"
                            ARCHIVE_CMD="rar a"
                            ARCHIVE_EXT=".rar"
                            echo "Выбран: RAR архив"         
                        else
                            echo "rar не найден"
                            read -e -p "Хотите его установить? (Y/n)" ANSWER
                                if [ "$ANSWER" = "Y" ] || [ "$ANSWER" = "y" ]; then
                                    sudo apt update && sudo apt upgrade -y
                                    sudo apt install rar unrar -y
                                    echo "rar скачен!"
                                    ARCHIVE_TYPE="rar"
                                    ARCHIVE_CMD="rar a"
                                    ARCHIVE_EXT=".rar"
                                    echo "Выбран: RAR архив"
                                elif [ "$ANSWER" = "N" ] || [ "$ANSWER" = "n" ]; then
                                    continue
                                else
                                    echo "Введите Y или n"
                                    continue        
                                fi
                        fi
                        break
                done
                ;;

        *)
            echo "Неверный выбор! Введите 1-4."
            ;;
    esac
    break
done


echo ""
echo "╔════════════════════════════════════════════════╗"
echo "║             СОЗДАНИЕ АРХИВА                    ║"
echo "╚════════════════════════════════════════════════╝"
echo ""

# Определяем полный путь к архиву в зависимости от выбранного режима
create_archive() {
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    ARCHIVE_NAME="$(basename "$TARGET_FILE")_${TIMESTAMP}${ARCHIVE_EXT}"

    # Если директория для архивации задана
    if [ -n "$ARCHIVE_DIR" ]; then
        DEST="$ARCHIVE_DIR/$ARCHIVE_NAME"
    elif [ -n "$ARCHIVE_DIR_STABLE" ]; then
        DEST="$ARCHIVE_DIR_STABLE/$ARCHIVE_NAME"
    else
        DEST="$PWD/$ARCHIVE_NAME"
    fi

    echo "Создание архива: $DEST"

    case $ARCHIVE_TYPE in
        tar.gz)
            $ARCHIVE_CMD "$DEST" "$TARGET_FILE"
            ;;
        zip)
            $ARCHIVE_CMD "$DEST" "$TARGET_FILE"
            ;;
        7z)
            $ARCHIVE_CMD "$DEST" "$TARGET_FILE"
            ;;
        rar)
            $ARCHIVE_CMD "$DEST" "$TARGET_FILE"
            ;;
        *)
            echo "Ошибка: неизвестный тип архива!"
            return 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo "Архив успешно создан: $DEST"
    else
        echo "Ошибка при создании архива!"
    fi
}

create_archive



echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║           ВЫБОР ПРОТОКОЛА ПЕРЕДАЧИ           ║"
echo "╠══════════════════════════════════════════════╣"
echo "║ 1. SCP  (простой)                            ║"
echo "║ 2. RSYNC (рекомендуется)                     ║"
echo "║ 3. SFTP  (FTP поверх SSH)                    ║"
echo "║ 4. Потоковая архивация (ssh + tar)           ║"
echo "║ 5. RCLONE (облачные хранилища)               ║"
echo "║ 0. Не копировать                             ║"
echo "╚══════════════════════════════════════════════╝"
echo ""




read -p "Выберите протокол (0-5): " transfer_protocol
case $transfer_protocol in


     1)
        read -p "Введите адрес сервера [user@hostname]: " SCP_SERVER
        read -e -p "Введите путь на удаленном сервере: " SCP_PATH
        read -p "Введите порт SCP [22]: " -i "22" SCP_PORT

        if [ -n "$ARCHIVE_DIR" ]; then
            FULL_ARCHIVE_PATH="$ARCHIVE_DIR/$ARCHIVE_NAME"
        elif [ -n "$ARCHIVE_DIR_STABLE" ]; then
            FULL_ARCHIVE_PATH="$ARCHIVE_DIR_STABLE/$ARCHIVE_NAME"
        else
            FULL_ARCHIVE_PATH="$PWD/$ARCHIVE_NAME"
        fi
    
        echo "Полный путь к архиву: $FULL_ARCHIVE_PATH"

        echo "Копирую через SCP..."
        echo "scp -P \"$SCP_PORT\" \"$FULL_ARCHIVE_PATH\" \"$SCP_SERVER:$SCP_PATH\""
        scp -P "$SCP_PORT" "$FULL_ARCHIVE_PATH" "$SCP_SERVER:$SCP_PATH"
        ;;
    
    2)
        read -p "Введите адрес сервера [user@hostname]: " RSYNC_SERVER
        read -p "Введите путь на удаленном сервере: " RSYNC_PATH
        read -p "Введите порт: " RSYNC_PORT
        echo "Копирую через RSYNC..."
        rsync -avz -e "ssh -p $RSYNC_PORT"  --progress "$FULL_ARCHIVE_PATH" "$RSYNC_SERVER:$RSYNC_PATH"
        ;;
    
    3)
        read -p "Введите адрес сервера [user@hostname]: " SFTP_SERVER
        read -p "Введите путь на удаленном сервере: " SFTP_PATH
        echo "Копирую через SFTP..."
        echo "put \"$FULL_ARCHIVE_PATH\" \"$SFTP_PATH\"" | sftp "$SFTP_SERVER"
        ;;
    
    4)
        read -p "Введите адрес сервера [user@hostname]: " SSH_SERVER
        read -p "Введите путь на удаленном сервере: " SSH_PATH
        echo "Потоковая архивация и передача..."
        if [ "$ARCHIVE_TYPE" = "tar.gz" ]; then
            tar czf - "$TARGET_FILE" | ssh "$SSH_SERVER" "tar xzf - -C \"$SSH_PATH\""
        else
            echo "Потоковая передача доступна только для tar.gz"
        fi
        ;;
    
    5)
        read -p "Введите имя настроенного удаленного хранилища: " RCLONE_REMOTE
        read -p "Введите путь в удаленном хранилище: " RCLONE_PATH
        echo "Копирую через RCLONE..."
        rclone copy "$FULL_ARCHIVE_PATH" "$RCLONE_REMOTE:$RCLONE_PATH"
        ;;
    
    0)
        echo "Копирование пропущено."
        ;;
    
    *)
        echo "Неверный выбор. Копирование пропущено."
        return
        ;;
esac

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         НАСТРОЙКА АВТОМАТИЧЕСКОГО БЭКАПА     ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

read -p "Хотите включить автозапуск через cron? (Y/n): " AUTORUN
if [[ "$AUTORUN" =~ ^[Yy]$ ]]; then
    CONFIG_FILE="$HOME/.backup.conf"

    echo "Создаём конфигурационный файл: $CONFIG_FILE"
    cat > "$CONFIG_FILE" <<EOF
# Конфигурация автобэкапа
BACKUP_DIR="$BACKUP_DIR"
TARGET_FILE="$TARGET_FILE"
ARCHIVE_TYPE="$ARCHIVE_TYPE"
ARCHIVE_DIR="${ARCHIVE_DIR:-$ARCHIVE_DIR_STABLE}"
TRANSFER_PROTOCOL="$transfer_protocol"
SERVER="${SCP_SERVER:-$RSYNC_SERVER}"
SERVER_PATH="${SCP_PATH:-$RSYNC_PATH}"
SERVER_PORT="${SCP_PORT:-$RSYNC_PORT}"
EOF

    echo "Конфиг сохранён!"

    read -p "Введите расписание в формате cron (например, '0 3 * * *' для запуска каждый день в 3:00): " CRON_SCHEDULE
    SCRIPT_PATH="$(realpath "$0")"

    # Добавляем задачу в cron
    (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE bash $SCRIPT_PATH --auto >> \$HOME/backup.log 2>&1") | crontab -

    echo "Автобэкап добавлен в cron!"
    echo "Логи будут писаться в ~/backup.log"
fi
