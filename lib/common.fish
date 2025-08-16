#!/usr/bin/env fish

# Wspólne funkcje logowania i narzędzia dla skryptów AVR

function info
    set_color green
    echo -n "["(date "+%Y-%m-%d %H:%M:%S")"] [INFO] "
    set_color normal
    echo $argv
end

function warn
    set_color yellow
    echo -n "["(date "+%Y-%m-%d %H:%M:%S")"] [WARNING] "
    set_color normal
    echo $argv
end

function error
    set_color red
    echo -n "["(date "+%Y-%m-%d %H:%M:%S")"] [ERROR] "
    set_color normal
    echo $argv
end

function run
    set -l cmd $argv
    set_color cyan
    echo -n "["(date "+%Y-%m-%d %H:%M:%S")"] [CMD] "
    set_color normal
    echo $cmd
    eval $cmd
    set -l st $status
    if test $st -ne 0
        error "Polecenie zakończone błędem ($st): $cmd"
        return $st
    end
    return 0
end

function separator
    set -l char "="
    set -l length 50
    if test (count $argv) -ge 1
        set char $argv[1]
    end
    if test (count $argv) -ge 2
        set length $argv[2]
    end
    echo (string repeat -n $length $char)
end

# Wspólne stałe konfiguracyjne dla AVR
set -g AVR_MCU "attiny2313"
set -g AVR_F_CPU "1000000UL"
set -g AVR_CFLAGS "-std=c11 -Wall -Wextra -Wpedantic -g -Os -ffunction-sections -fdata-sections -fno-common -fshort-enums"
set -g AVR_LDFLAGS "-Wl,--gc-sections"

# Funkcja do sprawdzenia czy plik istnieje z odpowiednim komunikatem
function check_file_exists
    set -l file $argv[1]
    set -l description $argv[2]

    if not test -f "$file"
        error "$description $file nie istnieje!"
        return 1
    end
    return 0
end
