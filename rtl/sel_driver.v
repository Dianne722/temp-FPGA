module sel_driver(
    input               clk         ,
    input               rst_n       ,
    input       [23:0]  dis_data    ,   //计数器模块传递过了的值
    output reg  [5:0]   sel         ,   //片选
    output reg  [7:0]   dig             //段选
);

    parameter   ZER = 7'b100_0000,
                ONE = 7'b111_1001,
                TWO = 7'b010_0100,
                THR = 7'b011_0000,
                FOU = 7'b001_1001,
                FIV = 7'b001_0010,
                SIX = 7'b000_0010,
                SEV = 7'b111_1000,
                EIG = 7'b000_0000,
                NIN = 7'b001_0000,
                A   = 7'b000_1111,  //显示正号
                B   = 7'b011_1111;  //显示符号

    parameter   TIME_20US = 1000;   

    reg     [9:0]       cnt     ;
    wire                add_cnt ;
    wire                end_cnt ;

    reg                 dot     ;   //小数点
    reg     [3:0]       data    ;   //寄存时分秒

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt <= 0;
        end 
        else if(add_cnt)begin 
            if(end_cnt)begin 
                cnt <= 0;
            end
            else begin 
                cnt <= cnt + 1;
            end 
        end
        else begin 
            cnt <= cnt;
        end 
    end 
    assign add_cnt = 1'b1;
    assign end_cnt = add_cnt && cnt == TIME_20US - 1 ;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            sel <= 6'b011_111;
        end 
        else if(end_cnt)begin 
            sel <= {sel[0],sel[5:1]};
        end 
        else begin 
            sel <= sel;
        end 
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            dot <= 1'b1;
            data <= 4'hf;
        end
        else begin
            case(sel)
                6'b011_111 : begin data <= dis_data[3:0]    ; dot <= 1'b1; end 
                6'b101_111 : begin data <= dis_data[7:4]    ; dot <= 1'b1; end 
                6'b110_111 : begin data <= dis_data[11:8]   ; dot <= 1'b1; end 
                6'b111_011 : begin data <= dis_data[15:12]  ; dot <= 1'b0; end  
                6'b111_101 : begin data <= dis_data[19:16]  ; dot <= 1'b1; end 
                6'b111_110 : begin data <= dis_data[23:20]  ; dot <= 1'b1; end 
                default    : begin data <= 4'hf             ; dot <= 1'b1; end 
            endcase
        end
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            dig <= 8'hFF;
        end
        else begin
            case(data)
                4'd0   :   dig <= {dot,ZER} ;
                4'd1   :   dig <= {dot,ONE} ;
                4'd2   :   dig <= {dot,TWO} ;
                4'd3   :   dig <= {dot,THR} ;
                4'd4   :   dig <= {dot,FOU} ;
                4'd5   :   dig <= {dot,FIV} ;
                4'd6   :   dig <= {dot,SIX} ;
                4'd7   :   dig <= {dot,SEV} ;
                4'd8   :   dig <= {dot,EIG} ;
                4'd9   :   dig <= {dot,NIN} ;
                4'hA   :   dig <= {dot,A}   ;
                4'hB   :   dig <= {dot,B}   ;
                default : dig <= 8'hFF;
            endcase
        end
    end

endmodule