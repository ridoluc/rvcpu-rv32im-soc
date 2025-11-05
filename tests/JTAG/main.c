int global_var[4] = {10,12,-32,52};

int main(){

    int a = 0;
    for (int i = 0; i < 4; i++)
    {
        a += global_var[i];
    }
    
    int * res = (int *)0x00000000;
    *res = a; // Store result in GPIO

    return 0;
}
