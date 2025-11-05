/**
 * Simple Timer Test Program
 * 
 * This program configures a timer to count down from a specified value,
 * waits for the timer to reach zero, and toggles a GPIO output each time
 * the timer expires.
 * 
 * Author: ridoluc
 * Date: 2025-11
 */


int main() {
    volatile int * timer = (int *)0x00000080; // Timer base address
    volatile int * timer_control = (int *)(timer); // Timer control register
    volatile int * timer_value = (int *)(timer + 1); // Timer value register
    volatile int * timer_prescaler = (int *)(timer + 2); // Timer prescaler register
    volatile int * timer_compare = (int *)(timer + 3); // Timer compare register    

    volatile int * gpio = (int *) 0x00000000; // GPIO base address

    // Set timer to count down from 50
    *timer_compare = 50;
    *timer_prescaler = 2; 
    *timer_control = 0x01; // Start the timer

    while (1) {
        if (*timer_control ==3) { // Check if timer has reached zero
            *timer_control |= 0x02; // Clear the interrupt flag
            // Timer reached zero, perform action here

            *gpio ^= 0x01; // Set GPIO to indicate timer event

        }
    }

    return 0;
}
