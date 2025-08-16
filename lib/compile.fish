#!/usr/bin/env fish

# Import wspólnych funkcji
set script_dir (dirname (realpath (status filename)))
source $script_dir/common.fish

function print_help
    echo "Użycie: "(basename (status filename))" <plik.c> [opcje]"
    echo
    echo "Kompiluje kod AVR na macOS do pliku HEX."
    echo
    echo "Argumenty:"
    echo "  <plik.c>   pełna nazwa pliku źródłowego (np. main.c)"
    echo
    echo "Opcje:"
    echo "  --size     pokaż rozmiar sekcji"
    echo "  --trace    włącz szczegółowe śledzenie"
    echo "  -h, --help pokaż pomoc"
    echo
    echo "Przykłady:"
    echo "  "(basename (status filename))" main.c"
    echo "  "(basename (status filename))" main.c --size"
end

# Parsowanie argumentów
set -l source_file ""
set -l size_flag 0
set -l trace_flag 0

for arg in $argv
    switch $arg
        case -h --help
            print_help
            exit 0
        case --size
            set size_flag 1
        case --trace
            set trace_flag 1
        case '*'
            if test -z "$source_file"
                set source_file $arg
            end
    end
end

if test -z "$source_file"
    error "Brak pliku źródłowego!"
    print_help
    exit 1
end

# Sprawdź czy plik ma rozszerzenie .c
if not string match -q "*.c" "$source_file"
    error "Plik musi mieć rozszerzenie .c: $source_file"
    exit 1
end

# Wyciągnij katalog i nazwę bazową
set -l source_dir (dirname "$source_file")
set -l basename_file (basename (string replace -r '\.c$' '' "$source_file"))

# Włącz trace jeśli żądane
if test $trace_flag -eq 1
    set fish_trace 1
end

# Stwórz folder target w katalogu źródłowym
set -l target_dir "$source_dir/target"
if not test -d "$target_dir"
    run "mkdir -p $target_dir"
    or exit 1
end

# Konfiguracja projektu - używa wspólnych stałych
set -l MCU $AVR_MCU
set -l F_CPU $AVR_F_CPU
set -l SOURCE "$source_file"
set -l BINARY "$target_dir/$basename_file.bin"
set -l HEXFILE "$target_dir/$basename_file.hex"
set -l MAPFILE "$target_dir/$basename_file.map"

# Flagi kompilacji - używa wspólnych stałych
set -l CFLAGS $AVR_CFLAGS
set CFLAGS $CFLAGS "-mmcu=$MCU -DF_CPU=$F_CPU"

set -l LDFLAGS "$AVR_LDFLAGS -Wl,-Map=$MAPFILE"

# Sprawdź czy plik źródłowy istnieje
check_file_exists "$SOURCE" "Plik źródłowy"
or exit 1

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

info "✅ Kompilacja zakończona pomyślnie!"
info "Wygenerowane pliki:"
info "  - $BINARY (plik binarny)"
info "  - $HEXFILE (plik HEX do wgrania)"
if test -f "$MAPFILE"
    info "  - $MAPFILE (mapa pamięci)"
end
