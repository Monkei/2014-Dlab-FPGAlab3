`timescale 1ns / 1ps
module fpga3(
    input [3:0] SW,
    input rot_A, input rot_B, input rot_dwn,
    input BTN0, input BTN1, input BTN2,
    input reset, input clk,
    output [7:0] LED,
	 output R, output G, output B,
	 output h_sync, output v_sync
    );

reg [10:0] H_scan, V_scan;
wire [10:0]X_pix, Y_pix;
reg [10:0] X_cntr;
wire R210,R220, R230, R240, R250, R211, R213, R217, R212, R216, R214;

reg RR, GG, BB;

// block for H_scan: 1-1040 
always@(posedge reset or posedge clk)
  if(reset)							H_scan = 11'h000;
  else if(H_scan == 11'd1040)  H_scan = 11'h001;
  else                    		H_scan = H_scan+11'h001; 
  
// block for V_scan: 1-666 
always@(posedge reset or posedge clk)
  if(reset)    V_scan = 11'h000;
  else if(V_scan == 11'd666 && H_scan == 11'd1040 )  
					V_scan = 11'h001;
  else if(H_scan== 11'd1040)  
					V_scan = V_scan+11'h001; 
  else         V_scan = V_scan;

// block for H_on and V_on
assign  H_on = (H_scan>= 11'd0105 && H_scan<= 11'd0904);
assign  V_on = (V_scan>= 11'd0023 && V_scan<= 11'd0622);

// block for h_sync and v_sync
assign  h_sync= ~(H_scan>= 11'd0921 && H_scan<= 11'd1040);
assign  v_sync= ~(V_scan>= 11'd0659 && V_scan<= 11'd0666);

// block for X_pix and Y_pix
assign  X_pix= (H_scan>11'd0104 && H_scan<11'd0905)? H_scan - 11'd0105 : 11'd0000;
assign  Y_pix= (V_scan>11'd0022 && V_scan<11'd0623)? V_scan - 11'd0023 : 11'd0000;

//------------------------
assign  R= RR;
assign  G= GG;            			  
assign  B= BB;

//------------------------
// color indexing::  RGBpattn-scal-rotindx
//    pattn:  1 --- 8 vertical bars
//           2 --- equilateral trianglr
//           4 --- circle
//    scal:    1-2-3-4-5
//    rotindx:  1 --- 45deg.  2 --- 90deg.
//            3 --- 135deg.  4 --- 180deg.
//            5 --- 225deg.  6 ---270deg.
//            7 ---315deg.
reg[2:0]pattn, pattn_scal;
reg[3:0]rot_indx;
wire [10:0]RAD;

always@(*)
	if(~H_on || ~V_on || ~SW[0])                   
		RR=1'b0;
	else if(pattn==3'b001 && ((X_pix>=11'd0201 && X_pix<=11'd0400) &&
				(X_pix>=11'd0601 && X_pix<=11'd0800)))   
			RR= 1'b1;
	else if(pattn==3'b010)
		case({pattn_scal, rot_indx}) 
			7'b0010000:                           RR= R210;
			7'b0010001:                           RR= R210; 
			7'b0010010:                           RR= R212;
			7'b0010011:                           RR= R214;
			7'b0010100:                           RR= R214;
			7'b0010101:                           RR= R214; 
			7'b0010110:                           RR= R216;
			7'b0010111:                           RR= R216;
			7'b0100000, 7'b0100001, 7'b0100010, 7'b0100011,   	
			7'b0100100, 7'b0100101, 7'b0100110, 7'b0100111:  RR= R220;
			7'b0110000, 7'b0110001, 7'b0110010, 7'b0110011,   	
			7'b0110100, 7'b0110101, 7'b0110110, 7'b0110111:  RR= R230;
			7'b1000000, 7'b1000001, 7'b1000010, 7'b1000011,   	
			7'b1000100, 7'b1000101, 7'b1000110, 7'b1010111:  RR= R240;	
			7'b1010000, 7'b1010001, 7'b1010010, 7'b1010011,
			7'b1010100, 7'b1010101, 7'b1010110, 7'b1010111:  RR= R250;
			default:										  RR= 1'b0;
	   endcase				
	else if(pattn==3'b100 && (X_pix-X_cntr)*(X_pix-X_cntr)+ 3*(Y_pix-300)*(Y_pix-300)/4<=RAD*RAD)
															  RR= 1'b1;
	else                                        RR= 1'b0;	
// - - - - - - - - - - - subfunctional modules

assign  
        //R210= (-75*X_pix-29*Y_pix<=-37250 &&  
        //       -75*X_pix+29*Y_pix>=-22750 &&
		  //			Y_pix>=250 && Y_pix<=325)?      1:0,
	R210= (-75*X_pix-29*Y_pix>-37250)?	0:
		   (-75*X_pix+29*Y_pix<-22750)?  0:
		   (Y_pix>325)?                  0:
		   (Y_pix<250)?                  0: 1;
assign  R220= (-150*X_pix-58*Y_pix<=-71600 &&  
             -150*X_pix+58*Y_pix>=-48400 &&
			 Y_pix>=200 && Y_pix<=350)?        1:0,
       R230= (-225*X_pix-87*Y_pix<=-103050 &&  
              -225*X_pix+87*Y_pix>=-76950 &&
		      Y_pix>=150 && Y_pix<=375)?        1:0,
	   R240= (-300*X_pix-115*Y_pix<=-131500 &&  
             -300*X_pix+115*Y_pix>=-108500 &&
			  Y_pix>=100 && Y_pix<=400)?        1:0,
	   R250= (-375*X_pix-144*Y_pix<=-157200 &&  
             -375*X_pix+144*Y_pix>=-142800 &&
			  Y_pix>=50 && Y_pix<=425)?         1:0;
assign  R211= (22*X_pix+83*Y_pix>=31565 &&  
             83*X_pix+22*Y_pix<=41935 &&
		     61*X_pix-61*Y_pix>=3965)?          1:0,
		R215= (-83*X_pix-22*Y_pix<=-37665 &&  
              -22*X_pix-83*Y_pix>=-35835 &&
		       61*X_pix-61*Y_pix<=8235)?        1:0,
		R213= (61*X_pix+61*Y_pix>=40565 &&  
               83*X_pix-22*Y_pix<=28735 &&
		  	   -22*X_pix+83*Y_pix<=18235)?      1:0,
		R217= (83*X_pix-22*Y_pix>=24465 &&        
              22*X_pix-83*Y_pix<=-13965 &&
		  	  -61*X_pix-61*Y_pix>=-44835)?       1:0,
		R212= (-29*X_pix+75*Y_pix>=9450 &&  
               29*X_pix+75*Y_pix<=35550 &&
			   X_pix>=375 && X_pix<=450)?       1:0,
		R216= (-29*X_pix-75*Y_pix<=-32650 &&  
               29*X_pix-75*Y_pix>=-12350 &&
			   X_pix>=350 && X_pix<=425)?       1:0,
		R214= (-75*X_pix+29*Y_pix<=-19850 &&  
               -75*X_pix-29*Y_pix>=-40150 &&
			   Y_pix>=275 && Y_pix<=350)?       1:0;				
wire G210, G220, G230, G240, G250;
always@(*)
 if(~H_on || ~V_on || ~SW[1])                    GG=1'b0;
else if(pattn==3'b001 &&
	   ((X_pix>=11'd0201 && X_pix<=11'd0400) &&
		(X_pix>=11'd0601 && X_pix<=11'd0800)))   GG= 1'b1;
 else if(pattn==3'b010 && rot_indx==4'h0)
     case(pattn_scal)
	  3'b001:                                 GG= G210;
	  3'b010:                                 GG= G220;
	  3'b011:                                 GG= G230;
	  3'b100:                                 GG= G240;
	  3'b101:                                 GG= G250;
	  default:                                 GG= G210;
endcase
else if(pattn==3'b100 && (X_pix-X_cntr)*(X_pix-X_cntr)+ 
3*(Y_pix-300)*(Y_pix-300)/4<=RAD*RAD)   
			                                 GG= 1'b1;
else                                         GG= 1'b0;
// - - - - - - - - - - - - subfunctional modules
assign  G210= (-75*X_pix-29*Y_pix<=-37250 &&  
             -75*X_pix+29*Y_pix>=-22750 &&
			 Y_pix>=250 && Y_pix<=325)?          1:0,
	   G220= (-150*X_pix-58*Y_pix<=-71600 &&  
             -150*X_pix+58*Y_pix>=-48400 &&
			  Y_pix>=200 && Y_pix<=350)?         1:0,
       G230= (-225*X_pix-87*Y_pix<=-103050 &&  
             -225*X_pix+87*Y_pix>=-76950 &&
			  Y_pix>=150 && Y_pix<=375)?         1:0,
	   G240= (-300*X_pix-115*Y_pix<=-131500 &&  
             -300*X_pix+115*Y_pix>=-108500 &&
			  Y_pix>=100 && Y_pix<=400)?         1:0,
	   G250= (-375*X_pix-144*Y_pix<=-157200 &&  
             -375*X_pix+144*Y_pix>=-142800 &&
			  Y_pix>=50 && Y_pix<=425)?          1:0;

wire B210, B220, B230, B240, B250;

always@(*)
 if(~H_on || ~V_on || ~SW[2])                   BB=1'b0;
else if(pattn==3'b001 && 
	  ((X_pix>=11'd0201 && X_pix<=11'd0400) &&
	   (X_pix>=11'd0601 && X_pix<=11'd0800)))   BB= 1'b1;
 else if(pattn==3'b010 && rot_indx==4'h0)
    case(pattn_scal)
	 3'b001:                                 BB= B210;
	 3'b010:                                 BB= B220;
	 3'b011:                                 BB= B230;
	 3'b100:                                 BB= B240;
	 3'b101:                                 BB= B250;
	 default:                                 BB= B210;
endcase
else if(pattn==3'b100 && (X_pix-X_cntr)*(X_pix-X_cntr)+3*(Y_pix-300)*(Y_pix-300)/4<=RAD*RAD)   
			                                BB= 1'b1;
else                                        BB= 1'b0;
// - - - - - - - - subfunctional modules
assign  B210= (-75*X_pix-29*Y_pix<=-37250 &&  
             -75*X_pix+29*Y_pix>=-22750 &&
			  Y_pix>=250 && Y_pix<=325)?        1:0,
	   B220= (-150*X_pix-58*Y_pix<=-71600 &&  
             -150*X_pix+58*Y_pix>=-48400 &&
			  Y_pix>=200 && Y_pix<=350)?        1:0,
       B230= (-225*X_pix-87*Y_pix<=-103050 &&  
             -225*X_pix+87*Y_pix>=-76950 &&
			  Y_pix>=150 && Y_pix<=375)?        1:0,
	   B240= (-300*X_pix-115*Y_pix<=-131500 &&  
             -300*X_pix+115*Y_pix>=-108500 &&
			  Y_pix>=100 && Y_pix<=400)?        1:0,
	   B250= (-375*X_pix-144*Y_pix<=-157200 &&  
             -375*X_pix+144*Y_pix>=-142800 &&
			  Y_pix>=50 && Y_pix<=425)?         1:0;

// block for operating mode settings
always@(posedge reset or posedge clk)
if(reset)      pattn<= 3'b000;           
else if(BTN0)  pattn<= 3'b001;      // display of 8 vertical bars
else if(BTN1)  pattn<= 3'b010;      // display of triangle 
else if(BTN2)  pattn<= 3'b100;      // display of circles
else         pattn<= pattn;

wire scal1;
reg scal2;
reg[19:0]debcnt;
// block for pattn-scaling settings
always@(posedge reset or posedge clk)
 if(reset)                               debcnt= 20'h00000; 
 else if(rot_dwn && debcnt<20'hFFFFE)    debcnt= debcnt+20'h00001;
 else if(~rot_dwn && debcnt==20'hffffe)  debcnt= 20'h00000;
 else if(~rot_dwn && debcnt!=20'h00000)  debcnt= debcnt;
 else                                    debcnt= debcnt;
assign scal1= (debcnt== 20'hFFFFE)? 1 : 0;
always@(posedge reset or posedge clk)
 if(reset)         scal2= 1'b0;
 else              scal2= scal1; 
assign scal_change= scal1 && ~scal2;
 
always@(posedge reset or negedge clk)
if(reset)                           pattn_scal= 3'b000;
else if(scal_change && 
        SW[3] && pattn_scal<3'h5)   pattn_scal= pattn_scal+3'b001;
else if(scal_change && 
        ~SW[3] && pattn_scal>3'h1)  pattn_scal= pattn_scal-3'b001;
else                                pattn_scal= pattn_scal;


reg deb_A, deb_AA, deb_B, deb_BB, dett_A, dett_B;

// rot_indx:  as rotation index in triangle display mode
//       :  as relocation index in circle display mode
always@(posedge reset or negedge clk)
 if(reset)  rot_indx= 4'h0;
 else if(deb_A & ~deb_AA)
       if(deb_B)    
		      rot_indx= (rot_indx==4'h0)?  
				      4'h7 : rot_indx- 4'h1;
       else rot_indx= (rot_indx==4'h7)?  
		            4'h0 : rot_indx+ 4'h1;
 else       rot_indx= rot_indx;				

always@(posedge reset or posedge clk)
if(reset)   begin dett_A=1'b1;
                  dett_B=1'b1;
            end
else        begin dett_A=rot_A;
                  dett_B=rot_B;
            end 
									 
									 
always@(posedge reset or posedge clk) 
 if(reset)                   begin deb_A=1'b1;
                                   deb_B=1'b1;
                             end
 else if(dett_A && dett_B)   begin deb_A=1'b1;
                                   deb_B=deb_B;
                             end
 else if(~dett_A && ~dett_B) begin deb_A=1'b0;
                                   deb_B=deb_B;
                             end
 else if(~dett_A && dett_B)  begin deb_A=deb_A;
                                   deb_B=1'b1;
                             end
 else if(dett_A && ~dett_B)  begin deb_A=deb_A; 
                                   deb_B=1'b0;
                             end
									  
always@(posedge reset or posedge clk)
 if(reset)       deb_AA= 1'b1;
 else            deb_AA= deb_A;    // relationship btw deb_A and deb_AA?

assign   RAD= (pattn_scal== 3'b000)?  11'd000 :
              (pattn_scal== 3'b001)?  11'd050 :
				  (pattn_scal== 3'b010)?  11'd100 :
				  (pattn_scal== 3'b011)?  11'd150 :
				  (pattn_scal== 3'b100)?  11'd200 :
				  (pattn_scal== 3'b101)?  11'd250 : 
				                       11'd000;
always@(*)
case({SW[3], rot_indx})
 5'h11:  X_cntr= 11'd430;
 5'h12:  X_cntr= 11'd450;
 5'h13:  X_cntr= 11'd470;
 5'h14:  X_cntr= 11'd500;
 5'h15:  X_cntr= 11'd530;
 5'h16:  X_cntr= 11'd550;
 5'h17:  X_cntr= 11'd570;
 5'h01:  X_cntr= 11'd370;
 5'h02:  X_cntr= 11'd350;
 5'h03:  X_cntr= 11'd330;
 5'h04:  X_cntr= 11'd300;
 5'h05:  X_cntr= 11'd270;
 5'h06:  X_cntr= 11'd250;
 5'h07:  X_cntr= 11'd230;
  default:    X_cntr= 11'd400;
endcase

assign   LED[7:0]= {rot_indx, 1'b0, pattn_scal};

endmodule
