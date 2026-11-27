`timescale 1ns / 1ps

module alu_tb;

    reg        clk;
    reg        rst_n;
    reg  [7:0] A;
    reg  [7:0] B;
    reg  [2:0] ALU_Sel;
    wire [7:0] ALU_Out;
    wire       CarryOut;

    integer test_count;
    integer pass_count;
    integer error_count;

    alu uut (
        .clk(clk),
        .rst_n(rst_n),
        .A(A),
        .B(B),
        .ALU_Sel(ALU_Sel),
        .ALU_Out(ALU_Out),
        .CarryOut(CarryOut)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task execute_test;
        input [7:0]      in_a;
        input [7:0]      in_b;
        input [2:0]      sel;
        input [7:0]      exp_out;
        input            exp_carry;
        input [8*28:1]   test_name;
        begin
            @(negedge clk);
            A       = in_a;
            B       = in_b;
            ALU_Sel = sel;

            @(negedge clk);
            test_count = test_count + 1;

            if ((ALU_Out !== exp_out) || (CarryOut !== exp_carry)) begin
                $display("[FAIL] %-28s | In: A=0x%02h, B=0x%02h | Exp: Out=0x%02h, C=%b | Got: Out=0x%02h, C=%b",
                         test_name, in_a, in_b, exp_out, exp_carry, ALU_Out, CarryOut);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] %-28s | In: A=0x%02h, B=0x%02h | Out: 0x%02h, Carry: %b",
                         test_name, in_a, in_b, ALU_Out, CarryOut);
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

        #12;
        rst_n = 1'b1;
        #5;

        // Op 0: Addition
        execute_test(8'd0,   8'd0,   3'b000, 8'd0,   1'b0, "ADD: Zero + Zero");
        execute_test(8'd255, 8'd1,   3'b000, 8'd0,   1'b1, "ADD: Overflow to Zero");
        execute_test(8'd127, 8'd128, 3'b000, 8'd255, 1'b0, "ADD: Max Non-Overflow");

        // Op 1: Subtraction
        execute_test(8'd200, 8'd50,  3'b001, 8'd150, 1'b0, "SUB: Normal Diff");
        execute_test(8'd10,  8'd30,  3'b001, 8'd236, 1'b1, "SUB: Underflow Borrow");

        // Op 2: Multiplication
        execute_test(8'd12,  8'd11,  3'b010, 8'd132, 1'b0, "MULT: 12 * 11");
        execute_test(8'd16,  8'd16,  3'b010, 8'd0,   1'b0, "MULT: Truncate 256");

        // Op 3: AND
        execute_test(8'hF0,  8'hAA,  3'b011, 8'hA0,  1'b0, "AND: Mask Pattern");

        // Op 4: OR
        execute_test(8'hA5,  8'h5A,  3'b100, 8'hFF,  1'b0, "OR: Bitwise Set");

        // Op 5: XOR
        execute_test(8'hAA,  8'hFF,  3'b101, 8'h55,  1'b0, "XOR: Bit Inversion");

        // Op 6: Shift Left
        execute_test(8'h80,  8'h00,  3'b110, 8'h00,  1'b1, "SHL: Shift MSB to Carry");

        // Op 7: Comparison
        execute_test(8'd200, 8'd100, 3'b111, 8'd1,   1'b0, "CMP: 200 > 100");
        execute_test(8'd50,  8'd100, 3'b111, 8'd0,   1'b0, "CMP: 50 > 100");

        #20;
        $display("------------------------------------------------------------");
        $display("VERIFICATION SUMMARY: %0d Passed, %0d Failed", pass_count, error_count);
        $display("------------------------------------------------------------");
        $finish;
    end

endmodule
