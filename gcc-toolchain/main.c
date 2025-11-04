// #include <stdint.h>
// #define FIXED_SHIFT 10  
// #define FIXED_SCALE (1 << FIXED_SHIFT)


// int main() {
//     int pi_fixed = 0;  // Fixed-point π approximation
//     int term;
//     int sign = 1;

//     for (int n = 0; n < 10; n++) {  // Increase iterations for more precision
//         term = FIXED_SCALE/(2 * n + 1); // 1/(2n+1) in fixed point
//         pi_fixed += sign * term;
//         sign = -sign;
//     }

//     int * res = (int *)(0xA8+0x100);
//     *res = pi_fixed*4; // Store result in memory location 0x4A8

//     // GPIO done 
//     int * gpio = (int *)0x00000000;
//     *gpio = 0x1; // Set GPIO to indicate completion

//     return 0;   
// }


// int global_var[4] = {0,1,2,3};

// int main(){

//     int a = 0;
//     for (int i = 0; i < 4; i++)
//     {
//         a += global_var[i];
//     }
    
//     int * res = (int *)(0xA8+0x100); // Memory location 0xA8+0x100 (dec = 168+256 = 424); 0x100 is the RAM base address
//     *res = a; // Store result in memory location 0xA8 (dec = 168 (42))

//     return 0;
// }

// int main(){
//     int a = 66000;
//     int b = 66000;

//     long long c = (long long) a*b; // Multiply a and b
//     int * res = (int *)(0xA8+0x100);
//     *res = c; // Store result in memory location 0xA8 (dec = 168)
//     *(res + 1) = c >> 32; // Store the upper 32 bits of the result
// }

// void delay_1s() {
//     unsigned int count = 50000000/3; // Adjust count for 1 second delay at 50MHz clock
//     asm volatile (
//         "1: \n"
//         "addi %0, %0, -1 \n" // Decrement count
//         "bnez %0, 1b \n"     // Loop if count != 0
//         : "+r" (count)       // Output operand (count in a register)
//         :                    // No input operands
//         :                    // No clobbered registers
//     );
// }

// int main() {

//     volatile int * gpio = (int *)0x00000400;

//     char sum = 0;


//     while(1){
//         sum++;
//         *gpio = (unsigned int)sum;
//         // delay_1s();
//     }

// }

// int global_var[4] = {10,12,-32,52};

// int main(){

//     int a = 0;
//     for (int i = 0; i < 4; i++)
//     {
//         a += global_var[i];
//     }
    
//     int * res = (int *)0x00000000;
//     *res = a; // Store result in GPIO

//     return 0;
// }


// int global_var[5] = {70,146,1601,150, 670};

// int main(){

//     int a = 0;

//     a = global_var[0];
//     a *= global_var[1];
//     a *= global_var[2];
//     a /= global_var[3];
//     a /= global_var[4];
    
//     int * res = (int *)0x00000400;
//     *res = a; // Store result in GPIO

//     return 0;
// }


/// @brief  Test program to read GPIO inputs and write them to GPIO outputs
int main(){

    const int * GPIO_base = (int *) 0x00000000; // Base address for GPIO
    int * GPIO_out =  (int *) (GPIO_base + 0); // GPIO output register
    int * GPIO_dir =  (int *) (GPIO_base + 1); // GPIO direction register
    int * GPIO_in =   (int *) (GPIO_base + 3); // GPIO input register    

    // *GPIO_dir = 0b11110000; // Example: Set GPIOs 0-3 as outputs, 4-7 as inputs

    while (1){
        *GPIO_out = *GPIO_in; // Read inputs and write to outputs
    }
}


// Test program to write to UART at address 0x00000040
// int main() {
//     volatile int * uart = (int *)0x00000040; // UART base address
//     volatile int * uart_control = (int *)(uart + 2); // UART control register
//     volatile int * uart_read = (int *)(uart + 1); // UART read register
    
//     int * GPIO_out =  (int *) 0x00000000;
//     int * GPIO_in =   (int *) 0x0000000C; // GPIO input register

//     char message[] = "Hello UART\n\r";
    
//     int * uart_baud = (int *)(uart + 3); // UART baud rate register
//     *uart_baud = 100;//5208;
    
//     // delay_1s(); // Delay to ensure UART is ready

//     // for (int i = 0; i < 12; i++) {
//     //     while (*uart_control & 0x01); // Wait until UART buffer is not full
//     //     *uart = message[i]; // Write character to UART
//     //     // delay_1s(); // Delay to ensure UART is ready
//     // }

//     int count_max =0;
//     int counter = 0;

//     while(1){
        
//         // count_max = *GPIO_in;
//         // counter++;
//         // if(counter > count_max) {
//         //     counter = 0; // Reset count if it exceeds max
//         // }
//         // *GPIO_out = counter; // Read GPIO inputs and write to GPIO outputs

//         // delay_1s(); // Delay to allow UART to process


//         *GPIO_out = *GPIO_in;
//         // for (int i = 0; i < 12; i++) {
//         //     while (*uart_control & 0x01); // Wait until UART buffer is not full
//         //     *uart = message[i]; // Write character to UART
//         //     // delay_1s(); // Delay to ensure UART is ready
//         // }

//         if(*uart_control & 0x08) { // Check if UART is ready to read
//             char data = *uart_read; // Read data from UART
//             while (*uart_control & 0x01); // Wait until UART buffer is not full
//             *uart = data; // Echo the received character back
//         }
//     }

//     return 0;
// }


// int main() {
//     volatile int * timer = (int *)0x00000080; // Timer base address
//     volatile int * timer_control = (int *)(timer); // Timer control register
//     volatile int * timer_value = (int *)(timer + 1); // Timer value register
//     volatile int * timer_prescaler = (int *)(timer + 2); // Timer prescaler register
//     volatile int * timer_compare = (int *)(timer + 3); // Timer compare register    

//     volatile int * gpio = (int *) 0x00000000; // GPIO base address

//     // Set timer to count down from 50
//     *timer_compare = 50;
//     *timer_prescaler = 2; 
//     *timer_control = 0x01; // Start the timer

//     while (1) {
//         if (*timer_control ==3) { // Check if timer has reached zero
//             *timer_control |= 0x02; // Clear the interrupt flag
//             // Timer reached zero, perform action here

//             *gpio ^= 0x01; // Set GPIO to indicate timer event

//         }
//     }

//     return 0;
// }


// int main(){

//     const int * ext_peripheral = (int *) 0x10000000; // Base address for EXT peripheral
//     int * ext_control_reg = (int *) (ext_peripheral + 0); // Control register at offset 0
//     int * ext_opA = (int *) (ext_peripheral + 1); // Register 1
//     int * ext_opB = (int *) (ext_peripheral + 2); // Register 2
//     volatile int * ext_result = (int *) (ext_peripheral + 3); // Result register at offset 3

//     *ext_opA = 126; // Write to register 1
//     *ext_opB = 251; // Write to register 2

//     // Wait for control bit 0 to be 1
//     while ((*ext_control_reg & 0x01) == 0);
//     int value = *ext_result; // Read from result register

//     volatile int * gpio = (int *) 0x00000000; // GPIO base address
//     *gpio = value; // Write value to GPIO

//     return 0;
// }