/**
 * Test program for calculating π using the Leibniz formula
 * 
 * This program uses a fixed-point representation to calculate an approximation of π
 * using the Leibniz formula: π = 4 * (1 - 1/3 + 1/5 - 1/7 + ...).
 * The result is stored in a specific memory location.
 * 
 * Author: ridoluc
 * Date: 2025-11
 */


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

