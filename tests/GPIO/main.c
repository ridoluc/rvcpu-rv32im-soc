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



/**
 * Test program for MULDIV unit
 *  
 */ 

// int global_var[5] = {70,146,1601,150, 670};

// int main(){

//     int a = 0;

//     a = global_var[0];
//     a *= global_var[1];
//     a *= global_var[2];
//     a /= global_var[3];
//     a /= global_var[4];
    
//     int * res = (int *)0x00000000;
//     *res = a; // Store result in GPIO

//     return 0;
// }