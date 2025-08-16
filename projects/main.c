/*
 * Program do sterowania dwoma wyjściami cyfrowych na ATtiny2313
 * 
 * Program przełącza stany pinów PD4 i PD6 w nieskończonej pętli:
 * - Pin PD6: początkowo HIGH, następnie przełączany co 500ms
 * - Pin PD4: początkowo LOW, następnie przełączany co 500ms
 * 
 * Może służyć do sterowania LED, przekaźnikami lub innymi urządzeniami
 * wymagającymi cyklicznego przełączania stanów.
 * 
 * Częstotliwość procesora: 1MHz (F_CPU=1000000UL)
 * Opóźnienie: 500ms między przełączeniami
 */

#include<avr/io.h>
#include<util/delay.h>

/**
 * Przełącza stan bitu na porcie D (0->1, 1->0)
 * @param position - numer bitu do przełączenia (0-7)
 */
void negateBit(int position) {
    if (PORTD & (1 << position)) {
        PORTD &= ~(1 << position);  // Jeśli bit jest 1, ustaw na 0
    } else {
        PORTD |= (1 << position);   // Jeśli bit jest 0, ustaw na 1
    }
}

/**
 * Główna logika programu - przełącza piny PD4 i PD6 co 500ms
 */
void doMain() {
    _delay_ms(500);     // Opóźnienie 500ms
    negateBit(4);       // Przełącz pin PD4
    negateBit(6);       // Przełącz pin PD6

    //PORTD |= (1 << 6);
//    PORTD &= (0 << 4);

//    _delay_ms(1000);
//    PORTD &= (0 << 6);
//    PORTD |= (1 << 4);
}

/**
 * Konfiguracja pinów jako wyjścia
 */
void setup() {
    DDRD |= 1 << 6;     // Pin PD6 jako wyjście
    DDRD |= 1 << 4;     // Pin PD4 jako wyjście
}

int main(void) {
    setup();               // Konfiguruj piny jako wyjścia
    PORTD |= (1 << 6);     // Ustaw PD6 na HIGH (stan początkowy)
    PORTD &= ~(1 << 4);    // Ustaw PD4 na LOW (stan początkowy)

    while (1) {            // Nieskończona pętla
        doMain();          // Wykonuj główną logikę programu
    }
}