--
-- VHDL Architecture xtovprot_lib.ftop144.arc
--
-- Created:
--          by - piotrek.UNKNOWN (PIOTREK-PC)
--          at - 10:13:11 09/29/2014
--
-- using Mentor Graphics HDL Designer(TM) 2012.1 (Build 6)
--
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

ENTITY ftop144_prod_F IS
 PORT(
    mc_d_fltn  : IN  STD_LOGIC_VECTOR(3 downto 0);
    mc_a_fltn  : IN  STD_LOGIC_VECTOR(3 downto 0);
    mc_st_fltn : IN  STD_LOGIC_VECTOR(7 downto 0);  
    mc_gt_fltn : IN  STD_LOGIC_VECTOR(7 downto 0);
    
    --SHDN_2     : IN  STD_LOGIC;
    SHDN_1     : IN  STD_LOGIC;
    
    rst_n      : IN  STD_LOGIC;
    JMP        : IN  STD_LOGIC;
    diodes     : OUT STD_LOGIC_VECTOR(3 downto 0);
    OVP_IO_MUX : OUT STD_LOGIC;
    OVP_IO_STAT: OUT STD_LOGIC;
    OVP_IO_A   : IN  STD_LOGIC_VECTOR(5 downto 0);
  
    uc_a_rstn  : OUT STD_LOGIC; -- not used 
    uc_a_shdwn : OUT STD_LOGIC; -- shutdown for analog genbarts
    uc_a_off   : OUT STD_LOGIC; -- off for analog 2912 
    
    uc_d_shdwn : OUT STD_LOGIC; -- shutdown for digital genbarts
    
    uc_gt_offa : OUT STD_LOGIC; -- off for gt 2912
    uc_gt_offb : OUT STD_LOGIC; -- off for gt 2912
    uc_st_offa : OUT STD_LOGIC; -- off for st 2912
    uc_st_offb : OUT STD_LOGIC; -- off for st 2912
    
   -- ax_res       : OUT STD_LOGIC;   -- betw(0)
    ax_clk       : IN STD_LOGIC;    -- betw(1)
    ax_frame     : IN STD_LOGIC;    -- betw(2)
    ax_data      : OUT STD_LOGIC;   -- betw(3)
    ax_write     : IN STD_LOGIC;    -- betw(4)
    ax_data_in   : IN STD_LOGIC;    -- betw(5)

    clk          : IN STD_LOGIC;    -- clock for flipflop  

    OVP_IO_STAT_delay 	: INOUT STD_LOGIC;   -- delay of output signal
    OVP_IO_STAT_delay_2 : INOUT STD_LOGIC;
    OVP_IO_STAT_delay_3 : INOUT STD_LOGIC;
    OVP_IO_STAT_delay_4 : INOUT STD_LOGIC;
    OVP_IO_STAT_delay_5 : INOUT STD_LOGIC;
    OVP_IO_STAT_delay_6 : INOUT STD_LOGIC;
    en                	: IN STD_LOGIC       -- enable tri-state buffer
  ); 
  
END ENTITY ftop144_prod_F;

--
ARCHITECTURE arch OF ftop144_prod_F IS
  constant CSIZE : integer := 3;
  constant TESTDATA : STD_LOGIC_VECTOR(23 downto 0) := X"0A0B0C";
  signal ra_fltn : std_logic_vector(3 downto 0);
  signal rd_fltn : std_logic_vector(3 downto 0);
  signal rst_fltn : std_logic_vector(7 downto 0);
  signal rgt_fltn : std_logic_vector(7 downto 0);

  signal a_fltn : std_logic;
  signal d_fltn : std_logic;
  signal st_fltn : std_logic;
  signal gt_fltn : std_logic;
  
  signal cmask   : std_logic_vector(23  downto 0);
  signal rstat   : std_logic_vector(23 downto 0);
  signal stat    : std_logic_vector(23 downto 0);
  signal reg_reset : std_logic;
  
  signal gmc_d_fltn  : std_logic_vector(3 downto 0);
  signal gmc_a_fltn  : std_logic_vector(3 downto 0);
  signal gmc_st_fltn : STD_LOGIC_VECTOR(7 downto 0);  
  signal gmc_gt_fltn : STD_LOGIC_VECTOR(7 downto 0);
  
  signal blockn : std_logic;
  
  -- F version
  --signal sdata_out : std_logic;
  signal mux_out   : std_logic;
  signal eng_mode  : std_logic;
  signal norm_reset : std_logic;
  
  signal OVP_IO_state : std_logic;
  
  
  signal istat : std_logic;
  signal iax_data_read : std_logic;
  signal iax_res : std_logic;
  signal iax_block : std_logic;
  
  signal creg : std_logic_vector(31 downto 0);
  signal iaxframecount : integer range 0 to 63;
  signal cnb : integer range 0 to 31;
 
BEGIN
  --rst_n    - from the push button
  --ax_res   - from the aux xilinx (I2C)
  --norm_res - SHDN_1 = LOW in normal mode
    
  reg_reset <= not rst_n  or iax_res or norm_reset;
   
  eng_mode  <= JMP; --active high : jumper off => engineering mode
  
  --use SHDN_1 (active low) as a reset in NORMAL mode
  norm_reset <= (not eng_mode) and (not SHDN_1);
  
  -- OVP_IO_A(5) used as a disable of 2912 (SSRs) in NORMAL mode
  --  channels are disabled individually
  -- by the cmask bits
  -- blockn = LOW keeps the genbarts and SSR active, can be set from I2C
  
  blockn    <= (not eng_mode and OVP_IO_A(5)) and (not iax_block); 
  
  --only mux in the F version (basic status output)
  OVP_IO_MUX <= mux_out;
  
  -- 0 if NOT OK:
  
  istat <= (a_fltn and d_fltn and st_fltn and gt_fltn) or eng_mode; 
  --eng_mode => do not stop pow. supply 
  --OVP_IO_STAT <= istat;
  OVP_IO_STAT_delay <= istat when en = '1' else 'Z';
  OVP_IO_STAT_delay_2 <= OVP_IO_STAT_delay when en = '1' else 'Z';  -- six stage delay
  OVP_IO_STAT_delay_3 <= OVP_IO_STAT_delay_2 when en = '1' else 'Z'; 
  OVP_IO_STAT_delay_4 <= OVP_IO_STAT_delay_3 when en = '1' else 'Z'; 
  OVP_IO_STAT_delay_5 <= OVP_IO_STAT_delay_4 when en = '1' else 'Z';
  OVP_IO_STAT_delay_6 <= OVP_IO_STAT_delay_5 when en = '1' else 'Z';

  --OVP_IO_STAT <= istat or OVP_IO_STAT_delay_6;
  OVP_IO_state <= istat or OVP_IO_STAT_delay_6;

  OVP_IO_STAT <= OVP_IO_state;


  d_fltn  <= rd_fltn(0) and rd_fltn(1) and rd_fltn(2) and rd_fltn(3);  
  a_fltn  <= ra_fltn(0) and ra_fltn(1) and ra_fltn(2) and ra_fltn(3);
  st_fltn <= rst_fltn(0) and rst_fltn(1) and rst_fltn(2) and rst_fltn(3) and
             rst_fltn(4) and rst_fltn(5) and rst_fltn(6) and rst_fltn(7);
  gt_fltn <= rgt_fltn(0) and rgt_fltn(1) and rgt_fltn(2) and rgt_fltn(3) and
             rgt_fltn(4) and rgt_fltn(5) and rgt_fltn(6) and rgt_fltn(7);      
   
            
 -- as received from the channels                                
  stat(3 downto 0)   <= mc_d_fltn;
  stat(7 downto 4)   <= mc_a_fltn;
  stat(15 downto 8)  <= mc_st_fltn;
  stat(23 downto 16) <= mc_gt_fltn;       
 -- masked, latched      
  rstat(3 downto 0)   <= rd_fltn;
  rstat(7 downto 4)   <= ra_fltn;
  rstat(15 downto 8)  <= rst_fltn;
  rstat(23 downto 16) <= rgt_fltn; 
 --                                                                                
  diodes(0) <= d_fltn;
  diodes(1) <= a_fltn;
  diodes(2) <= st_fltn;
  diodes(3) <= gt_fltn;

  --blockn = LOW keeps the genbarts and SSR active
  uc_d_shdwn <= d_fltn or not blockn ;     -- low to digital genbarts to switch them off
  uc_a_shdwn <= a_fltn or not blockn ;     -- low to analog genbarts to switch them off
                             -- if masked, then flops are not set and  genbarts are not shutdown
  uc_a_off   <= (not a_fltn ) and not reg_reset and blockn;  -- high to analog opto to switch it off
  uc_a_rstn  <= rst_n;                            --not used
  
  uc_st_offa  <= (not st_fltn ) and not reg_reset and blockn; --reg_reset high  keeps SSR OPEN
  uc_st_offb  <= (not st_fltn ) and not reg_reset and blockn;
  
  uc_gt_offa  <= (not gt_fltn ) and not reg_reset and blockn;
  uc_gt_offb  <= (not gt_fltn ) and not reg_reset and blockn;
 
 --*******************************************************************************************
 orek:process(mc_d_fltn,mc_a_fltn,mc_st_fltn,mc_gt_fltn ,cmask)
 begin
   for i in 0 to 3 LOOP
     gmc_d_fltn(i) <= mc_d_fltn(i) or cmask(i);
   end LOOP;   
   for i in 0 to 3 LOOP
     gmc_a_fltn(i) <= mc_a_fltn(i) or cmask(i+4);
   end LOOP;
   for i in 0 to 7 LOOP
     gmc_st_fltn(i) <= mc_st_fltn(i) or cmask(i+8);
   end LOOP;   
   for i in 0 to 7 LOOP
     gmc_gt_fltn(i) <= mc_gt_fltn(i) or cmask(i+16);
   end LOOP; 
 end process orek;
 --***************************************************************************** 
  reg_digital: process(reg_reset, clk)
  begin
       for i in 0 to 3 loop
          if(reg_reset = '1') then
              rd_fltn(i)  <= '1';
          elsif(clk'event and clk='0' and OVP_IO_state = '1') then
              rd_fltn(i) <= gmc_d_fltn(i);    --falling edge D-FF
          end if;    
       end loop;              
  end process reg_digital;
 --***************************************************************************** 
  reg_analog: process(reg_reset, clk)
  begin
       for i in 0 to 3 loop
         if(reg_reset = '1') then
            ra_fltn(i) <= '1';
         elsif(clk'event and clk='0' and OVP_IO_state = '1') then
            ra_fltn(i) <= gmc_a_fltn(i);    --falling edge D-FF
         end if;   
       end loop;               
  end process reg_analog;
 --*****************************************************************************  
  reg_st: process(reg_reset, clk)
  begin
       for i in 0 to 7 loop
          if(reg_reset = '1') then
              rst_fltn(i) <= '1';
          elsif(clk'event and clk='0' and OVP_IO_state = '1') then
              rst_fltn(i) <= gmc_st_fltn(i);    --falling edge D-FF
          end if;   
       end loop;            
  end process reg_st; 
 --*****************************************************************************  
  reg_gt: process(reg_reset, clk)
  begin  
       for i in 0 to 7 loop
         if(reg_reset = '1') then
            rgt_fltn(i) <= '1';
         elsif(clk'event and clk='0' and OVP_IO_state = '1') then
            rgt_fltn(i) <= gmc_gt_fltn(i);    --falling edge D-FF
         end if;   
       end loop;             
  end process reg_gt; 
 --*****************************************************************************
  rdmux:process(OVP_IO_A(4 downto 0),rstat)
  variable i : integer range 0 to 23;
  begin
    i := CONV_INTEGER(OVP_IO_A(4 downto 0));
    mux_out <= rstat(i);
  end process rdmux;
 --*****************************************************************************
 --                 F below
 --*****************************************************************************
 axframecount:process(ax_frame,ax_clk)
 begin
   if(ax_frame = '0') then
     iaxframecount <= 0;
     cnb <= 31;
   elsif(ax_clk'event and ax_clk='0') then -- negedge !!!!!
   --elsif(ax_clk'event and ax_clk='0' and cnb /= 0) then -- negedge !!!!!  --comment in for simulation
     iaxframecount <= iaxframecount + 1;
     cnb <=cnb-1;
   end if;
 end process axframecount;
 
 ax_data <= iax_data_read;
 --ax_res <= not rst_n;
 
 pumpomux:process(ax_write,iaxframecount, istat,stat,creg)
 begin
    if(ax_write = '0') then -- dana jest przed ax_frame....
      case iaxframecount is
        when 0 to 7 => 
           iax_data_read <=  istat; 
        when 8 to 31 =>
          --BYYYK !!!!!!!!!! odwrotnie mialo byc (S bit)
          if(creg(24) = '0') then
           iax_data_read <=  rstat(cnb) ;
          else
           iax_data_read <=   stat(cnb);
        end if; 
        when 32 to 63 =>
           iax_data_read <=  creg(cnb);
        end case;
   end if;             
 end process pumpomux;
 
--***************************************************************************** 
  pumpin:process(ax_frame,ax_write,ax_clk)
 begin
   if(ax_frame = '0' or ax_write = '0') then
      cmask(23 downto 0) <= creg(23 downto 0);
      iax_res   <= creg(31);    
      iax_block <= creg(30);
   elsif(ax_clk'event and ax_clk='0') then -- negedge !!!!!
      creg(cnb) <= ax_data_in;
   end if;  
end process pumpin;     
--***************************************************************************** 
  
END ARCHITECTURE arch;

