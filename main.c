#include<avr/io.h>
#include<util/delay.h>

void negateBit(int position) {
    if (PORTD & (1 << position)) {
        PORTD &= ~(1 << position);
    } else {
        PORTD |= (1 << position);
    }
}

void doMain() {
    _delay_ms(500);
    negateBit(4);
    negateBit(6);

    //PORTD |= (1 << 6);
//    PORTD &= (0 << 4);

//    _delay_ms(1000);
//    PORTD &= (0 << 6);
//    PORTD |= (1 << 4);
}

void setup() {
    DDRD |= 1 << 6;
    DDRD |= 1 << 4;
}

int main(void) {
    setup();
    PORTD |= (1 << 6);
    PORTD &= ~(1 << 4);
    while (1) {
        doMain();
    }
}