module top(
    input           clk     ,
    input           rst_n   ,
    inout           dq      ,
    input           key     ,
    output  reg     led2    ,
    input           rx      ,
    output          pwm     ,
    output  reg     led     ,
    output          tx      ,
    output  [5:0]   sel     ,
    output  [7:0]   dig 
);  

    wire                    key_out     ;
    wire    [15:0]          t_data      ;
    wire    [23:0]          dis_data    ;
    wire    [7:0]           t_data_uart ;//发送到PC端
    wire                    en          ;

    wire                    flag2;      //上位机发送信号
    assign flag2 = (rx == 0); // 当 rx 等于 1 时，flag2 为 1；当 rx 等于 0 时，flag2 为 0
    //assign led2 = flag2;

    parameter TIME_5S = 250_000_000 ;//5秒
    reg     [27:0]      cnt      ;//28位宽
    wire                add_cnt  ;
    wire                end_cnt  ;


    assign add_cnt = 1'b1;
    assign end_cnt = cnt == TIME_5S - 1;

    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt <= 28'b0;
        end
        else if(add_cnt)begin
            if(end_cnt)begin
                cnt <= 28'b0;
            end
            else begin
                cnt <= cnt + 1'b1;
            end
        end
        else begin
            cnt <= cnt;
        end
    end
    
    assign t_data_uart=end_cnt ? {1'b0,t_data[10:4]}:t_data_uart;//当1秒时 转换数据给uart 没到5秒时就等于本身
 
    reg [7:0] state; // 添加状态寄存器
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin 
            led <= 1'b0 ;
            state <= 8'h0; // 初始化状态寄存器
        end 
        else begin
            case(state)
                8'h0: begin // 初始状态
                    if(key_out)begin 
                        led <= 1'b1 ; // 按下按键，led亮
                        state <= 8'h1; // 进入下一个状态
                    end
                end
                8'h1: begin // 按键按下后的状态
                    if(key_out)begin 
                        led <= 1'b0 ; // 再次按下按键，led灭
                        state <= 8'h0; // 回到初始状态
                    end
                end
            endcase
        end 
    end 

    reg [7:0] state1; // 添加状态寄存器
    always @(posedge clk or negedge rst_n)begin 
        if(!rst_n)begin 
            led2 <= 1'b0 ;
            state1 <= 8'h0; // 初始化状态寄存器
        end 
        else begin
             case(state1)
                8'h0: begin // 初始状态
                if(flag2)begin 
                led2 <= 1'b1 ; // 接收指令，led亮
                state1 <= 8'h1; // 进入下一个状态
                end 
            end
               8'h1: begin // 按键按下后的状态
               if(flag2)begin 
                led2 <= 1'b0 ; // 再次接收指令，led灭
                state1 <= 8'h0; // 回到初始状态
                end
            end
            endcase
    end 
    end
    ds18b20_driver      inst_ds18b20_driver(
        .clk                (clk        ),
        .rst_n              (rst_n      ),
        .dq                 (dq         ),
        .t_data             (t_data     ) 
    );

    ctrl                inst_ctrl(
        .t_data             (t_data     ),
        .dis_data           (dis_data   ),
        .en                 (en         )
    );

    sel_driver          inst_sel_driver(
        .clk                (clk        ) ,
        .rst_n              (rst_n      ) ,
        .dis_data           (dis_data   ) ,
        .sel                (sel        ) ,
        .dig                (dig        )  
    );

    FSM_KEY1            inst_FSM_KEY1(
    .clk                    (clk        ),      
    .rst_n                  (rst_n      ),  
    .key_in                 (key        ),   
    .key_out                (key_out    )    
    );

    uart_tx             inst_uart_tx(
    .clk                    (clk        ),
    .rst_n                  (rst_n      ),
    .din                    (t_data_uart),//传的数据
    .din_vld                (end_cnt    ),//计时器作为判断条件
    .dout                   (tx         ) 
    );

    beep                inst_beep(
        .clk                (clk        ),
        .rst_n              (rst_n      ),
        .en                 (en         ),
        .pwm                (pwm        )
    );  

    uart_rx             inst_uart_rx(
        .clk                 (clk        ),
        .rst_n               (rst_n      ),
        .din                 (rx         )
    );
endmodule