#!/usr/bin/env fish

# Import wspólnych funkcji
set script_dir (dirname (realpath (status filename)))
source $script_dir/common.fish

function print_help
    echo "Użycie: "(basename (status filename))" <host> <plik.hex> [opcje]"
    echo
    echo "Wgrywa plik HEX na mikrokontroler przez RPi."
    echo
    echo "Argumenty:"
    echo "  <host>     docelowy host SSH (np. rpi_local)"
    echo "  <plik.hex> pełna nazwa pliku HEX (np. target/main.hex)"
    echo
    echo "Opcje:"
    echo "  --restart  zrestartuj mikrokontroler po flashu"
    echo "  --trace    włącz szczegółowe śledzenie"
    echo "  -h, --help pokaż pomoc"
    echo
    echo "Przykłady:"
    echo "  "(basename (status filename))" rpi_local target/main.hex"
    echo "  "(basename (status filename))" rpi_local target/main.hex --restart"
end

# Parsowanie argumentów
set -l host ""
set -l hex_file ""
set -l restart_flag 0
set -l trace_flag 0

set -l positional_count 0
for arg in $argv
    switch $arg
        case -h --help
            print_help
            exit 0
        case --restart
            set restart_flag 1
        case --trace
            set trace_flag 1
        case '*'
            set positional_count (math $positional_count + 1)
            if test $positional_count -eq 1
                set host $arg
            else if test $positional_count -eq 2
                set hex_file $arg
            end
    end
end

if test -z "$host" -o -z "$hex_file"
    error "Brak wymaganych argumentów!"
    print_help
    exit 1
end

# Sprawdź czy plik ma rozszerzenie .hex
if not string match -q "*.hex" "$hex_file"
    error "Plik musi mieć rozszerzenie .hex: $hex_file"
    exit 1
end

# Sprawdź czy plik HEX istnieje
check_file_exists "$hex_file" "Plik HEX"
or exit 1

# Wyciągnij nazwę bazową bez rozszerzenia i ścieżki
set -l basename_file (basename (string replace -r '\.hex$' '' "$hex_file"))

# Włącz trace jeśli żądane
if test $trace_flag -eq 1
    set fish_trace 1
end

# Katalog projektów na RPi i nazwa pliku
set -l remote_projects_dir "~/avr-projects"
set -l remote_hexfile_filename "$basename_file.hex"

# Przygotowanie komendy avrdude na RPi (bez ścieżki - tylko nazwa pliku)
set -l avrdude_cmd "sudo avrdude -v -C ~/avrdude.conf -c kma-at2313 -p attiny2313 -U flash:w:$remote_hexfile_filename:i"

info "Wgrywanie $hex_file na $host"
info "Katalog docelowy: $remote_projects_dir"
info "Używamy sprawdzonej komendy avrdude"

# Utworzenie katalogu projektów na RPi jeśli nie istnieje
info "Tworzenie katalogu $remote_projects_dir na RPi..."
ssh $host "mkdir -p $remote_projects_dir"

# Przesłanie pliku HEX na RPi do katalogu projektów
info "Przesyłanie $hex_file na RPi..."
run "scp $hex_file $host:$remote_projects_dir/$remote_hexfile_filename"
or exit 1

# Sprawdź czy plik został prawidłowo przesłany
info "Sprawdzanie czy plik został przesłany..."
ssh $host "test -f $remote_projects_dir/$remote_hexfile_filename && echo 'Plik istnieje na RPi: $remote_projects_dir/$remote_hexfile_filename' || echo 'BŁĄD: Plik nie istnieje!'"

info "Komenda avrdude: $avrdude_cmd"

# Programowanie na RPi - WAŻNE: cd do katalogu z plikiem przed avrdude
ssh $host "cd $remote_projects_dir && $avrdude_cmd"
set -l flash_result $status

# Usunięcie tymczasowego pliku z RPi
ssh $host "rm -f $remote_projects_dir/$remote_hexfile_filename" >/dev/null 2>&1

if test $flash_result -eq 0
    info "✅ Wgrywanie zakończone pomyślnie!"

    # Restart mikrokontrolera jeśli żądany
    if test $restart_flag -eq 1
        info "Restartowanie mikrokontrolera..."
        ssh $host "echo 'Restart MCU - implementuj zgodnie z Twoim setupem GPIO'"
    end

    # Pokaż statystyki
    set -l hex_size (wc -c < $hex_file)
    info "Rozmiar pliku HEX: $hex_size bajtów"

else
    error "❌ Wgrywanie nie powiodło się (kod: $flash_result)"
    warn "Sprawdź połączenie SSH i konfigurację avrdude na RPi"
    exit $flash_result
end

info "🎉 Gotowe!"
