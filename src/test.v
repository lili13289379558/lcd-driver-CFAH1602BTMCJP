module LCD_Example(
  input CLOCK_50,     //    50 MHz clock
  input [3:0] KEY,      //    Pushbutton[3:0]
  input [17:0] SW,     //    Toggle Switch[17:0]
  output [6:0]    HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7,  // Seven Segment Digits
  output [8:0] LEDG,   //    LED Green
  output [17:0] LEDR,   //    LED Red
  inout [35:0] GPIO_0,GPIO_1,    //    GPIO Connections
 //    LCD Module 16X2
  output LCD_ON,     // LCD Power ON/OFF
  output LCD_BLON,     // LCD Back Light ON/OFF
  output LCD_RW,     // LCD Read/Write Select, 0 = Write, 1 = Read
  output LCD_EN,     // LCD Enable
  output LCD_RS,     // LCD Command/Data Select, 0 = Command, 1 = Data
  inout [7:0] LCD_DATA, // LCD Data bus 8 bits
  input  UART_RXD,  //RS232 RXD
  output UART_TXD  //RS232 TXD
);

//    All inout port turn to tri-state
assign    GPIO_0        =    36'hzzzzzzzzz;
assign    GPIO_1        =    36'hzzzzzzzzz;

wire  clk_25Mout ,clk_2sec;

assign HEX0=7'b111_1111;  //off 7-segment Display
assign HEX1=7'b111_1111;
assign HEX2=7'b111_1111;
assign HEX3=7'b111_1111;
assign HEX4=7'b111_1111;
assign HEX5=7'b111_1111;
assign HEX6=7'b111_1111;
assign HEX7=7'b111_1111;

// Send switches to red leds 
assign LEDR = SW;

// turn LCD ON
assign    LCD_ON      =    1'b1;
assign    LCD_BLON    =    1'b1;

wire LCD_EN1,LCD_EN2,LCD_RS1,LCD_RS2,LCD_RW1,LCD_RW2;
wire [7:0] LCD_DATA1,LCD_DATA2;

//module clk_div_1hz(clk_in , Reset, clk_25Mout);
clk_div_25MHz u0 (CLOCK_50 , KEY[0], clk_25Mout);

clk_div_2sec(CLOCK_50 ,KEY[0], clk_2sec);


//lcd_1602_1(sysclk,Enable, rst_n, lcd_en, lcd_rs, lcd_rw, lcd_data ); 
lcd1_1602 u1 (clk_25Mout,
    KEY[0], 
    LCD_EN1, 
    LCD_RS1, 
    LCD_RW1,
    LCD_DATA1
    ); 

lcd2_1602 u2 (clk_25Mout,
    KEY[0], 
    LCD_EN2, 
    LCD_RS2, 
    LCD_RW2,
    LCD_DATA2
    ); 

mux_2x1 u3 ( LCD_EN1,
    LCD_EN2,
    LCD_RS1,
    LCD_RS2,
    LCD_RW1,
    LCD_RW2,
    LCD_DATA1,
    LCD_DATA2,
    clk_2sec,   //Toggle LCD Text 
    LCD_EN,
    LCD_RS,
    LCD_RW,
    LCD_DATA
             );
             


endmodule

module  mux_2x1(
  input LCD_EN1,
  input LCD_EN2,
  input LCD_RS1,
  input LCD_RS2,
  input LCD_RW1,
  input LCD_RW2,
  input [7:0] LCD_DATA1,
  input [7:0] LCD_DATA2,
  input sel,
  output reg  LCD_EN,
  output reg  LCD_RS,
  output reg  LCD_RW,
  output reg  [7:0] LCD_DATA
  );
  
  
  always @ (sel,LCD_EN1,LCD_EN2,LCD_RS1,LCD_RS2,LCD_RW1,LCD_RW2,LCD_DATA1,LCD_DATA2)
  begin 
     if (sel == 1'b0) 
         begin
         LCD_EN=LCD_EN1;
         LCD_RS=LCD_RS1;
         LCD_RW=LCD_RW1;
         LCD_DATA=LCD_DATA1;
         end 
     else 
         begin
         LCD_EN=LCD_EN2;
         LCD_RS=LCD_RS2;
         LCD_RW=LCD_RW2;
         LCD_DATA=LCD_DATA2;
         end
  end

 endmodule



module lcd1_1602(sysclk, rst_n, lcd_en, lcd_rs, lcd_rw, lcd_data ); 
 input sysclk; //系統時鐘 50MHZ 
 input rst_n; //復位信號，低電平有效；  

 output lcd_en; //讀寫使能信號，高電平有效； 
 output reg lcd_rs; //數據命令選擇端(H/L)； 
 output lcd_rw; //讀寫選擇端(H/L); 
 output reg [7:0] lcd_data; //8位數據口；  


 parameter [127:0]row2="  hello world!  "; 
 //因為lcd1602每一行可顯示16個字符，一個字符占8位； 
 parameter [127:0]row1="  I like FPGA!  "; 
 //所以每一行一共有16*8=128位；  

 reg [15:0] time_cnt; 

 always @(posedge sysclk or negedge rst_n) 
  begin 
  if(!rst_n) 
     time_cnt<=16'h0; 
  else 
     time_cnt<=time_cnt+16'b1;  
  end 
  
  assign lcd_rw=1'b0; 
  assign lcd_en=time_cnt[15]; 
  wire state_flag ; 
  //狀態標誌位 ,因為FPGA的運算速度比LCD1602要快的多， 
  //所以必須要等到LCD1602穩定後才往裏面寫數據； 
  
  assign state_flag=(time_cnt==16'h7fff)?1'b1:1'b0 ; 
  //lcd_en最小值500ns ,所以lcd_en的頻率應維持在2MHZ以內；   
  
  parameter IDLE=8'h00; //lcd1602 initial; 
  parameter INI_SET=8'h01; //顯示工作模式設置；  
  parameter INI_CLR=8'h02; //清屏顯示；  
  parameter CURSOR_SET1=8'h03; // 光標設置1；  
  parameter CURSOR_SET2=8'h04; //光標設置2；  
  
  //display line 1; 
  parameter LINE1_ADDER=8'h05;  
  
  parameter LINE1_0=8'h06;  
  parameter LINE1_1=8'h07;  
  parameter LINE1_2=8'h08;  
  parameter LINE1_3=8'h09;  
  parameter LINE1_4=8'h0A;  
  parameter LINE1_5=8'h0B;  
  parameter LINE1_6=8'h0C;  
  parameter LINE1_7=8'h0D;  
  parameter LINE1_8=8'h0E;  
  parameter LINE1_9=8'h0F;  
  parameter LINE1_A=8'h10;  
  parameter LINE1_B=8'h11;  
  parameter LINE1_C=8'h12;  
  parameter LINE1_D=8'h13;  
  parameter LINE1_E=8'h14;  
  parameter LINE1_F=8'h15; 
  
  // display line 2; 
  parameter LINE2_ADDER=8'h16;  
  
  parameter LINE2_0=8'h17;  
  parameter LINE2_1=8'h18;  
  parameter LINE2_2=8'h19;  
  parameter LINE2_3=8'h1A;  
  parameter LINE2_4=8'h1B;  
  parameter LINE2_5=8'h1C;  
  parameter LINE2_6=8'h1D;  
  parameter LINE2_7=8'h1E;  
  parameter LINE2_8=8'h1F;  
  parameter LINE2_9=8'h20;  
  parameter LINE2_A=8'h21;  
  parameter LINE2_B=8'h22;  
  parameter LINE2_C=8'h23;  
  parameter LINE2_D=8'h24;  
  parameter LINE2_E=8'h25;  
  parameter LINE2_F=8'h26; 
  
  //------------------------------------------------// 
  reg[7:0] state; 
  reg[7:0] next_state; 
      
 always @ (posedge sysclk or negedge rst_n) 
 begin 
    if(!rst_n ) 
  state<=IDLE; 
    else if(state_flag) 
  state<=next_state; 
   end 

  always @ (*) 
  begin 
    case(state) //display line1; 
    IDLE   : next_state=INI_SET; 
    INI_SET  : next_state=INI_CLR; 
    INI_CLR  : next_state=CURSOR_SET1; 
    CURSOR_SET1 : next_state=CURSOR_SET2; 
    CURSOR_SET2 : next_state=LINE1_ADDER; 
    
    LINE1_ADDER : next_state=LINE1_0; 
    
    LINE1_0  : next_state=LINE1_1; 
    LINE1_1  : next_state=LINE1_2; 
    LINE1_2  : next_state=LINE1_3; 
    LINE1_3  : next_state=LINE1_4; 
    LINE1_4  : next_state=LINE1_5; 
    LINE1_5  : next_state=LINE1_6; 
    LINE1_6  : next_state=LINE1_7; 
    LINE1_7  : next_state=LINE1_8; 
    LINE1_8  : next_state=LINE1_9; 
    LINE1_9  : next_state=LINE1_A; 
    LINE1_A  : next_state=LINE1_B; 
    LINE1_B  : next_state=LINE1_C; 
    LINE1_C  : next_state=LINE1_D; 
    LINE1_D  : next_state=LINE1_E; 
    LINE1_E  : next_state=LINE1_F; 
    LINE1_F  : next_state=LINE2_ADDER; 
    
    //display line2; 
    LINE2_ADDER : next_state=LINE2_0; 
    
    LINE2_0  : next_state=LINE2_1; 
    LINE2_1  : next_state=LINE2_2; 
    LINE2_2  : next_state=LINE2_3; 
    LINE2_3  : next_state=LINE2_4; 
    LINE2_4  : next_state=LINE2_5; 
    LINE2_5  : next_state=LINE2_6; 
    LINE2_6  : next_state=LINE2_7; 
    LINE2_7  : next_state=LINE2_8; 
    LINE2_8  : next_state=LINE2_9; 
    LINE2_9  : next_state=LINE2_A; 
    LINE2_A  : next_state=LINE2_B; 
    LINE2_B  : next_state=LINE2_C; 
    LINE2_C  : next_state=LINE2_D; 
    LINE2_D  : next_state=LINE2_E; 
    LINE2_E  : next_state=LINE2_F; 
    LINE2_F  : next_state=LINE1_ADDER;
     
    default : next_state=IDLE; 
   endcase 
  end 

 always @ (posedge sysclk or negedge rst_n) 
 begin 
  if(!rst_n) 
 begin 
  lcd_rs   <= 1'b0; 
  lcd_data <= 8'hxx; 
 end 
  else if(state_flag)
    begin 
    case (next_state) 
     IDLE  :  begin
                   lcd_rs <= 1'h0;
                   lcd_data <=8'hxx;  
                   end
                     
     INI_SET :  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h38;
     end  
     INI_CLR :  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h01;
     end 
     CURSOR_SET1:  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h06;
     end  
     CURSOR_SET2:  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h0c;
     end 
     // line1 
     LINE1_ADDER:  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h80;
     end   
     LINE1_0  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[127:120]; 
     end  
     LINE1_1  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[119:112];  
     end 
     LINE1_2  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[111:104];
     end   
     LINE1_3  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[103:96];
     end  
     LINE1_4  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[95:88]; 
     end  
     LINE1_5  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[87:80];
     end  
     LINE1_6  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[79:72];
     end   
     LINE1_7  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row1[71:64]; 
     end  
     LINE1_8  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row1[63:56]; 
     end  
     LINE1_9  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[55:48];
     end  
     LINE1_A  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[47:40]; 
     end   
     LINE1_B  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row1[39:32]; 
     end  
     LINE1_C  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[31:24]; 
     end  
     LINE1_D  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[23:16]; 
     end  
     LINE1_E  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[15:8]; 
     end   
     LINE1_F  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[7:0];  
     end
     // line2  
     LINE2_ADDER:  begin
     lcd_rs <=1'h0;
     lcd_data <=8'hC0; 
     end 
 
  LINE2_0  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[127:120]; 
     end  
     LINE2_1  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[119:112];  
     end 
     LINE2_2  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[111:104];
     end   
     LINE2_3  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[103:96];
     end  
     LINE2_4  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[95:88]; 
     end  
     LINE2_5  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[87:80];
     end  
     LINE2_6  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[79:72];
     end   
     LINE2_7  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row2[71:64]; 
     end  
     LINE2_8  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row2[63:56]; 
     end  
     LINE2_9  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[55:48];
     end  
     LINE2_A  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[47:40]; 
     end   
     LINE2_B  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row2[39:32]; 
     end  
     LINE2_C  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[31:24]; 
     end  
     LINE2_D  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[23:16]; 
     end  
     LINE2_E  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[15:8]; 
     end   
     LINE2_F  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[7:0];  
     end
     
      
  endcase 
    
  /* case(next_state) 
     IDLE   : lcd_data <=8'hxx;  
     INI_SET  : lcd_data <=8'h38; 
     //設置16*2顯示，5*7點陣，8位數據接口；  
     INI_CLR  : lcd_data <=8'h01; //清屏顯示；  
     CURSOR_SET1: lcd_data <=8'h06; 
     //寫一個字符後地址指針加一；   
     CURSOR_SET2: lcd_data <=8'h0c; 
     //設置開顯示，不顯示光標； 
     //line1  
     LINE1_ADDER: lcd_data <=8'h80; 
     //LCD1602第一行 首地址；   
     LINE1_0  : lcd_data <=row1[127:120]; 
     LINE1_1  : lcd_data <=row1[119:112]; 
     LINE1_2  : lcd_data <=row1[111:104]; 
     LINE1_3  : lcd_data <=row1[103:96]; 
     LINE1_4  : lcd_data <=row1[95:88]; 
     LINE1_5  : lcd_data <=row1[87:80]; 
     LINE1_6  : lcd_data <=row1[79:72]; 
     LINE1_7  : lcd_data <=row1[71:64]; 
     LINE1_8  : lcd_data <=row1[63:56]; 
     LINE1_9  : lcd_data <=row1[55:48]; 
     LINE1_A  : lcd_data <=row1[47:40]; 
     LINE1_B  : lcd_data <=row1[39:32]; 
     LINE1_C  : lcd_data <=row1[31:24]; 
     LINE1_D  : lcd_data <=row1[23:16]; 
     LINE1_E  : lcd_data <=row1[15:8]; 
     LINE1_F  : lcd_data <=row1[7:0]; 
     
     //line2 
     LINE2_ADDER: lcd_data <=8'hC0; 
     //LCD1602第二行首地址(8'h80+8'h40=8'hC0) 
     LINE2_0  : lcd_data <=row2[127:120]; 
     LINE2_1  : lcd_data <=row2[119:112]; 
     LINE2_2  : lcd_data <=row2[111:104]; 
     LINE2_3  : lcd_data <=row2[103:96]; 
     LINE2_4  : lcd_data <=row2[95:88]; 
     LINE2_5  : lcd_data <=row2[87:80]; 
     LINE2_6  : lcd_data <=row2[79:72]; 
     LINE2_7  : lcd_data <=row2[71:64]; 
     LINE2_8  : lcd_data <=row2[63:56]; 
     LINE2_9  : lcd_data <=row2[55:48]; 
     LINE2_A  : lcd_data <=row2[47:40]; 
     LINE2_B  : lcd_data <=row2[39:32]; 
     LINE2_C  : lcd_data <=row2[31:24]; 
     LINE2_D  : lcd_data <=row2[23:16]; 
     LINE2_E  : lcd_data <=row2[15:8]; 
     LINE2_F  : lcd_data <=row2[7:0]; 
    endcase */ 
   end 
  
  end 
  
endmodule     



//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++

module lcd2_1602(sysclk, rst_n, lcd_en, lcd_rs, lcd_rw, lcd_data ); 
 input sysclk; //系統時鐘 50MHZ 
 input rst_n; //復位信號，低電平有效；  


 output lcd_en; //讀寫使能信號，高電平有效； 
 output reg lcd_rs; //數據命令選擇端(H/L)； 
 output lcd_rw; //讀寫選擇端(H/L); 
 output reg [7:0] lcd_data; //8位數據口；  


 parameter [127:0]row1="    hello world!"; 
 //因為lcd1602每一行可顯示16個字符，一個字符占8位； 
 parameter [127:0]row2="    I like FPGA!"; 
 //所以每一行一共有16*8=128位；  

 reg [15:0] time_cnt; 

 always @(posedge sysclk or negedge rst_n) 
  begin 
  if(!rst_n) 
     time_cnt<=16'h0; 
  else 
     time_cnt<=time_cnt+16'b1;  
  end 
  
  assign lcd_rw=1'b0; 
  assign lcd_en=time_cnt[15]; 
  wire state_flag ; 
  //狀態標誌位 ,因為FPGA的運算速度比LCD1602要快的多， 
  //所以必須要等到LCD1602穩定後才往裏面寫數據； 
  
  assign state_flag=(time_cnt==16'h7fff)?1'b1:1'b0 ; 
  //lcd_en最小值500ns ,所以lcd_en的頻率應維持在2MHZ以內；   
  
  parameter IDLE=8'h00; //lcd1602 initial; 
  parameter INI_SET=8'h01; //顯示工作模式設置；  
  parameter INI_CLR=8'h02; //清屏顯示；  
  parameter CURSOR_SET1=8'h03; // 光標設置1；  
  parameter CURSOR_SET2=8'h04; //光標設置2；  
  
  //display line 1; 
  parameter LINE1_ADDER=8'h05;  
  
  parameter LINE1_0=8'h06;  
  parameter LINE1_1=8'h07;  
  parameter LINE1_2=8'h08;  
  parameter LINE1_3=8'h09;  
  parameter LINE1_4=8'h0A;  
  parameter LINE1_5=8'h0B;  
  parameter LINE1_6=8'h0C;  
  parameter LINE1_7=8'h0D;  
  parameter LINE1_8=8'h0E;  
  parameter LINE1_9=8'h0F;  
  parameter LINE1_A=8'h10;  
  parameter LINE1_B=8'h11;  
  parameter LINE1_C=8'h12;  
  parameter LINE1_D=8'h13;  
  parameter LINE1_E=8'h14;  
  parameter LINE1_F=8'h15; 
  
  // display line 2; 
  parameter LINE2_ADDER=8'h16;  
  
  parameter LINE2_0=8'h17;  
  parameter LINE2_1=8'h18;  
  parameter LINE2_2=8'h19;  
  parameter LINE2_3=8'h1A;  
  parameter LINE2_4=8'h1B;  
  parameter LINE2_5=8'h1C;  
  parameter LINE2_6=8'h1D;  
  parameter LINE2_7=8'h1E;  
  parameter LINE2_8=8'h1F;  
  parameter LINE2_9=8'h20;  
  parameter LINE2_A=8'h21;  
  parameter LINE2_B=8'h22;  
  parameter LINE2_C=8'h23;  
  parameter LINE2_D=8'h24;  
  parameter LINE2_E=8'h25;  
  parameter LINE2_F=8'h26; 
  
  //------------------------------------------------// 
  reg[7:0] state; 
  reg[7:0] next_state; 
      
 always @ (posedge sysclk or negedge rst_n) 
 begin 
    if(!rst_n ) 
  state<=IDLE; 
 else if(state_flag) 
  state<=next_state; 
 end

  always @ (*) 
  begin 
    case(state) //display line1; 
    IDLE   : next_state=INI_SET; 
    INI_SET  : next_state=INI_CLR; 
    INI_CLR  : next_state=CURSOR_SET1; 
    CURSOR_SET1 : next_state=CURSOR_SET2; 
    CURSOR_SET2 : next_state=LINE1_ADDER; 
    
    LINE1_ADDER : next_state=LINE1_0; 
    
    LINE1_0  : next_state=LINE1_1; 
    LINE1_1  : next_state=LINE1_2; 
    LINE1_2  : next_state=LINE1_3; 
    LINE1_3  : next_state=LINE1_4; 
    LINE1_4  : next_state=LINE1_5; 
    LINE1_5  : next_state=LINE1_6; 
    LINE1_6  : next_state=LINE1_7; 
    LINE1_7  : next_state=LINE1_8; 
    LINE1_8  : next_state=LINE1_9; 
    LINE1_9  : next_state=LINE1_A; 
    LINE1_A  : next_state=LINE1_B; 
    LINE1_B  : next_state=LINE1_C; 
    LINE1_C  : next_state=LINE1_D; 
    LINE1_D  : next_state=LINE1_E; 
    LINE1_E  : next_state=LINE1_F; 
    LINE1_F  : next_state=LINE2_ADDER; 
    
    //display line2; 
    LINE2_ADDER : next_state=LINE2_0; 
    
    LINE2_0  : next_state=LINE2_1; 
    LINE2_1  : next_state=LINE2_2; 
    LINE2_2  : next_state=LINE2_3; 
    LINE2_3  : next_state=LINE2_4; 
    LINE2_4  : next_state=LINE2_5; 
    LINE2_5  : next_state=LINE2_6; 
    LINE2_6  : next_state=LINE2_7; 
    LINE2_7  : next_state=LINE2_8; 
    LINE2_8  : next_state=LINE2_9; 
    LINE2_9  : next_state=LINE2_A; 
    LINE2_A  : next_state=LINE2_B; 
    LINE2_B  : next_state=LINE2_C; 
    LINE2_C  : next_state=LINE2_D; 
    LINE2_D  : next_state=LINE2_E; 
    LINE2_E  : next_state=LINE2_F; 
    LINE2_F  : next_state=LINE1_ADDER;
     
    default : next_state=IDLE; 
   endcase 
  end 

 always @ (posedge sysclk or negedge rst_n) 
 begin 
  if(!rst_n) 
 begin 
  lcd_rs   <= 1'b0; 
  lcd_data <= 8'hxx; 
 end 
  else if(state_flag)
    begin 
    case (next_state) 
     IDLE  :  begin
                   lcd_rs <= 1'h0;
                   lcd_data <=8'hxx;  
                   end
                     
     INI_SET :  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h38;
     end  
     INI_CLR :  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h01;
     end 
     CURSOR_SET1:  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h06;
     end  
     CURSOR_SET2:  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h0c;
     end 
     // line1 
     LINE1_ADDER:  begin
     lcd_rs <= 1'h0;
     lcd_data <=8'h80;
     end   
     LINE1_0  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[127:120]; 
     end  
     LINE1_1  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[119:112];  
     end 
     LINE1_2  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[111:104];
     end   
     LINE1_3  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[103:96];
     end  
     LINE1_4  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[95:88]; 
     end  
     LINE1_5  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[87:80];
     end  
     LINE1_6  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[79:72];
     end   
     LINE1_7  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row1[71:64]; 
     end  
     LINE1_8  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row1[63:56]; 
     end  
     LINE1_9  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[55:48];
     end  
     LINE1_A  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[47:40]; 
     end   
     LINE1_B  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row1[39:32]; 
     end  
     LINE1_C  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[31:24]; 
     end  
     LINE1_D  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[23:16]; 
     end  
     LINE1_E  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[15:8]; 
     end   
     LINE1_F  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row1[7:0];  
     end
     // line2  
     LINE2_ADDER:  begin
     lcd_rs <=1'h0;
     lcd_data <=8'hC0; 
     end 
 
  LINE2_0  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[127:120]; 
     end  
     LINE2_1  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[119:112];  
     end 
     LINE2_2  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[111:104];
     end   
     LINE2_3  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[103:96];
     end  
     LINE2_4  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[95:88]; 
     end  
     LINE2_5  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[87:80];
     end  
     LINE2_6  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[79:72];
     end   
     LINE2_7  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row2[71:64]; 
     end  
     LINE2_8  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row2[63:56]; 
     end  
     LINE2_9  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[55:48];
     end  
     LINE2_A  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[47:40]; 
     end   
     LINE2_B  :  begin 
     lcd_rs <= 1'h1;
     lcd_data <=row2[39:32]; 
     end  
     LINE2_C  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[31:24]; 
     end  
     LINE2_D  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[23:16]; 
     end  
     LINE2_E  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[15:8]; 
     end   
     LINE2_F  :  begin
     lcd_rs <= 1'h1;
     lcd_data <=row2[7:0];  
     end
  endcase 

  end 
  
 end 
  
endmodule     




module clk_div_25MHz(clk_in , Reset, clk_25Mout);
input clk_in ;
input Reset;
output reg   clk_25Mout;

integer i;
always@(posedge clk_in or negedge Reset) begin
 if (!Reset) begin
    i=0;
    clk_25Mout=0;
   end
 else begin
    i= i+1 ;
    if (i>=2) begin
         clk_25Mout  = ~ clk_25Mout;
        i=0;
       end
    end    
end            
endmodule

//+++++++++++++++++++++++++++++++++++++++++
module clk_div_2sec(clk_in , Reset, clk_out);
input clk_in ;
input Reset;
output reg  clk_out;

integer i;
always@(posedge clk_in or negedge Reset) begin
 if (!Reset) begin
   i=0;
   clk_out=0;
   end
 else begin
    i= i+1 ;
    if (i>=50_000_000) begin
        clk_out  = ~clk_out;
        i=0;
       end
    end    
end            

endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
example 2

lcdlab3.v


module lcdlab3(
  input CLOCK_50,    //    50 MHz clock
  input [3:0] KEY,      //    Pushbutton[3:0]
  input [17:0] SW,    //    Toggle Switch[17:0]
  output [6:0]    HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7,  // Seven Segment Digits
  output [8:0] LEDG,  //    LED Green
  output [17:0] LEDR,  //    LED Red
  inout [35:0] GPIO_0,GPIO_1,    //    GPIO Connections
//    LCD Module 16X2
  output LCD_ON,    // LCD Power ON/OFF
  output LCD_BLON,    // LCD Back Light ON/OFF
  output LCD_RW,    // LCD Read/Write Select, 0 = Write, 1 = Read
  output LCD_EN,    // LCD Enable
  output LCD_RS,    // LCD Command/Data Select, 0 = Command, 1 = Data
  inout [7:0] LCD_DATA    // LCD Data bus 8 bits
);

//    All inout port turn to tri-state
assign    GPIO_0        =    36'hzzzzzzzzz;
assign    GPIO_1        =    36'hzzzzzzzzz;

wire [6:0] myclock;
wire RST;
assign RST = KEY[0];

// reset delay gives some time for peripherals to initialize
wire DLY_RST;
Reset_Delay r0(    .iCLK(CLOCK_50),.oRESET(DLY_RST) );

// Send switches to red leds 
assign LEDR = SW;

// turn LCD ON
assign    LCD_ON        =    1'b1;
assign    LCD_BLON    =    1'b1;
///保存SW前8位数
wire [3:0] hex1, hex0;
assign hex1 = SW[7:4];
assign hex0 = SW[3:0];


LCD_Display u1(
// Host Side
   .iCLK_50MHZ(CLOCK_50),
   .iRST_N(DLY_RST),
   .hex0(hex0),
   .hex1(hex1),
// LCD Side
   .DATA_BUS(LCD_DATA),
   .LCD_RW(LCD_RW),
   .LCD_E(LCD_EN),
   .LCD_RS(LCD_RS)
);


// blank unused 7-segment digits
assign HEX0 = 7'b111_1111;
assign HEX1 = 7'b111_1111;
assign HEX2 = 7'b111_1111;
assign HEX3 = 7'b111_1111;
assign HEX4 = 7'b111_1111;
assign HEX5 = 7'b111_1111;
assign HEX6 = 7'b111_1111;
assign HEX7 = 7'b111_1111;

endmodule
LCD_Display.v


/*
 SW8 (GLOBAL RESET) resets LCD
ENTITY LCD_Display IS
-- Enter number of live Hex hardware data values to display
-- (do not count ASCII character constants)
    GENERIC(Num_Hex_Digits: Integer:= 2); 
-----------------------------------------------------------------------
-- LCD Displays 16 Characters on 2 lines
-- LCD_display string is an ASCII character string entered in hex for 
-- the two lines of the  LCD Display   (See ASCII to hex table below)
-- Edit LCD_Display_String entries above to modify display
-- Enter the ASCII character's 2 hex digit equivalent value
-- (see table below for ASCII hex values)
-- To display character assign ASCII value to LCD_display_string(x)
-- To skip a character use 8'h20" (ASCII space)
-- To dislay "live" hex values from hardware on LCD use the following: 
--   make array element for that character location 8'h0" & 4-bit field from Hex_Display_Data
--   state machine sees 8'h0" in high 4-bits & grabs the next lower 4-bits from Hex_Display_Data input
--   and performs 4-bit binary to ASCII conversion needed to print a hex digit
--   Num_Hex_Digits must be set to the count of hex data characters (ie. "00"s) in the display
--   Connect hardware bits to display to Hex_Display_Data input
-- To display less than 32 characters, terminate string with an entry of 8'hFE"
--  (fewer characters may slightly increase the LCD's data update rate)
------------------------------------------------------------------- 
--                        ASCII HEX TABLE
--  Hex                        Low Hex Digit
-- Value  0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
------\----------------------------------------------------------------
--H  2 |  SP  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /
--i  3 |  0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?
--g  4 |  @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O
--h  5 |  P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _
--   6 |  `   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o
--   7 |  p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~ DEL
-----------------------------------------------------------------------
-- Example "A" is row 4 column 1, so hex value is 8'h41"
-- *see LCD Controller's Datasheet for other graphics characters available
*/
        
module LCD_Display(iCLK_50MHZ, iRST_N, hex1, hex0, 
    LCD_RS,LCD_E,LCD_RW,DATA_BUS);
    
input iCLK_50MHZ, iRST_N;
input [3:0] hex1, hex0;
output LCD_RS, LCD_E, LCD_RW;
inout [7:0] DATA_BUS;

parameter
HOLD = 4'h0,
FUNC_SET = 4'h1,
DISPLAY_ON = 4'h2,
MODE_SET = 4'h3,
Print_String = 4'h4,
LINE2 = 4'h5,
RETURN_HOME = 4'h6,
DROP_LCD_E = 4'h7,
RESET1 = 4'h8,
RESET2 = 4'h9,
RESET3 = 4'ha,
DISPLAY_OFF = 4'hb,
DISPLAY_CLEAR = 4'hc;

reg [3:0] state, next_command;
// Enter new ASCII hex data above for LCD Display
reg [7:0] DATA_BUS_VALUE;
wire [7:0] Next_Char;
reg [19:0] CLK_COUNT_400HZ;
reg [4:0] CHAR_COUNT;
reg CLK_400HZ, LCD_RW_INT, LCD_E, LCD_RS;

// BIDIRECTIONAL TRI STATE LCD DATA BUS
assign DATA_BUS = (LCD_RW_INT? 8'bZZZZZZZZ: DATA_BUS_VALUE);

LCD_display_string u1(
.index(CHAR_COUNT),
.out(Next_Char),
.hex1(hex1),
.hex0(hex0));

assign LCD_RW = LCD_RW_INT;

always @(posedge iCLK_50MHZ or negedge iRST_N)
    if (!iRST_N)
    begin
       CLK_COUNT_400HZ <= 20'h00000;
       CLK_400HZ <= 1'b0;
    end
	///
    else if (CLK_COUNT_400HZ < 20'h0F424)
    begin
       CLK_COUNT_400HZ <= CLK_COUNT_400HZ + 1'b1;
    end
    else
    begin
      CLK_COUNT_400HZ <= 20'h00000;
      CLK_400HZ <= ~CLK_400HZ;
    end
// State Machine to send commands and data to LCD DISPLAY

always @(posedge CLK_400HZ or negedge iRST_N)
    if (!iRST_N)
    begin
     state <= RESET1;
    end
    else
    case (state)
    RESET1:            
// Set Function to 8-bit transfer and 2 line display with 5x8 Font size
// see Hitachi HD44780 family data sheet for LCD command and timing details
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h38;
      state <= DROP_LCD_E;
      next_command <= RESET2;
      CHAR_COUNT <= 5'b00000;
    end
    RESET2:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h38;
      state <= DROP_LCD_E;
      next_command <= RESET3;
    end
    RESET3:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h38;
      state <= DROP_LCD_E;
      next_command <= FUNC_SET;
    end
// EXTRA STATES ABOVE ARE NEEDED FOR RELIABLE PUSHBUTTON RESET OF LCD

    FUNC_SET:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h38;
      state <= DROP_LCD_E;
      next_command <= DISPLAY_OFF;
    end

// Turn off Display and Turn off cursor
    DISPLAY_OFF:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h08;
      state <= DROP_LCD_E;
      next_command <= DISPLAY_CLEAR;
    end

// Clear Display and Turn off cursor
    DISPLAY_CLEAR:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h01;
      state <= DROP_LCD_E;
      next_command <= DISPLAY_ON;
    end

// Turn on Display and Turn off cursor
    DISPLAY_ON:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h0C;
      state <= DROP_LCD_E;
      next_command <= MODE_SET;
    end

// Set write mode to auto increment address and move cursor to the right
    MODE_SET:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h06;
      state <= DROP_LCD_E;
      next_command <= Print_String;
    end

// Write ASCII hex character in first LCD character location
    Print_String:
    begin
      state <= DROP_LCD_E;
      LCD_E <= 1'b1;
      LCD_RS <= 1'b1;
      LCD_RW_INT <= 1'b0;
    // ASCII character to output
      if (Next_Char[7:4] != 4'h0)
        DATA_BUS_VALUE <= Next_Char;
        // Convert 4-bit value to an ASCII hex digit
      else if (Next_Char[3:0] >9)
        // ASCII A...F
         DATA_BUS_VALUE <= {4'h4,Next_Char[3:0]-4'h9};
      else
        // ASCII 0...9
         DATA_BUS_VALUE <= {4'h3,Next_Char[3:0]};
    // Loop to send out 32 characters to LCD Display  (16 by 2 lines)
      if ((CHAR_COUNT < 31) && (Next_Char != 8'hFE))
         CHAR_COUNT <= CHAR_COUNT + 1'b1;
      else
         CHAR_COUNT <= 5'b00000; 
    // Jump to second line?
      if (CHAR_COUNT == 15)
        next_command <= LINE2;
    // Return to first line?
      else if ((CHAR_COUNT == 31) || (Next_Char == 8'hFE))
        next_command <= RETURN_HOME;
      else
        next_command <= Print_String;
    end

// Set write address to line 2 character 1
    LINE2:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'hC0;
      state <= DROP_LCD_E;
      next_command <= Print_String;
    end

// Return write address to first character postion on line 1
    RETURN_HOME:
    begin
      LCD_E <= 1'b1;
      LCD_RS <= 1'b0;
      LCD_RW_INT <= 1'b0;
      DATA_BUS_VALUE <= 8'h80;
      state <= DROP_LCD_E;
      next_command <= Print_String;
    end

// The next three states occur at the end of each command or data transfer to the LCD
// Drop LCD E line - falling edge loads inst/data to LCD controller
    DROP_LCD_E:
    begin
      LCD_E <= 1'b0;
      state <= HOLD;
    end
// Hold LCD inst/data valid after falling edge of E line                
    HOLD:
    begin
      state <= next_command;
    end
    endcase
endmodule

module LCD_display_string(index,out,hex0,hex1);
input [4:0] index;
input [3:0] hex0,hex1;
output [7:0] out;
reg [7:0] out;
// ASCII hex values for LCD Display
// Enter Live Hex Data Values from hardware here
// LCD DISPLAYS THE FOLLOWING:
//----------------------------
//| Count=XX                  |
//| DE2                       |
//----------------------------
// Line 1
   always 
     case (index)
    5'h00: out <= 8'h43;
    5'h01: out <= 8'h6F;
    5'h02: out <= 8'h75;
    5'h03: out <= 8'h6E;
    5'h04: out <= 8'h74;
    5'h05: out <= 8'h3D;
    5'h06: out <= {4'h0,hex1};
    5'h07: out <= {4'h0,hex0};
// Line 2
    5'h10: out <= 8'h44;
    5'h11: out <= 8'h45;
    5'h12: out <= 8'h32;
    default: out <= 8'h20;
     endcase
endmodule
reset_delay.v



module    Reset_Delay(iCLK,oRESET);
input        iCLK;
output reg    oRESET;
reg    [19:0]    Cont;

always@(posedge iCLK)
begin
    if(Cont!=20'hFFFFF)
    begin
        Cont    <=    Cont+1'b1;
        oRESET    <=    1'b0;
    end
    else
    oRESET    <=    1'b1;
end