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

reg[10:0] H_scan,V_scan;
wire H_on , V_on;
wire[10:0] X_pix , Y_pix;
reg RR , GG , BB;
reg[2:0] pattn;
reg[3:0] rot_indx;
reg[19:0] debcnt;
reg scal2;
wire scal1,scal_change;
reg[2:0] pattn_scal;
reg dett_A,dett_B,deb_A,deb_B,deb_AA;
wire[10:0] RAD;
reg[10:0] X_cntr;
wire R210,R220,R230,R240,R250,R212,R214,R216/*,R222,R224,R226,R217,R211,R213,R215*/;
wire G210,G220,G230,G240,G250,G212,G214,G216;
wire B210,B220,B230,B240,B250,B212,B214,B216;


// block for H_scan: 1-1040 
always@(posedge reset or posedge clk)
	if(reset)
		H_scan= 11'h000;
	else if(H_scan== 11'd1040)
		H_scan= 11'h001;
	else
		H_scan= H_scan+11'h001; 
// block for V_scan: 1-666 
always@(posedge reset or posedge clk)
	if(reset)
		V_scan= 11'h000;
	else if(V_scan== 11'd666 && H_scan== 11'd1040 )
		V_scan= 11'h001;
	else if(H_scan== 11'd1040)
		V_scan= V_scan+11'h001; 
	else
		V_scan= V_scan;

// block for H_on and V_on
assign  H_on= (H_scan>= 11'd0105 && H_scan<= 11'd0904);
assign  V_on= (V_scan>= 11'd0023 && V_scan<= 11'd0622);
// block for h_sync and v_sync
assign  h_sync= ~(H_scan>= 11'd0921 && H_scan<= 11'd1040);
assign  v_sync= ~(V_scan>= 11'd0659 && V_scan<= 11'd0666);
// block for X_pix and Y_pix
assign  X_pix= (H_scan>=11'd0105 && H_scan<=11'd0904)? H_scan - 11'd0105 : 11'd0000;
assign  Y_pix= (V_scan>=11'd0023 && V_scan<=11'd0622)? V_scan - 11'd0023 : 11'd0000;

assign  R= RR;
assign  G= GG;            			  
assign  B= BB;

always@(*)
	if(~H_on || ~V_on || ~SW[0])
		RR=1'b0;
	else if(pattn==3'b001 && ((X_pix>=11'd0001 && X_pix<=11'd0300) || (X_pix>=11'd0601 && X_pix<=11'd0700)))
		RR= 1'b1;
	else if(pattn==3'b010)
		case({pattn_scal, rot_indx}) //3+4
			7'b0010000,7'b0010100:RR= R210;
			7'b0010001,7'b0010101:RR= R212; 
			7'b0010010,7'b0010110:RR= R214;
			7'b0010011,7'b0010111:RR= R216;
			
			7'b0100000,7'b0100001,7'b0100010,7'b0100011,
			7'b0100100,7'b0100101,7'b0100110,7'b0100111:
						RR= R220;
			7'b0110000,7'b0110001,7'b0110010,7'b0110011,   	
			7'b0110100,7'b0110101,7'b0110110,7'b0110111:
						RR= R230;
			7'b1000000,7'b1000001,7'b1000010,7'b1000011,   	
			7'b1000100,7'b1000101,7'b1000110,7'b1010111:
						RR= R240;	
			7'b1010000,7'b1010001,7'b1010010,7'b1010011,
			7'b1010100,7'b1010101,7'b1010110,7'b1010111:
						RR= R250;
			default:RR= 1'b0;
	    endcase				
	else if(pattn==3'b100 &&(X_cntr+RAD)>X_pix&&(X_cntr-RAD)<X_pix&& (X_pix-X_cntr)*(X_pix-X_cntr)+3*(Y_pix-300)*(Y_pix-300)/4<=RAD*RAD)
		RR= 1'b1;

				/*if(X_pix>=X_cntr)
			if(Y_pix >= 300)
				if((X_pix-X_cntr)*(X_pix-X_cntr)*4+3*(Y_pix-300)*(Y_pix-300)<=4*RAD*RAD)
					RR= 1'b1;
		/*else 
			if()*/
	else
		RR= 1'b0;	
// - - - - - - - - - - - subfunctional modules
//assign R210= (-75*X_pix-29*Y_pix>-37250)? 0:
//		     (-75*X_pix+29*Y_pix<-22750)? 0:
//		     (Y_pix>325)?                 0:
//		     (Y_pix<250)?                 0: 1; 

//---------------------------
assign R210= (75*X_pix+29*Y_pix>=37250 && 75*X_pix<=22750+29*Y_pix && Y_pix>=250 && Y_pix<=325 && X_pix>=350 && X_pix<=450)? 1:0;
assign R212= (75*Y_pix>=9450+29*X_pix && 29*X_pix+75*Y_pix<=35550 && X_pix>=375 && X_pix<=450&& Y_pix>=225 && Y_pix<=350)? 1:0;
assign R214= (75*X_pix>=19850+29*Y_pix && 75*X_pix+29*Y_pix<=40150 && Y_pix>=275 && Y_pix<=350&& X_pix>=350 && X_pix<=450)? 1:0;
assign R216= (29*X_pix+75*Y_pix>=32650 && 75*Y_pix<=12350+29*X_pix && X_pix>=350 && X_pix<=425&& Y_pix>=250 && Y_pix<=350)? 1:0;

assign R220= (150*X_pix+58*Y_pix>=71600 &&  150*X_pix<=48400+58*Y_pix && Y_pix>=200 && Y_pix<=350)? 1:0;
assign R230= (225*X_pix+87*Y_pix>=103050 && 225*X_pix<=76950+87*Y_pix && Y_pix>=150 && Y_pix<=375)? 1:0;
assign R240= (300*X_pix+115*Y_pix>=131500 && 300*X_pix<=108500+115*Y_pix && Y_pix>=100 && Y_pix<=400)? 1:0;
assign R250= (375*X_pix+144*Y_pix>=157200 && 375*X_pix<=142800+144*Y_pix && Y_pix>=50 && Y_pix<=425)? 1:0;

//---------------------------
//assign G210= (75*X_pix+29*Y_pix>=37250 && 75*X_pix<=22750+29*Y_pix && Y_pix>=250 && Y_pix<=325)? 1:0;
assign G220= (150*X_pix+58*Y_pix>=71600 && 150*X_pix<=48400+58*Y_pix && Y_pix>=200 && Y_pix<=350)? 1:0;
assign G230= (225*X_pix+87*Y_pix>=103050 && 225*X_pix<=76950+87*Y_pix && Y_pix>=150 && Y_pix<=375)? 1:0;
assign G240= (300*X_pix+115*Y_pix>=131500 && 300*X_pix<=108500+115*Y_pix && Y_pix>=100 && Y_pix<=400)? 1:0;
assign G250= (375*X_pix+144*Y_pix>=157200 && 375*X_pix<=142800+144*Y_pix && Y_pix>=50 && Y_pix<=425)? 1:0;

assign G210= (75*X_pix+29*Y_pix>=37250 && 75*X_pix<=22750+29*Y_pix && Y_pix>=250 && Y_pix<=325 && X_pix>=350 && X_pix<=450)? 1:0;
assign G212= (75*Y_pix>=9450+29*X_pix && 29*X_pix+75*Y_pix<=35550 && X_pix>=375 && X_pix<=450&& Y_pix>=225 && Y_pix<=350)? 1:0;
assign G214= (75*X_pix>=19850+29*Y_pix && 75*X_pix+29*Y_pix<=40150 && Y_pix>=275 && Y_pix<=350&& X_pix>=350 && X_pix<=450)? 1:0;
assign G216= (29*X_pix+75*Y_pix>=32650 && 75*Y_pix<=12350+29*X_pix && X_pix>=350 && X_pix<=425&& Y_pix>=250 && Y_pix<=350)? 1:0;
//---------------------------
//assign B210= (75*X_pix+29*Y_pix>=37250 && 75*X_pix<=22750+29*Y_pix && Y_pix>=250 && Y_pix<=325)? 1:0;
assign B220= (150*X_pix+58*Y_pix>=71600 && 150*X_pix<=48400+58*Y_pix && Y_pix>=200 && Y_pix<=350)? 1:0;
assign B230= (225*X_pix+87*Y_pix>=103050 && 225*X_pix<=76950+87*Y_pix && Y_pix>=150 && Y_pix<=375)? 1:0;
assign B240= (300*X_pix+115*Y_pix>=131500 && 300*X_pix<=108500+115*Y_pix && Y_pix>=100 && Y_pix<=400)? 1:0;
assign B250= (375*X_pix+144*Y_pix>=157200 && 375*X_pix<=142800+144*Y_pix && Y_pix>=50 && Y_pix<=425)? 1:0;
/*
assign B212= (75*Y_pix>=9450+29*X_pix && 29*X_pix+75*Y_pix<=35550 && X_pix>=375 && X_pix<=450)? 1:0;
assign B216= (29*X_pix+75*Y_pix>=32650 && 75*Y_pix<=12350+29*X_pix && X_pix>=350 && X_pix<=425)? 1:0;
assign B214= (75*X_pix>=19850+29*Y_pix && 75*X_pix+29*Y_pix<=40150 && Y_pix>=275 && Y_pix<=350)? 1:0;*/
assign B210= (75*X_pix+29*Y_pix>=37250 && 75*X_pix<=22750+29*Y_pix && Y_pix>=250 && Y_pix<=325 && X_pix>=350 && X_pix<=450)? 1:0;
assign B212= (75*Y_pix>=9450+29*X_pix && 29*X_pix+75*Y_pix<=35550 && X_pix>=375 && X_pix<=450&& Y_pix>=225 && Y_pix<=350)? 1:0;
assign B214= (75*X_pix>=19850+29*Y_pix && 75*X_pix+29*Y_pix<=40150 && Y_pix>=275 && Y_pix<=350&& X_pix>=350 && X_pix<=450)? 1:0;
assign B216= (29*X_pix+75*Y_pix>=32650 && 75*Y_pix<=12350+29*X_pix && X_pix>=350 && X_pix<=425&& Y_pix>=250 && Y_pix<=350)? 1:0;

/*assign R222= (150*Y_pix>=9450*2+58*X_pix && 58*X_pix+150*Y_pix<=35550*2 && X_pix>=300 && X_pix<=475)? 1:0;
assign R224= (150*X_pix>=19850*2+58*Y_pix && 150*X_pix+58*Y_pix<=2*40150 && Y_pix>=175 && Y_pix<=375)? 1:0;
assign R226= (58*X_pix+150*Y_pix>=32650*2 && 150*Y_pix<=12350*2+58*X_pix && X_pix>=300 && X_pix<=600)? 1:0;*/

     /*
assign R211= (22*X_pix+83*Y_pix>=31565 && 83*X_pix+22*Y_pix<=41935 && 61*X_pix-61*Y_pix>=3965)? 1:0;
assign R215= (-83*X_pix-22*Y_pix<=-37665 && -22*X_pix-83*Y_pix>=-35835 && 61*X_pix-61*Y_pix<=8235)? 1:0;
assign R213= (61*X_pix+61*Y_pix>=40565 && 83*X_pix-22*Y_pix<=28735 && -22*X_pix+83*Y_pix<=18235)? 1:0;
assign R217= (83*X_pix-22*Y_pix>=24465 && 22*X_pix-83*Y_pix<=-13965 && -61*X_pix-61*Y_pix>=-44835)? 1:0;
*/

always@(*)
	if(~H_on || ~V_on || ~SW[1])
		GG=1'b0;
	else if(pattn==3'b001 && ((X_pix>=11'd0001 && X_pix<=11'd0100) || (X_pix>=11'd0201 && X_pix<=11'd0500)))
		GG= 1'b1;
	else if(pattn==3'b010)
		case({pattn_scal, rot_indx}) //3+4
			7'b0010000,7'b0010100:GG= G210;
			7'b0010001,7'b0010101:GG= G212; 
			7'b0010010,7'b0010110:GG= G214;
			7'b0010011,7'b0010111:GG= G216;
			
			7'b0100000,7'b0100001,7'b0100010,7'b0100011,
			7'b0100100,7'b0100101,7'b0100110,7'b0100111:
						GG= G220;
			7'b0110000,7'b0110001,7'b0110010,7'b0110011,   	
			7'b0110100,7'b0110101,7'b0110110,7'b0110111:
						GG= G230;
			7'b1000000,7'b1000001,7'b1000010,7'b1000011,   	
			7'b1000100,7'b1000101,7'b1000110,7'b1010111:
						GG= G240;	
			7'b1010000,7'b1010001,7'b1010010,7'b1010011,
			7'b1010100,7'b1010101,7'b1010110,7'b1010111:
						GG= G250;
			default:GG= 1'b0; 
	    endcase				
	else if(pattn==3'b100 &&(X_cntr+RAD)>X_pix&&(X_cntr-RAD)<X_pix&& (X_pix-X_cntr)*(X_pix-X_cntr)+3*(Y_pix-300)*(Y_pix-300)/4<=RAD*RAD)
		GG= 1'b1;
		/*temp = 
		if(X_pix>=X_cntr)begin
			if(Y_pix >= 300)begin
				if((X_pix-X_cntr)*(X_pix-X_cntr)*4+3*(Y_pix-300)*(Y_pix-300)<=4*RAD*RAD)
					GG= 1'b1;
			end else begin
				if((X_pix-X_cntr)*(X_pix-X_cntr)*4+3*(300-Y_pix)*(300-Y_pix)<=4*RAD*RAD)
					GG= 1'b1;
			end
		end else begin
			if(Y_pix >= 300)begin
				if((X_cntr-X_pix)*(X_cntr-X_pix)*4+3*(Y_pix-300)*(Y_pix-300)<=4*RAD*RAD)
					GG= 1'b1;
			end else begin
				if((X_cntr-X_pix)*(X_cntr-X_pix)*4+3*(300-Y_pix)*(300-Y_pix)<=4*RAD*RAD)
					GG= 1'b1;
			end
		end
*/
	else                                         
		GG= 1'b0;
// - - - - - - - - - - - - subfunctional modules


always@(*)
	if(~H_on || ~V_on || ~SW[2])
		BB=1'b0;
	else if(pattn==3'b001 && ((X_pix>=11'd0001 && X_pix<=11'd0100) || (X_pix>=11'd0401 && X_pix<=11'd0700)))
		BB= 1'b1;
    else if(pattn==3'b010)
		case({pattn_scal, rot_indx}) //3+4
			7'b0010000,7'b0010100:BB= B210;
			7'b0010001,7'b0010101:BB= B212; 
			7'b0010010,7'b0010110:BB= B214;
			7'b0010011,7'b0010111:BB= B216;
			
			7'b0100000,7'b0100001,7'b0100010,7'b0100011,
			7'b0100100,7'b0100101,7'b0100110,7'b0100111:
						BB= B220;
			7'b0110000,7'b0110001,7'b0110010,7'b0110011,   	
			7'b0110100,7'b0110101,7'b0110110,7'b0110111:
						BB= B230;
			7'b1000000,7'b1000001,7'b1000010,7'b1000011,   	
			7'b1000100,7'b1000101,7'b1000110,7'b1010111:
						BB= B240;	
			7'b1010000,7'b1010001,7'b1010010,7'b1010011,
			7'b1010100,7'b1010101,7'b1010110,7'b1010111:
						BB= B250;
			default:BB= 1'b0;
	    endcase				
	else if(pattn==3'b100 &&(X_cntr+RAD)>X_pix&&(X_cntr-RAD)<X_pix&& (X_pix-X_cntr)*(X_pix-X_cntr)+3*(Y_pix-300)*(Y_pix-300)/4<=RAD*RAD)
		BB= 1'b1;

	else
		BB= 1'b0;
// - - - - - - - - subfunctional modules


// block for operating mode settings
always@(posedge reset or posedge clk)
	if(reset)
		pattn<= 3'b000;           
	else if(BTN0)
		pattn<= 3'b001;      // display of 8 vertical bars
	else if(BTN1)
		pattn<= 3'b010;      // display of triangle 
	else if(BTN2)
		pattn<= 3'b100;      // display of circles
	else
		pattn<= pattn;

// block for pattn-scaling settings
always@(posedge reset or posedge clk)
	if(reset)
		debcnt= 20'h00000; 
	else if(rot_dwn && debcnt<20'hFFFFE)
		debcnt= debcnt+20'h00001;
	else if(~rot_dwn && debcnt==20'hffffe)
		debcnt= 20'h00000;
	else if(~rot_dwn && debcnt!=20'h00000)
		debcnt= debcnt;
	else
		debcnt= debcnt;

assign scal1= (debcnt== 20'hFFFFE)? 1 : 0;

always@(posedge reset or posedge clk)
	if(reset)
		scal2= 1'b0;
	else
		scal2= scal1; 

assign scal_change= scal1 && ~scal2;
 
always@(posedge reset or negedge clk)
	if(reset)
		pattn_scal= 3'b001;
	else if(scal_change && SW[3] && pattn_scal<3'h5)
		pattn_scal= pattn_scal+3'b001;
	else if(scal_change && ~SW[3] && pattn_scal>3'h1)
		pattn_scal= pattn_scal-3'b001;
	else
		pattn_scal= pattn_scal;

// rot_indx:  as rotation index in triangle display mode
//       :  as relocation index in circle display mode

always@(posedge reset or negedge clk)
	if(reset)
		rot_indx= 4'h0;
	else if(deb_A & ~deb_AA)
		if(deb_B)    
		    rot_indx= (rot_indx==4'h0)? 4'h7 : rot_indx- 4'h1;
		else
			rot_indx= (rot_indx==4'h7)? 4'h0 : rot_indx+ 4'h1;
	else
		rot_indx= rot_indx;				

always@(posedge reset or posedge clk)
	if(reset)
		begin
			dett_A=1'b1;
			dett_B=1'b1;
        end
	else
		begin
			dett_A=rot_A;
			dett_B=rot_B;
        end 
									 								 
always@(posedge reset or posedge clk) 
	if(reset)
		begin
			deb_A=1'b1;
			deb_B=1'b1;
        end
	else if(dett_A && dett_B)
		begin
			deb_A=1'b1;
            deb_B=deb_B;
        end
	else if(~dett_A && ~dett_B)
		begin
			deb_A=1'b0;
            deb_B=deb_B;
        end
	else if(~dett_A && dett_B)
		begin
			deb_A=deb_A;
            deb_B=1'b1;
        end
	else if(dett_A && ~dett_B)
		begin
			deb_A=deb_A; 
         deb_B=1'b0;
        end
									  
always@(posedge reset or posedge clk)
	if(reset)
		deb_AA= 1'b1;
	else
		deb_AA= deb_A;    // relationship btw deb_A and deb_AA?
		

assign RAD= (pattn_scal== 3'b000)? 11'd000 :
            (pattn_scal== 3'b001)? 11'd050 :
				(pattn_scal== 3'b010)? 11'd100 :
				(pattn_scal== 3'b011)? 11'd150 :
				(pattn_scal== 3'b100)? 11'd200 :
				(pattn_scal== 3'b101)? 11'd250 : 
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
		default:X_cntr= 11'd400;
	endcase		
	
assign LED[7:0]= {rot_indx, 1'b0, pattn_scal};
	
endmodule
