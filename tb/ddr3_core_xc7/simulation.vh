`timescale 1 ns / 100ps

//-----------------------------------------------------------------
// CLOCK_GEN
//-----------------------------------------------------------------
`define CLOCK_GEN(NAME, CYCLE)     \
    reg ``NAME;      \
    initial \
    begin \
       ``NAME <= 0; \
       forever # (``CYCLE / 2) ``NAME = ~``NAME; \
    end

//-----------------------------------------------------------------
// RESET_GEN
//-----------------------------------------------------------------
`define RESET_GEN(NAME, DELAY)     \
    reg ``NAME;      \
    initial \
    begin \
       ``NAME <= 1; \
       # ``DELAY    \
       ``NAME <= 0; \
    end

//-----------------------------------------------------------------
// TB_VCD
//-----------------------------------------------------------------
`define TB_VCD(TOP, NAME)     \
    initial \
    begin \
       $dumpfile(``NAME);  \
       $dumpvars(0,``TOP); \
    end
