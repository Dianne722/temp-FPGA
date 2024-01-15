module uart_tx(
    input               clk     ,
    input               rst_n   ,
    input   [7:0]       din     ,
    input               din_vld ,//发送条件
    output  reg         dout        
);
    //1.多久发一个数据 2.发送多少bit 3.flag计数器什么时候开始停止计数 4.data数据寄存加上起始位 5.串行发送出去

    parameter   BAUD = 434;

    reg     [8:0]       cnt_bsp     ;
    wire                add_cnt_bsp ;
    wire                end_cnt_bsp ;

    reg     [3:0]       cnt_bit     ;
    wire                add_cnt_bit ;
    wire                end_cnt_bit ;

    reg                 flag        ;
    reg     [8:0]       data        ;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt_bsp <= 0;
        end 
        else if(add_cnt_bsp)begin 
            if(end_cnt_bsp)begin 
                cnt_bsp <= 0;
            end
            else begin 
                cnt_bsp <= cnt_bsp + 1;
            end 
        end
        else begin 
            cnt_bsp <= cnt_bsp;
        end 
    end 
    assign add_cnt_bsp = flag;
    assign end_cnt_bsp = add_cnt_bsp && cnt_bsp == BAUD - 1;

    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin
            cnt_bit <= 0;
        end 
        else if(add_cnt_bit)begin 
            if(end_cnt_bit)begin 
                cnt_bit <= 0;
            end
            else begin 
                cnt_bit <= cnt_bit + 1;
            end 
        end
        else begin 
            cnt_bit <= cnt_bit;
        end 
    end 
    assign add_cnt_bit = end_cnt_bsp;
    assign end_cnt_bit = add_cnt_bit && cnt_bit == 8 ;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            flag <= 1'b0;
        end
        else if(din_vld)begin
            flag <= 1'b1;
        end
        else if(end_cnt_bit)begin
            flag <= 1'b0;
        end
        else begin
            flag <= flag;
        end
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            data <= 9'h1ff;
        end
        else if(din_vld)begin
            data <= {din,1'b0};  //数据加上起始位
        end
        else begin
            data <= data;
        end
    end

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            dout <= 1'b1;
        end
        else if(cnt_bsp == 1)begin
            dout <= data[cnt_bit];  //并串转换 LSB
        end
        else if(end_cnt_bit)begin
            dout <= 1'b1;
        end
        else begin
            dout <= dout;
        end
    end


endmodule