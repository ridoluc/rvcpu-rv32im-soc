ENTRY(_start)

/* Define memory regions */
MEMORY
{
    IMEM (rx) : ORIGIN = 0x80000000, LENGTH = 0x400  /* Instruction memory: 1024 bytes */
    DMEM (rw) : ORIGIN = 0x00000100, LENGTH = 0x100  /* Data memory: 256 bytes */
}

/* Define sections and their placement */
SECTIONS
{
    /* Place the .text section in instruction memory (IMEM) */
    .text : 
    {
        KEEP(*(.text._start))  /* Ensure _start is placed first */
        *(.text)               /* All other .text sections */
        *(.text.*)             /* All .text.* sections */
    } > IMEM       /* Logical address starts at 0x0, but load at 0x80000000 */

    /* Place the .rodata section in instruction memory (IMEM) */
    .rodata : 
    {
        _rodata_start = .;
        *(.rodata)             /* Read-only data */
        *(.rodata.*)           /* All .rodata.* sections */
    } > IMEM 

    .srodata : 
    {
        *(.srodata)             /* Read-only data */
        *(.srodata.*)           /* All .rodata.* sections */
    } > IMEM 

    /* Place the .data section in data memory (DMEM) */
    .data :
    {
        _data_start = .;       /* Mark the start of .data in DMEM */
        *(.data)               /* All .data sections */
        *(.data.*)             /* All .data.* sections */
    } > DMEM AT > IMEM         /* Load .data into IMEM but run it in DMEM */

    .sdata :
    {
        _sdata_start = .;
        *(.sdata)               /* All .sdata sections */
        *(.sdata.*)             /* All .sdata.* sections */
        _sdata_end = .;
    } > DMEM AT > IMEM

    /* Define the load address of .data in IMEM */
    _data_load_start = LOADADDR(.data)+0x80000000;
    _data_load_end = _data_load_start + SIZEOF(.data)+ + SIZEOF(.sdata);

    /* Place the .bss section in data memory (DMEM) */
    .bss :
    {
        _bss_start = .;        /* Mark the start of .bss in DMEM */
        *(.bss)                /* All .bss sections */
        *(.bss.*)              /* All .bss.* sections */
        *(COMMON)              /* Common symbols */
        _bss_end = .;          /* Mark the end of .bss in DMEM */
    } > DMEM

    /* Define the stack at the top of data memory */
    _stack = ORIGIN(DMEM) + LENGTH(DMEM);  /* Stack grows downward */
}