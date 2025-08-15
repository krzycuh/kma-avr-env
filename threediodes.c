#include<avr/io.h>
#include<util/delay.h>

const int delayTime = 20;



void negateBit(int position) {
    if (PORTD & (1 << position)) {
        PORTD &= ~(1 << position);
    } else {
        PORTD |= (1 << position);
    }
}

void enableBitAndDisableOthersForDelay(int position) {
    PORTD = (1 << position);
    _delay_ms(delayTime);
}

void doMain() {
    enableBitAndDisableOthersForDelay(2);
    enableBitAndDisableOthersForDelay(4);
    enableBitAndDisableOthersForDelay(6);

    //PORTD |= (1 << 6);
//    PORTD &= (0 << 4);

//    _delay_ms(1000);
//    PORTD &= (0 << 6);
//    PORTD |= (1 << 4);
}

void setup() {
    DDRD |= 1 << 6;
    DDRD |= 1 << 4;
    DDRD |= 1 << 2;
}

int main(void) {
    setup();
    // PORTD |= (1 << 6);
    // PORTD &= ~(1 << 4);
    // PORTD &= ~(1 << 2);
    while (1) {
        doMain();
    }
}