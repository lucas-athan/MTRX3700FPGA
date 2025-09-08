// ---------------------------------------------------------------------
// binary to 4-digit BCD (supports 0..9999) - returns {d3,d2,d1,d0}
// ---------------------------------------------------------------------
module bin2bcd_4digits (
    input  logic [13:0] bin,      // up to 9999
    output logic [15:0] bcd      // {d3,d2,d1,d0}
);
    function automatic logic [15:0] conv(input logic [13:0] v);
        integer i;
        logic [31:0] shift;
        begin
            shift = {18'b0, v};
            for (i = 0; i < 14; i = i + 1) begin
                if (shift[31:28] >= 5) shift[31:28] = shift[31:28] + 3;
                if (shift[27:24] >= 5) shift[27:24] = shift[27:24] + 3;
                if (shift[23:20] >= 5) shift[23:20] = shift[23:20] + 3;
                if (shift[19:16] >= 5) shift[19:16] = shift[19:16] + 3;
                shift = shift << 1;
            end
            conv = shift[31:16];
        end
    endfunction
    assign bcd = conv(bin);
endmodule