/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Physics Institute, University of Bonn
 * ------------------------------------------------------------
 */


module ftop144_prod_F(
        input  wire [3:0]  mc_d_fltn,
        input  wire [3:0]  mc_a_fltn,
        input  wire [7:0]  mc_st_fltn,
        input  wire [7:0]  mc_gt_fltn,

        input  wire        SHDN_2,
        input  wire        SHDN_1,

        input  wire        rst_n,
        input  wire        JMP,
        output wire [3:0]  diodes,
        output wire        OVP_IO_MUX,
        output wire        OVP_IO_STAT,
        input  wire [5:0]  OVP_IO_A,

        output wire        uc_a_rstn,   // not used
        output wire        uc_a_shdwn,  // shutdown for analog genbarts
        output wire        uc_a_off,    // off for analog 2912

        output wire        uc_d_shdwn,  // shutdown for digital genbarts

        output wire        uc_gt_offa,  // off for gt 2912
        output wire        uc_gt_offb,  // off for gt 2912
        output wire        uc_st_offa,  // off for st 2912
        output wire        uc_st_offb,  // off for st 2912
        
        output wire        ax_res,      //betw(0)
        input  wire        ax_clk,      //betw(1)
        input  wire        ax_frame,    //betw(2)
        output wire        ax_data,     //betw(3)
        input  wire        ax_write,    //betw(4)
        input  wire        ax_data_in   //betw(5)
    );

parameter  CSZIZE = 3;
parameter TESTDATA = 24'h0A0B0C; 
reg [3:0] ra_fltn;
reg [3:0] rd_fltn;
reg [7:0] rst_fltn;
reg [7:0] rgt_fltn;

wire a_fltn;
wire d_fltn;
wire st_fltn;
wire gt_fltn;

reg [23:0] cmask;
wire [23:0] rstat;
wire [23:0] stat;
wire reg_reset;

reg [3:0] gmc_d_fltn;
reg [3:0] gmc_a_fltn;
reg [7:0] gmc_st_fltn;
reg [7:0] gmc_gt_fltn;

wire blockn;

// F version
wire sdata_out;
reg mux_out;
wire eng_mode;
wire norm_reset;

wire istat;
reg iax_data_read;
reg iax_res;
reg iax_block;

reg [31:0] creg;
reg [5:0] iaxframecount;
reg [4:0] cnb;
integer i;
assign creg = 32'h000000;
//rst_n    - from the push button
//ax_res   - from the aux xilinx (I2C)
//norm_reset - SHDN_1 = LOW in normal mode

assign reg_reset = ~rst_n | iax_res | norm_reset;

assign eng_mode = JMP;    // active high : jumper off => engineering mode

// use SHDN 1 (active low) as a reset in NORMAL mode
assign norm_reset = (~eng_mode) & (~SHDN_1);

// OVP_IO_A(5) used as a disable of 2912 (SSRs) in NORMAL mode
//  channels are disabled individually
// by the cmask bits
// blockn = LOW keeps the genbarts and SSR active, can be set from I2C

assign blockn = (~eng_mode & OVP_IO_A[5]) & (~iax_block);

// only MUX in the F version (basic status output)
assign OVP_IO_MUX = mux_out;

// 0 if NOT OK:
assign istat = (a_fltn & d_fltn & st_fltn & gt_fltn) | eng_mode;

// eng_mode => do not stop power supply
assign OVP_IO_STAT = istat;

assign d_fltn = rd_fltn[0] & rd_fltn[1] & rd_fltn[2] & rd_fltn[3];
assign a_fltn = ra_fltn[0] & ra_fltn[1] & ra_fltn[2] & ra_fltn[3];
assign st_fltn = rst_fltn[0] & rst_fltn[1] & rst_fltn[2] & rst_fltn[3] & rst_fltn[4] & rst_fltn[5] & rst_fltn[6] & rst_fltn[7];
assign gt_fltn = rgt_fltn[0] & rgt_fltn[1] & rgt_fltn[2] & rgt_fltn[3] & rgt_fltn[4] & rgt_fltn[5] & rgt_fltn[6] & rgt_fltn[7];

// as received from the channels
assign stat[3:0] = mc_d_fltn;
assign stat[7:4] = mc_a_fltn;
assign stat[15:8] = mc_st_fltn;
assign stat[23:16] = mc_gt_fltn;
// masked, latched      
assign rstat[3:0] = rd_fltn;
assign rstat[7:4] = ra_fltn;
assign rstat[15:8] = rst_fltn;
assign rstat[23:16] = rgt_fltn;
//                                                                                
assign diodes[0] = d_fltn;
assign diodes[1] = a_fltn;
assign diodes[2] = st_fltn;
assign diodes[3] = gt_fltn;

//blockn = LOW keeps the genbarts and SSR active
assign uc_d_shdwn = d_fltn |  ~blockn;  // low to digital genbarts to switch them off
assign uc_a_shdwn = a_fltn |  ~blockn;  // low to analog genbarts to switch them off
// if masked, then flops are not set and  genbarts are not shutdown
assign uc_a_off = (~a_fltn) &  ~reg_reset & blockn; // high to analog opto to switch it off
assign uc_a_rstn = rst_n;   //not used

assign uc_st_offa = (~st_fltn) &  ~reg_reset & blockn; // reg_reset high  keeps SSR OPEN
assign uc_st_offb = (~st_fltn) &  ~reg_reset & blockn;

assign uc_gt_offa = (~gt_fltn) &  ~reg_reset & blockn;
assign uc_gt_offb = (~gt_fltn) &  ~reg_reset & blockn;


//*******************************************************************************************
always @(mc_d_fltn or mc_a_fltn or mc_st_fltn or mc_gt_fltn or cmask) begin
    for (i=0; i<=3 ; i=i+1)  begin
        gmc_d_fltn[i] <= mc_d_fltn[i] | cmask[i];
    end
    for (i=0; i<=3 ; i=i+1)  begin
        gmc_a_fltn[i] <= mc_a_fltn[i] | cmask[i+4];
    end
    for (i=0; i<=7 ; i=i+1)  begin
        gmc_st_fltn[i] <= mc_st_fltn[i] | cmask[i+8];
    end
    for (i=0; i<=7 ; i=i+1)  begin
        gmc_gt_fltn[i] <= mc_gt_fltn[i] | cmask[i+16];
    end
end

//REG_DIGITAL*******************************************************************************************
always @(reg_reset or gmc_d_fltn) begin
    for (i=0; i<=3; i=i+1) begin
      if(reg_reset == 1'b1) 
            rd_fltn[i] <= 1'b1;
      else if(gmc_d_fltn[i] == 1'b0) 
            rd_fltn[i] <= 1'b0;
    end 
end

//REG_ANALOG*******************************************************************************************
always @(reg_reset or gmc_a_fltn) begin
    for (i=0; i<=3; i=i+1) begin
      if(reg_reset == 1'b1) 
            ra_fltn[i] <= 1'b1;
      else if(gmc_a_fltn[i] == 1'b0) 
            ra_fltn[i] <= 1'b0;
    end 
end

//REG_ST*****************************************************************************  
always @(reg_reset or gmc_st_fltn) begin
    for (i=0; i<=7; i=i+1) begin
      if(reg_reset == 1'b1) 
            rst_fltn[i] <= 1'b1;
      else if(gmc_st_fltn[i] == 1'b0) 
            rst_fltn[i] <= 1'b0;
    end 
end

//REG_GT*****************************************************************************  
always @(reg_reset or gmc_gt_fltn) begin
    for (i=0; i<=7; i=i+1) begin
      if(reg_reset == 1'b1) 
            rgt_fltn[i] <= 1'b1;
      else if(gmc_gt_fltn[i] == 1'b0) 
            rgt_fltn[i] <= 1'b0;
    end 
end

//RDMUX*****************************************************************************
always @(OVP_IO_A[4:0] or rstat) begin
    mux_out <= rstat[OVP_IO_A[4:0]];
end

//*****************************************************************************
//                 F below
//*****************************************************************************
always @(negedge ax_frame or negedge ax_clk) begin
    if (ax_frame == 1'b0) begin // negedge ax_frame 
        iaxframecount <= 0;
        cnb <= 31;
    end
    else begin  // negedge ax_clk 
        iaxframecount <= iaxframecount+1;
        cnb <= cnb-1;
    end
end


assign ax_data =  iax_data_read;
assign ax_res = ~rst_n;

always @(ax_write or iaxframecount or istat or stat or creg) begin
    if(ax_write ==1'b0) // data is before ax_frame
        if ((iaxframecount>=6'b000000) && (iaxframecount<=6'b000111)) // from 0 to 7
            iax_data_read <=  istat;
        else if ((iaxframecount>=6'b001000) && (iaxframecount<=6'b011111)) begin   // from 8 to 31
            if (creg[24] == 1'b0)
                iax_data_read <= rstat[cnb];
            else 
                iax_data_read <= stat[cnb];
        end
        else if ((iaxframecount>=6'b100000))
            iax_data_read <= creg[cnb];
end


always @(ax_frame or  ax_write or ax_clk) begin
    if((ax_frame == 1'b0 || ax_write == 1'b0)) begin
        cmask[23:0] <= creg[23:0];
        iax_res <= creg[31];
        iax_block <= creg[30];
    end    
    else if (ax_clk == 1'b0) begin
        creg[cnb] <= ax_data_in;
    end
end


endmodule