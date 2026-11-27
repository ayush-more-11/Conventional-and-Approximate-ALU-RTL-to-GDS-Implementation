// File: approx_alu_tb.v
// Rigorous Self-Checking Testbench for Synchronous Approximate ALU
// Validates deliberate approximation errors, carry-chain truncation, and full corner cases.

`timescale 1ns / 1ps

module approx_alu_tb;

    // Testbench stimulus nets
    reg        clk;
    reg        rst_n;
    reg  [7:0] A;
    reg  [7:0] B;
    reg  [2:0] ALU_Sel;
    wire [7:0] ALU_Out;
    wire       CarryOut;

    // Coverage statistics
    integer test_count;
    integer pass_count;
    integer error_count;

    // Instantiate Unit Under Test (UUT)
    approx_alu uut (
        .clk(clk),
        .rst_n(rst_n),
        .A(A),
        .B(B),
        .ALU_Sel(ALU_Sel),
        .ALU_Out(ALU_Out),
        .CarryOut(CarryOut)
    );

    // 100 MHz clock generation (Period = 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Verification task: Evaluates strictly on negedge clk to eliminate race hazards
    task execute_test;
        input [7:0]      in_a;
        input [7:0]      in_b;
        input [2:0]      sel;
        input [7:0]      exp_out;
        input            exp_carry;
        input [8*32:1]   test_name;
        begin
            @(negedge clk);
            A       = in_a;
            B       = in_b;
            ALU_Sel = sel;

            @(negedge clk); // Wait 1 full cycle for register capture
            test_count = test_count + 1;

            if ((ALU_Out !== exp_out) || (CarryOut !== exp_carry)) begin
                $display("[FAIL] %-32s | In: A=0x%02h (%3d), B=0x%02h (%3d) | Exp: Out=0x%02h, C=%b | Got: Out=0x%02h, C=%b at %0t ps",
                         test_name, in_a, in_a, in_b, in_b, exp_out, exp_carry, ALU_Out, CarryOut, $time);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] %-32s | In: A=0x%02h (%3d), B=0x%02h (%3d) | Out: 0x%02h (%3d), Carry: %b",
                         test_name, in_a, in_a, in_b, in_b, ALU_Out, ALU_Out, CarryOut);
                pass_count = pass_count + 1;
            end
        end
    endtask

    initial begin
        test_count  = 0;
        pass_count  = 0;
        error_count = 0;
        A           = 8'h00;
        B           = 8'h00;
        ALU_Sel     = 3'b000;
        rst_n       = 1'b0;

        $display("----------------------------------------------------------------------");
        $display("Starting Rigorous Verification of Synchronous Approximate ALU...");
        $display("----------------------------------------------------------------------");

        // 1. Reset Verification
        #12;
        @(negedge clk);
        if (ALU_Out !== 8'h00 || CarryOut !== 1'b0) begin
            $display("[FAIL] Asynchronous reset assertion failed!");
            error_count = error_count + 1;
        end else begin
            $display("[PASS] Asynchronous reset successfully cleared all pipeline registers.");
        end
        rst_n = 1'b1;
        #5;

        // --------------------------------------------------------------------
        // OPERATION 0: APPROXIMATE ADDITION (ALU_Sel = 3'b000)
        // --------------------------------------------------------------------
        execute_test(8'd0,   8'd0,   3'b000, 8'd0,   1'b0, "ADD_APPX: Zero + Zero");
        
        // Deliberate Error: 3 + 1 = 4 in true math. In approx: top=0, bottom=11|01=11 -> 3
        execute_test(8'd3,   8'd1,   3'b000, 8'd3,   1'b0, "ADD_APPX: Bottom-2 Bit Error");
        
        // Exact Result: 8 + 4 = 12. Bottom bits are 00|00=00, top bits add correctly
        execute_test(8'd8,   8'd4,   3'b000, 8'd12,  1'b0, "ADD_APPX: Exact Alignment");
        
        // Truncated Carry: Top 6 bits overflow (63 + 1 = 64 -> 0 mod 64, carry=1)
        execute_test(8'd252, 8'd4,   3'b000, 8'd0,   1'b1, "ADD_APPX: Top-6 Carry Trigger");
        
        // Full Max: 255 + 255. Top=63+63=126 (62 with carry=1), Bottom=11|11=11 -> Out=251
        execute_test(8'd255, 8'd255, 3'b000, 8'd251, 1'b1, "ADD_APPX: Full Range Max");
        
        // Checkerboard: 0xAA (42, 2) + 0x55 (21, 1). Top=63, Bottom=3 -> 0xFF (255)
        execute_test(8'hAA,  8'h55,  3'b000, 8'hFF,  1'b0, "ADD_APPX: Checkerboard Pattern");

        // --------------------------------------------------------------------
        // OPERATION 1: APPROXIMATE SUBTRACTION (ALU_Sel = 3'b001)
        // --------------------------------------------------------------------
        execute_test(8'd0,   8'd0,   3'b001, 8'd0,   1'b0, "SUB_APPX: Zero - Zero");
        
        // Exact Result: 7 - 2 = 5. Top: 1-0=1, Bottom: 11^10=01 -> 5
        execute_test(8'd7,   8'd2,   3'b001, 8'd5,   1'b0, "SUB_APPX: Exact Alignment");
        
        // Deliberate Error: 4 - 1 = 3 in true math. In approx: Top: 1-0=1, Bottom: 00^01=01 -> 5
        execute_test(8'd4,   8'd1,   3'b001, 8'd5,   1'b0, "SUB_APPX: Bottom-2 Bit Error");
        
        // Self-Cancellation
        execute_test(8'd170, 8'd170, 3'b001, 8'd0,   1'b0, "SUB_APPX: Equal Subtraction");
        
        // Top 6 Underflow Borrow: 0 - 4. Top: 0-1 = -1 (63 with borrow=1), Bottom: 00^00=00 -> 252
        execute_test(8'd0,   8'd4,   3'b001, 8'd252, 1'b1, "SUB_APPX: Top-6 Borrow Trigger");
        
        // Underflow Pattern: 10 - 30. Top: 2 - 7 = -5 (59 with borrow=1), Bottom: 10^10=00 -> 236
        execute_test(8'd10,  8'd30,  3'b001, 8'd236, 1'b1, "SUB_APPX: A < B Negative Diff");

        // --------------------------------------------------------------------
        // OPERATION 2: MULTIPLICATION (ALU_Sel = 3'b010)
        // --------------------------------------------------------------------
        execute_test(8'd0,   8'd0,   3'b010, 8'd0,   1'b0, "MULT: Zero * Zero");
        execute_test(8'd255, 8'd0,   3'b010, 8'd0,   1'b0, "MULT: Max * Zero");
        execute_test(8'd255, 8'd1,   3'b010, 8'd255, 1'b0, "MULT: Identity Factor");
        execute_test(8'd16,  8'd8,   3'b010, 8'd128, 1'b0, "MULT: Powers of Two");
        execute_test(8'd12,  8'd11,  3'b010, 8'd132, 1'b0, "MULT: Mid-Scale Multiplication");
        execute_test(8'd16,  8'd16,  3'b010, 8'd0,   1'b0, "MULT: Truncation at 256");
        execute_test(8'd255, 8'd255, 3'b010, 8'd1,   1'b0, "MULT: Max Truncation (65025)");

        // --------------------------------------------------------------------
        // OPERATION 3: BITWISE AND (ALU_Sel = 3'b011)
        // --------------------------------------------------------------------
        execute_test(8'h00,  8'h00,  3'b011, 8'h00,  1'b0, "AND: All Zeros");
        execute_test(8'hFF,  8'hFF,  3'b011, 8'hFF,  1'b0, "AND: All Ones");
        execute_test(8'hAA,  8'h55,  3'b011, 8'h00,  1'b0, "AND: Orthogonal Alternating");
        execute_test(8'hF0,  8'hAA,  3'b011, 8'hA0,  1'b0, "AND: High Nibble Isolation");

        // --------------------------------------------------------------------
        // OPERATION 4: BITWISE OR (ALU_Sel = 3'b100)
        // --------------------------------------------------------------------
        execute_test(8'h00,  8'h00,  3'b100, 8'h00,  1'b0, "OR: All Zeros");
        execute_test(8'hAA,  8'h55,  3'b100, 8'hFF,  1'b0, "OR: Complement Union");
        execute_test(8'hA5,  8'h00,  3'b100, 8'hA5,  1'b0, "OR: Zero Identity");

        // --------------------------------------------------------------------
        // OPERATION 5: BITWISE XOR (ALU_Sel = 3'b101)
        // --------------------------------------------------------------------
        execute_test(8'hA5,  8'hA5,  3'b101, 8'h00,  1'b0, "XOR: Self Cancellation");
        execute_test(8'hAA,  8'hFF,  3'b101, 8'h55,  1'b0, "XOR: Bit Inversion");
        execute_test(8'h0F,  8'hF0,  3'b101, 8'hFF,  1'b0, "XOR: Nibble Swap Union");

        // --------------------------------------------------------------------
        // OPERATION 6: LOGICAL SHIFT LEFT (ALU_Sel = 3'b110)
        // --------------------------------------------------------------------
        execute_test(8'h01,  8'h00,  3'b110, 8'h02,  1'b0, "SHL: Shift LSB to Bit 1");
        execute_test(8'h40,  8'h00,  3'b110, 8'h80,  1'b0, "SHL: Shift Bit 6 to Bit 7");
        execute_test(8'h80,  8'h00,  3'b110, 8'h00,  1'b1, "SHL: Shift Bit 7 to Carry");
        execute_test(8'hFF,  8'h00,  3'b110, 8'hFE,  1'b1, "SHL: Max Value Shift");

        // --------------------------------------------------------------------
        // OPERATION 7: GREATER THAN COMPARISON (ALU_Sel = 3'b111)
        // --------------------------------------------------------------------
        execute_test(8'd100, 8'd100, 3'b111, 8'd0,   1'b0, "CMP: Equal Inputs (False)");
        execute_test(8'd255, 8'd0,   3'b111, 8'd1,   1'b0, "CMP: 255 > 0 (True)");
        execute_test(8'd0,   8'd255, 3'b111, 8'd0,   1'b0, "CMP: 0 > 255 (False)");
        execute_test(8'd128, 8'd127, 3'b111, 8'd1,   1'b0, "CMP: Boundary 128 > 127 (True)");

        // --------------------------------------------------------------------
        // Summary Report
        // --------------------------------------------------------------------
        #20;
        $display("----------------------------------------------------------------------");
        $display("APPROXIMATE ALU VERIFICATION SUMMARY");
        $display("Total Tests Executed : %0d", test_count);
        $display("Tests Passed          : %0d", pass_count);
        $display("Tests Failed          : %0d", error_count);
        $display("----------------------------------------------------------------------");

        if (error_count == 0) begin
            $display(">>> ALL APPROXIMATE ALU CORNER CASES PASSED SUCCESSFULLY! <<<");
        end else begin
            $display(">>> TESTBENCH FAILED WITH %0d ERRORS. <<<", error_count);
        end

        $finish;
    end

endmodule
