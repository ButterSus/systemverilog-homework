//
//  schoolRISCV - small RISC-V CPU
//
//  Originally based on Sarah L. Harris MIPS CPU
//  & schoolMIPS project.
//
//  Copyright (c) 2017-2020 Stanislav Zhelnio & Aleksandr Romanov.
//
//  Modified in 2024 by Yuri Panchul & Mike Kuskov
//  for systemverilog-homework project.
//

module cpu_cluster
#(
    parameter nCPUs  = 3,
              nBANKs = 4,
              SIZE   = 64
)
(
    input                             clk,      // clock
    input                             rst,      // reset

    input        [nCPUs - 1:0][31:0]  rstPC,    // program counter set on reset
    input        [nCPUs - 1:0][ 4:0]  regAddr,  // debug access reg address
    output logic [nCPUs - 1:0][31:0]  regData   // debug access reg data
);

    localparam BANK_ADDR_W = $clog2(nBANKs);

    `ifndef SYNTHESIS
    initial assert ((1 << BANK_ADDR_W) == nBANKs)
        else $fatal("nBANKs must be power of 2");
    initial assert ((SIZE % nBANKs) == 0) 
        else $fatal("SIZE must be divisible by nBANKs");
    `endif

    genvar i;

    //-----------------
    // Shared ROM banks

    wire  [31:0] bank_imData [nBANKs - 1:0];
    logic [31:0] bank_imAddr [nBANKs - 1:0];

    // verilator lint_off VARHIDDEN
    always_comb
        for (int i = 0; i < nBANKs; i ++) begin
            bank_imAddr [i] = nCPUs' ('x);

            for (int j = 0; j < nCPUs; j ++)
                if (bank_gnt [i][j])
                    bank_imAddr [i] = cpu_imAddr[j][31:BANK_ADDR_W];
        end
    // verilator lint_on VARHIDDEN

    generate
        for (i = 0; i < nBANKs; i ++) begin
            instruction_rom #(
                .SIZE    ( SIZE / nBANKs ),
                .BANK_ID ( i             ),
                .nBANKs  ( nBANKs        )
            ) i_bank_rom
            (
                .a  ( bank_imAddr [i] ),
                .rd ( bank_imData [i] )
            );
        end
    endgenerate

    //-----------------
    // Per-bank arbiters

    wire  [nCPUs - 1:0] bank_gnt [0:nBANKs - 1];
    logic [nCPUs - 1:0] bank_req [0:nBANKs - 1];

    // verilator lint_off VARHIDDEN
    always_comb
        for (int i = 0; i < nBANKs; i ++)
            for (int j = 0; j < nCPUs; j ++)
                bank_req [i][j] = (cpu_bank_sel [j] == i);
    // verilator lint_on VARHIDDEN
    
    generate
        for (i = 0; i < nBANKs; i ++) begin
            round_robin_arbiter #(.N(nCPUs)) i_bank_arbiter
            (
                .clk ( clk          ),
                .rst ( rst          ),
                .req ( bank_req [i] ),
                .gnt ( bank_gnt [i] )
            );
        end
    endgenerate

    // Module instantiations

    wire  [31:0] cpu_imAddr    [0:nCPUs - 1];
    logic [31:0] cpu_imData    [0:nCPUs - 1];
    logic        cpu_imDataVld [0:nCPUs - 1];

    // verilator lint_off VARHIDDEN
    always_comb
        for (int i = 0; i < nCPUs; i ++) begin
            cpu_imData    [i] = bank_imData [cpu_bank_sel [i]];
            cpu_imDataVld [i] = bank_gnt    [cpu_bank_sel [i]][i];
        end
    // verilator lint_on VARHIDDEN

    logic [BANK_ADDR_W - 1:0] cpu_bank_sel [0:nCPUs - 1];

    // verilator lint_off VARHIDDEN
    always_comb
        for (int i = 0; i < nCPUs; i ++) begin
            // Note, address lower 2 bits are always 2'b00
            cpu_bank_sel [i] = cpu_imAddr [i][BANK_ADDR_W - 1:0];
        end
    // verilator lint_on VARHIDDEN

    generate
        for (i = 0; i < nCPUs; i ++) begin
            sr_cpu i_cpu
            (
                .clk       ( clk               ),
                .rst       ( rst               ),
                .rstPC     ( rstPC         [i] ),
                .imAddr    ( cpu_imAddr    [i] ),
                .imData    ( cpu_imData    [i] ),
                .imDataVld ( cpu_imDataVld [i] ),
                .regAddr   ( regAddr       [i] ),
                .regData   ( regData       [i] )
            );
        end
    endgenerate

endmodule
