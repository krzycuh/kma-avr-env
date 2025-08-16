#!/usr/bin/env fish

# Skrypt do dodania avr-build do PATH
# Uruchom: source setup-path.fish

set script_dir (dirname (realpath (status filename)))
set avr_lib_dir "$script_dir/lib"

# Sprawdź czy katalog lib istnieje
if not test -d "$avr_lib_dir"
    echo "❌ Błąd: Katalog $avr_lib_dir nie istnieje!"
    return 1
end

# Sprawdź czy avr-build istnieje
if not test -f "$avr_lib_dir/avr-build"
    echo "❌ Błąd: Plik $avr_lib_dir/avr-build nie istnieje!"
    return 1
end

# Dodaj do PATH jeśli jeszcze nie ma
if not contains "$avr_lib_dir" $PATH
    set -gx PATH "$avr_lib_dir" $PATH
    echo "✅ Dodano $avr_lib_dir do PATH"

    # Sprawdź czy działa
    if command -v avr-build >/dev/null
        echo "✅ Komenda 'avr-build' jest teraz dostępna!"
        echo ""
        echo "Przykłady użycia:"
        echo "  avr-build rpi_local main.c"
        echo "  avr-build rpi_local projects/threediodes.c --size"
        echo "  cd projects && avr-build rpi_local main.c --restart"
        echo ""
        echo "Aby dodać na stałe do Fish, uruchom:"
        echo "  echo 'set -gx PATH \"$avr_lib_dir\" \$PATH' >> ~/.config/fish/config.fish"
    else
        echo "❌ Błąd: 'avr-build' nadal nie jest dostępne"
    end
else
    echo "ℹ️  $avr_lib_dir już jest w PATH"
end
