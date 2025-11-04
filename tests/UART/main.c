// Test program to write and read from UART

int main() {
    volatile int * uart = (int *)0x00000040; // UART base address
    volatile int * uart_control = (int *)(uart + 2); // UART control register
    volatile int * uart_read = (int *)(uart + 1); // UART read register

    
    int * uart_baud = (int *)(uart + 3); // UART baud rate register
    
    // UART BAUD counter set arbitrarily to 100 matching the testbench  
    // For real tests set the BAUD register according to the actual CPU frequency.
    // Example: CPU Freq = 50MHz, Baud rate = 9600
    // UART Baud setting = 50,000,000 / 9,600 = 5208
    *uart_baud = 100;
    

    int count_max =0;
    int counter = 0;

    // char message[] = "Hello UART\n\r";

    while(1){

        // RECEIVE STRING
        // for (int i = 0; i < 12; i++) {
        //     while (*uart_control & 0x01); // Wait until UART buffer is not full
        //     *uart = message[i]; // Write character to UART
        //     // delay_1s(); // Delay to ensure UART is ready
        // }

        // RECEIVE CHARACTER AND ECHO BACK
        if(*uart_control & 0x08) { // Check if UART is ready to read
            char data = *uart_read; // Read data from UART
            while (*uart_control & 0x01); // Wait until UART buffer is not full
            *uart = data; // Echo the received character back
        }
    }

    return 0;
}
