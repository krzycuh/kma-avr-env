/*
 * Program do sterowania trzema diodami LED na ATtiny2313
 * 
 * Program tworzy sekwencyjny efekt świecenia trzech diod LED:
 * - PD2 (pin 6): pierwsza dioda w sekwencji
 * - PD4 (pin 8): druga dioda w sekwencji
 * - PD6 (pin 11): trzecia dioda w sekwencji
 * 
 * W każdym momencie świeci się tylko jedna dioda, tworząc efekt
 * "biegającego światła" z szybkim przełączaniem co 20ms.
 * 
 * Częstotliwość procesora: 1MHz (F_CPU=1000000UL)
 * Opóźnienie: 20ms między przełączeniami (szybka animacja)
 */

#include<avr/io.h>
#include<util/delay.h>

const int delayTime = 300;  // Czas opóźnienia w milisekundach



/**
 * Przełącza stan bitu na porcie D (0->1, 1->0)
 * @param position - numer bitu do przełączenia (0-7)
 * UWAGA: Ta funkcja nie jest używana w głównej logice programu
 */
void negateBit(int position) {
    if (PORTD & (1 << position)) {
        PORTD &= ~(1 << position);  // Jeśli bit jest 1, ustaw na 0
    } else {
        PORTD |= (1 << position);   // Jeśli bit jest 0, ustaw na 1
    }
}

/**
 * Włącza tylko jeden pin na porcie D i wyłącza wszystkie pozostałe
 * Następnie czeka przez określony czas
 * @param position - numer pinu do włączenia (pozostałe będą wyłączone)
 */
void enableBitAndDisableOthersForDelay(int position) {
    PORTD = (1 << position);    // Ustaw tylko jeden bit, reszta = 0
    _delay_ms(delayTime);       // Czekaj przez określony czas
}

/**
 * Główna logika programu - sekwencyjne włączanie diod LED
 * Tworzy efekt "biegającego światła" PD2 -> PD4 -> PD6 -> PD2...
 */
void doMain() {
    enableBitAndDisableOthersForDelay(2);  // Włącz tylko PD2 (20ms)
    enableBitAndDisableOthersForDelay(4);  // Włącz tylko PD4 (20ms)
    enableBitAndDisableOthersForDelay(6);  // Włącz tylko PD6 (20ms)

    //PORTD |= (1 << 6);
//    PORTD &= (0 << 4);

//    _delay_ms(1000);
//    PORTD &= (0 << 6);
//    PORTD |= (1 << 4);
}

/**
 * Konfiguracja pinów jako wyjścia dla trzech diod LED
 */
void setup() {
    DDRD |= 1 << 6;     // Pin PD6 jako wyjście (LED 3)
    DDRD |= 1 << 4;     // Pin PD4 jako wyjście (LED 2) 
    DDRD |= 1 << 2;     // Pin PD2 jako wyjście (LED 1)
}

int main(void) {
    setup();                    // Konfiguruj piny PD2, PD4, PD6 jako wyjścia

    // Początkowy stan: wszystkie diody wyłączone
    // PORTD |= (1 << 6);       // Opcjonalnie: włącz PD6
    // PORTD &= ~(1 << 4);      // Opcjonalnie: wyłącz PD4  
    // PORTD &= ~(1 << 2);      // Opcjonalnie: wyłącz PD2

    while (1) {                 // Nieskończona pętla animacji
        doMain();               // Wykonuj sekwencję świecenia diod
    }
}