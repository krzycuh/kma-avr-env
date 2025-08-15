# AVR Development Environment

## Kompilacja i programowanie AVR (ATtiny2313)

Skrypt `compile-and-upload.fish` kompiluje kod C (AVR-GCC) na macOS, generuje plik `.hex` i programuje mikrokontroler na Raspberry Pi przez SSH (z użyciem `avrdude`).

### Wymagania

- macOS:
  - Fish (shell)
  - avr-gcc, avr-libc, avr-binutils (`avr-objcopy`, `avr-size`)
  - ssh
- Raspberry Pi (host zdalny):
  - avrdude (dostępny jako `sudo avrdude`)
  - plik konfiguracyjny `~/avrdude.conf` (dostosuj ścieżkę w skrypcie, jeśli inna)
  - konfiguracja programatora pod nazwą `kma-at2313` (zmień, jeśli używasz innego)

Domyślny układ w skrypcie: `attiny2313`, `F_CPU=1000000UL`.

### Konfiguracja Raspberry Pi (GPIO/avrdude)

1) Zainstaluj `avrdude` na RPi:

```bash
sudo apt update && sudo apt install -y avrdude
```

2) Przygotuj własny plik `~/avrdude.conf` i dodaj definicję programatora GPIO. Najprościej skopiować systemowy plik i dopisać własny blok.
Numery pinów są w notacji BCM (GPIO4, GPIO11, GPIO10, GPIO9). Powyższa konfiguracja odpowiada Twojej przykładowej: 

```bash
cp /etc/avrdude.conf ~/avrdude.conf
cat >> ~/avrdude.conf <<'EOF'
programmer
  id    = "kma-at2313";
  desc  = "Use the Linux sysfs interface to bitbang GPIO lines";
  type  = "linuxgpio";
  reset = 4;
  sck   = 11;
  mosi  = 10;
  miso  = 9;
;
EOF
```

3) Upewnij się, że piny nie są używane przez inne interfejsy. Jeśli używasz domyślnych linii SPI (GPIO9/10/11) jako zwykłych GPIO, najlepiej wyłącz SPI w `raspi-config`:

```bash
sudo raspi-config  # Interfacing Options -> SPI -> Disable
```

4) Podłącz przewody do ATtiny2313: `MOSI`, `MISO`, `SCK`, `RESET`, plus `VCC` i `GND`.

- Bezpieczeństwo napięciowe: Raspberry Pi pracuje na 3.3V. Jeśli ATtiny jest zasilany 5V, użyj konwersji poziomów (level shifter/oporniki). Najbezpieczniej zasilić ATtiny z 3.3V podczas programowania.
- `RESET` powinien mieć rezystor podciągający do VCC (typowo 10kΩ).

5) Test po stronie RPi (bez programowania, tylko wykrycie układu):

```bash
sudo avrdude -v -C ~/avrdude.conf -c kma-at2313 -p attiny2313 -n
```

Skrypt używa dokładnie tej konfiguracji (parametr `-C ~/avrdude.conf` i programator `-c kma-at2313`).

### Użycie

```bash
./compile-and-upload.fish <host> <plik.c> [opcje]
```

- **host**: alias lub adres SSH (np. `rpi_local`, `user@rpi.local`)
- **plik.c**: ścieżka do źródła C (musi kończyć się na `.c`)

### Opcje

- `--verify`: weryfikuj po zaprogramowaniu
- `--restart`: zrestartuj mikrokontroler po flashu (sekcja do dostosowania na RPi)
- `--size`: pokaż rozmiary sekcji, zapisz mapę do `*.map`
- `--trace`: włącz szczegółowe śledzenie działania skryptu
- `-h`, `--help`: pokaż pomoc

### Przykłady

```bash
# Kompilacja i programowanie z weryfikacją
./compile-and-upload.fish rpi_local attiny-rpi-com.c --verify

# Podgląd rozmiarów i restart po flashu
./compile-and-upload.fish rpi_local attiny-rpi-com.c --size --restart

# Diagnostyka
./compile-and-upload.fish rpi_local attiny-rpi-com.c --trace
```

### Co robi skrypt

1. Waliduje argumenty i opcje.
2. Ustawia parametry projektu (`MCU=attiny2313`, `F_CPU=1000000UL`).
3. Czyści poprzednie artefakty (`*.bin`, `*.hex`, `*.map` dla danego pliku).
4. Kompiluje do `.bin` i generuje `.hex`.
5. Opcjonalnie wyświetla rozmiary (`--size`).
6. Programuje układ przez SSH, przesyłając `.hex` potokiem do `avrdude` na RPi.
7. Opcjonalnie weryfikuje (`--verify`) i restartuje (`--restart`).
8. Zwraca czytelne logi i kod błędu w razie niepowodzenia.

Artefakty: `nazwa.bin`, `nazwa.hex`, `nazwa.map` (dla `--size`).

### Dostosowanie

- Zmień `MCU`, `F_CPU` w skrypcie, jeśli używasz innego układu.
- Dostosuj `avrdude_cmd` (przełączniki `-c`, `-p`, `-C` i inne) do Twojego programatora i konfiguracji.
- Podmień sekcję restartu (`--restart`) na realne sterowanie GPIO/rezetem na RPi.

### Rozwiązywanie problemów

- Brak połączenia SSH: sprawdź `ssh <host>`, klucze i wpisy w `~/.ssh/config` (np. alias `rpi_local`).
- Brak `avrdude` lub `~/avrdude.conf` na RPi: zainstaluj i/lub popraw ścieżkę w skrypcie.
- Zły programator: dopasuj `-c` w `avrdude_cmd`.
- Błędny plik wejściowy: podaj istniejący plik zakończony `.c`.

### Pomoc

```bash
./compile-and-upload.fish --help
```
