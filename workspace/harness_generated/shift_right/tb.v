`timescale 1ns/1ps

module tb;

    reg [49:0] in;
    reg [2:0] shift;
    reg [4:0] fill;
    wire out_valid;
    wire [49:0] out;

    shift_right dut (
        .out_valid(out_valid),
        .in(in),
        .shift(shift),
        .fill(fill),
        .out(out)
    );

    function automatic [49:0] expected_out;
        input [49:0] in_i;
        input [2:0] shift_i;
        input [4:0] fill_i;
        integer idx;
        reg [49:0] temp;
        begin
            temp = 50'b0;
            for (idx = 0; idx < 10; idx = idx + 1) begin
                if ((idx + shift_i) < 10) begin
                    temp[idx*5 +: 5] = in_i[(idx+shift_i)*5 +: 5];
                end else begin
                    temp[idx*5 +: 5] = fill_i;
                end
            end
            expected_out = temp;
        end
    endfunction

    task automatic fail(input [8*160-1:0] msg);
        begin
            $display("FAIL: %0s", msg);
            $finish;
        end
    endtask

    task automatic check_case(input [49:0] in_i, input [2:0] shift_i, input [4:0] fill_i);
        reg [49:0] exp_i;
        begin
            in = in_i;
            shift = shift_i;
            fill = fill_i;
            #1;
            if (out_valid !== (shift_i <= 3'd4)) fail("out_valid mismatch");
            if (shift_i <= 3'd4) begin
                exp_i = expected_out(in_i, shift_i, fill_i);
                if (out !== exp_i) begin
                    $display("FAIL: shift_right mismatch shift=%0d expected=%013h got=%013h", shift_i, exp_i, out);
                    $finish;
                end
            end
        end
    endtask

    initial begin
        check_case({5'd10,5'd9,5'd8,5'd7,5'd6,5'd5,5'd4,5'd3,5'd2,5'd1}, 3'd0, 5'h1F);
        check_case({5'd10,5'd9,5'd8,5'd7,5'd6,5'd5,5'd4,5'd3,5'd2,5'd1}, 3'd1, 5'h00);
        check_case({5'd10,5'd9,5'd8,5'd7,5'd6,5'd5,5'd4,5'd3,5'd2,5'd1}, 3'd2, 5'h1B);
        check_case({5'd22,5'd23,5'd24,5'd25,5'd26,5'd27,5'd28,5'd29,5'd30,5'd31}, 3'd4, 5'h03);
        check_case({5'd22,5'd23,5'd24,5'd25,5'd26,5'd27,5'd28,5'd29,5'd30,5'd31}, 3'd5, 5'h03);
        check_case({5'd22,5'd23,5'd24,5'd25,5'd26,5'd27,5'd28,5'd29,5'd30,5'd31}, 3'd7, 5'h03);

        $display("TESTS PASSED");
        $finish;
    end

endmodule
