/**
 * EXT Peripheral Test Program
 * 
 * This program writes two operands to the EXT peripheral,
 * waits for the computation to complete, reads the result,
 * and writes the result to the GPIO.
 * 
 * Author: ridoluc
 * Date: 2025-11
 */


int main(){

    const int * ext_peripheral = (int *) 0x10000000; // Base address for EXT peripheral
    int * ext_control_reg = (int *) (ext_peripheral + 0); // Control register at offset 0
    int * ext_opA = (int *) (ext_peripheral + 1); // Register 1
    int * ext_opB = (int *) (ext_peripheral + 2); // Register 2
    volatile int * ext_result = (int *) (ext_peripheral + 3); // Result register at offset 3

    *ext_opA = 126; // Write to register 1
    *ext_opB = 76; // Write to register 2

    // Wait for control bit 0 to be 1
    while ((*ext_control_reg & 0x01) == 0);
    int value = *ext_result; // Read from result register

    volatile int * gpio = (int *) 0x00000000; // GPIO base address
    *gpio = value; // Write value to GPIO

    return 0;
}