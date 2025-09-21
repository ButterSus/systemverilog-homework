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
    parameter nCPUs = 3
)
(
    input                             clk,      // clock
    input                             rst,      // reset

    input        [nCPUs - 1:0][31:0]  rstPC,    // program counter set on reset
    input        [nCPUs - 1:0][ 4:0]  regAddr,  // debug access reg address
    output logic [nCPUs - 1:0][31:0]  regData   // debug access reg data
);

    // Shared ROM

    wire  [31:0] imData;
    logic [31:0] imAddr;

    always_comb begin
        imAddr = nCPUs' (0);

        for (int i = 0; i < nCPUs; i ++)
            if (gnt [i])
                imAddr  = cpu_imAddr  [i];
    end

    instruction_rom i_rom
    (
        .a  ( imAddr ),
        .rd ( imData )
    );

    // Arbiter

    wire [nCPUs - 1:0] gnt;
    
    round_robin_arbiter #(.N(nCPUs)) i_arbiter
    (
        .clk ( clk                       ),
        .rst ( rst                       ),
        .req ( nCPUs' ((1 << nCPUs) - 1) ),
        .gnt ( gnt                       )
    );

    // Module instantiations

    wire [31:0] cpu_imAddr  [nCPUs - 1:0];

    generate
        genvar i;

        for (i = 0; i < nCPUs; i ++) begin
            sr_cpu i_cpu
            (
                .clk       ( clk            ),
                .rst       ( rst            ),
                .rstPC     ( rstPC      [i] ),
                .imAddr    ( cpu_imAddr [i] ),
                .imData    ( imData         ),
                .imDataVld ( gnt        [i] ),
                .regAddr   ( regAddr    [i] ),
                .regData   ( regData    [i] )
            );
        end
    endgenerate

endmodule
