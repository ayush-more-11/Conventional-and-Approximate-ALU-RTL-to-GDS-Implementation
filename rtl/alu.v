`timescale 1ns / 1ps

module alu (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [2:0] ALU_Sel,
    output reg  [7:0] ALU_Out,
    output reg        CarryOut
);

    wire [8:0] sum_extended  = {1'b0, A} + {1'b0, B};
    wire [8:0] diff_extended = {1'b0, A} - {1'b0, B};
    wire [15:0] mult_full    = A * B;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ALU_Out  <= 8'd0;
            CarryOut <= 1'b0;
        end else begin
            case (ALU_Sel)
                3'b000: begin // Addition
                    ALU_Out  <= sum_extended[7:0];
                    CarryOut <= sum_extended[8];
                end
                3'b001: begin // Subtraction
                    ALU_Out  <= diff_extended[7:0];
                    CarryOut <= diff_extended[8];
                end
                3'b010: begin // Multiplication
                    ALU_Out  <= mult_full[7:0];
                    CarryOut <= 1'b0;
                end
                3'b011: begin // Bitwise AND
                    ALU_Out  <= A & B;
                    CarryOut <= 1'b0;
                end
                3'b100: begin // Bitwise OR
                    ALU_Out  <= A | B;
                    CarryOut <= 1'b0;
                end
                3'b101: begin // Bitwise XOR
                    ALU_Out  <= A ^ B;
                    CarryOut <= 1'b0;
                end
                3'b110: begin // Logical Shift Left
                    ALU_Out  <= {A[6:0], 1'b0};
                    CarryOut <= A[7];
                end
                3'b111: begin // Comparison (A > B)
                    ALU_Out  <= (A > B) ? 8'd1 : 8'd0;
                    CarryOut <= 1'b0;
                end
                default: begin
                    ALU_Out  <= 8'd0;
                    CarryOut <= 1'b0;
                end
            endcase
        end
    end

endmodule
