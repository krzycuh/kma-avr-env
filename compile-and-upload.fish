#!/usr/bin/env fish

# Funkcje logowania
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

function print_help
    echo "Użycie: "(basename (status filename))" <host> <plik.c> [opcje]"
    echo
    echo "Kompiluje kod AVR na macOS i flashuje na RPi w jednym kroku."
    echo
    echo "Argumenty:"
    echo "  <host>     docelowy host SSH (np. rpi_local)"
    echo "  <plik.c>   pełna nazwa pliku źródłowego (np. attiny-rpi-com.c)"
    echo
    echo "Opcje:"
    echo "  --verify   weryfikuj po zaprogramowaniu"
    echo "  --restart  zrestartuj mikrokontroler po flashu"
    echo "  --size     pokaż rozmiar sekcji"
    echo "  --trace    włącz szczegółowe śledzenie"
    echo "  -h, --help pokaż pomoc"
    echo
    echo "Przykłady:"
    echo "  "(basename (status filename))" rpi_local attiny-rpi-com.c --verify"
    echo "  "(basename (status filename))" rpi_local attiny-rpi-com.c --size --restart"
end

# Parsowanie argumentów
set -l host ""
set -l source_file ""
set -l verify_flag 0
set -l restart_flag 0
set -l size_flag 0
set -l trace_flag 0

set -l positional_count 0
for arg in $argv
    switch $arg
        case -h --help
            print_help
            exit 0
        case --verify
            set verify_flag 1
        case --restart
            set restart_flag 1
        case --size
            set size_flag 1
        case --trace
            set trace_flag 1
        case '*'
            set positional_count (math $positional_count + 1)
            if test $positional_count -eq 1
                set host $arg
            else if test $positional_count -eq 2
                set source_file $arg
            end
    end
end

if test -z "$host" -o -z "$source_file"
    error "Brak wymaganych argumentów!"
    print_help
    exit 1
end

# Sprawdź czy plik ma rozszerzenie .c
if not string match -q "*.c" "$source_file"
    error "Plik musi mieć rozszerzenie .c: $source_file"
    exit 1
end

# Wyciągnij nazwę bazową bez rozszerzenia
set -l basename_file (string replace -r '\.c$' '' "$source_file")

# Włącz trace jeśli żądane
if test $trace_flag -eq 1
    set fish_trace 1
end

# Stwórz folder target jeśli nie istnieje
if not test -d "target"
    run "mkdir -p target"
    or exit 1
end

# Konfiguracja projektu
set -l MCU "attiny2313"
set -l F_CPU "1000000UL"  # 1MHz zgodnie z komentarzem w kodzie
set -l SOURCE "$source_file"
set -l BINARY "target/$basename_file.bin"
set -l HEXFILE "target/$basename_file.hex"
set -l MAPFILE "target/$basename_file.map"

# Ulepszone flagi kompilacji
set -l CFLAGS "-std=c11 -Wall -Wextra -Wpedantic -g -Os"
set CFLAGS $CFLAGS "-mmcu=$MCU -DF_CPU=$F_CPU"
set CFLAGS $CFLAGS "-ffunction-sections -fdata-sections"
set CFLAGS $CFLAGS "-fno-common -fshort-enums"

set -l LDFLAGS "-Wl,--gc-sections -Wl,-Map=$MAPFILE"

# Sprawdź czy plik źródłowy istnieje
if not test -f "$SOURCE"
    error "Plik źródłowy $SOURCE nie istnieje!"
    exit 1
end

info "Kompilacja $SOURCE dla $MCU..."

# Czyszczenie starych plików
run "rm -f $BINARY $HEXFILE $MAPFILE"

# Kompilacja
run "avr-gcc $CFLAGS $SOURCE -o $BINARY $LDFLAGS"
or exit 1

# Generowanie HEX
run "avr-objcopy -O ihex -R .eeprom $BINARY $HEXFILE"
or exit 1

# Pokaż rozmiar jeśli żądane
if test $size_flag -eq 1
    info "Rozmiar sekcji:"
    avr-size -C --mcu=$MCU $BINARY
    if test -f "$MAPFILE"
        info "Mapa pamięci zapisana w: $MAPFILE"
    end
end

# Przygotowanie komendy avrdude na RPi
set -l avrdude_cmd "sudo avrdude -v -C ~/avrdude.conf -c kma-at2313 -p attiny2313"
set avrdude_cmd "$avrdude_cmd -U flash:w:-:i"  # czytaj HEX z stdin

# Dodaj weryfikację jeśli żądana
if test $verify_flag -eq 1
    set avrdude_cmd "$avrdude_cmd -U verify"
    info "Weryfikacja włączona"
end

info "Programowanie przez SSH: $host"
info "Komenda avrdude: $avrdude_cmd"

# Programowanie przez pipe - HEX leci przez SSH bezpośrednio do avrdude
cat $HEXFILE | ssh $host "$avrdude_cmd"
set -l flash_result $status

if test $flash_result -eq 0
    info "✅ Programowanie zakończone pomyślnie!"
    
    # Restart mikrokontrolera jeśli żądany
    if test $restart_flag -eq 1
        info "Restartowanie mikrokontrolera..."
        # Przykładowa komenda - dostosuj do Twojego setupu GPIO
        ssh $host "echo 'Restart MCU - implementuj zgodnie z Twoim setupem GPIO'"
    end
    
    # Pokaż statystyki
    set -l hex_size (wc -c < $HEXFILE)
    info "Rozmiar pliku HEX: $hex_size bajtów"
    
else
    error "❌ Programowanie nie powiodło się (kod: $flash_result)"
    warn "Sprawdź połączenie SSH i konfigurację avrdude na RPi"
    exit $flash_result
end

info "🎉 Gotowe!"
