.section .text
.global _start

_start:
    # Initialize the stack pointer
    la sp, _stack

    # Copy .data from IMEM to DMEM
    la a0, _data_load_start       # Load destination address (start of .data in DMEM)
    la a1, _data_start          # Load source address (start of .data in IMEM)
    la a2, _data_load_end         # Load end address of .data in DMEM
copy_data:
    beq a0, a2, call_main    # If all .data is copied, jump to clear_bss
    lw t0, 0(a0)             # Load word from source
    sw t0, 0(a1)             # Store word to destination
    addi a0, a0, 4           # Increment destination pointer
    addi a1, a1, 4           # Increment source pointer
    j copy_data              # Repeat

    # Call main
call_main:
    call main                # Call the main function

    # Infinite loop after main
exit:
    j exit