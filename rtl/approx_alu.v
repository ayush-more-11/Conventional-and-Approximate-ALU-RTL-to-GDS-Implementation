// File: approx_alu.v
// Streamlined Synchronous 8-bit Approximate ALU for ASIC Physical Design Flow
// Target Tools: Cadence Genus (Synthesis), Cadence Innovus (P&R), Vivado (Simulation)
// Features: Lower-Part OR Adder (LOA), Approximate Subtraction, Synchronous Registered I/O

module approx_alu (
    input  wire       clk,        // Clock input for CTS and STA timing closure
    input  wire       rst_n,      // Asynchronous active-low reset
    input  wire [7:0] A,          // 8-bit Operand A
    input  wire [7:0] B,          // 8-bit Operand B
    input  wire [2:0] ALU_Sel,    // 3-bit Operation Select (8 operations matching alu.v)
    output reg  [7:0] ALU_Out,    // 8-bit Registered Output
    output reg        CarryOut    // Registered Carry / Borrow flag
);

    // -------------------------------------------------------------------------
    // Approximate Arithmetic Data Paths:
    // -------------------------------------------------------------------------
    // 1. Approximate Addition (LOA Architecture):
    //    Top 6 bits: Exact standard addition with carry propagation
    //    Bottom 2 bits: Carry-free bitwise OR logic to eliminate critical path delay
    wire [6:0] sum_top6    = {1'b0, A[7:2]} + {1'b0, B[7:2]};
    wire [1:0] sum_bottom2 = A[1:0] | B[1:0];
    wire [7:0] approx_sum  = {sum_top6[5:0], sum_bottom2};

    // 2. Approximate Subtraction:
    //    Top 6 bits: Exact standard subtraction with borrow propagation
    //    Bottom 2 bits: Borrow-free bitwise XOR logic
    wire [6:0] diff_top6    = {1'b0, A[7:2]} - {1'b0, B[7:2]};
    wire [1:0] diff_bottom2 = A[1:0] ^ B[1:0];
    wire [7:0] approx_diff  = {diff_top6[5:0], diff_bottom2};

    // 3. Multiplication: Standard truncated lower 8-bit product (matches alu.v)
    wire [15:0] mult_full   = A * B;

    // -------------------------------------------------------------------------
    // Synchronous Registered Output Pipeline
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ALU_Out  <= 8'd0;
            CarryOut <= 1'b0;
        end else begin
            case (ALU_Sel)
                3'b000: begin // APPROXIMATE Addition
                    ALU_Out  <= approx_sum;
                    CarryOut <= sum_top6[6]; // CarryOut reflects top-6 bit overflow
                end

                3'b001: begin // APPROXIMATE Subtraction
                    ALU_Out  <= approx_diff;
                    CarryOut <= diff_top6[6]; // Borrow flag when A[7:2] < B[7:2]
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

                3'b110: begin // Logical Shift Left by 1
                    ALU_Out  <= {A[6:0], 1'b0};
                    CarryOut <= A[7]; // MSB shifted out into CarryOut
                end

                3'b111: begin // Greater Than Comparison
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
