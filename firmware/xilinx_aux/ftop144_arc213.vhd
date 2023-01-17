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
LIBRARY xtovprot_lib;
USE xtovprot_lib.All;

ENTITY ftop144_aux_F IS
 PORT(
    SCL_TX_A  : OUT  STD_LOGIC; --to optocoupler
    SCL_TX_B  : OUT  STD_LOGIC; --to optocoupler
    SDA_TX_A  : OUT  STD_LOGIC; --to optocoupler
    SDA_TX_B  : OUT  STD_LOGIC; --to optocoupler
    
    SDA_RX_A  : IN   STD_LOGIC; --from optocoupler
    SDA_RX_B  : IN   STD_LOGIC; --from optocoupler
    
    SDA_TX    : IN   STD_LOGIC; --from P82B96, opencol !!!!
    SDA_RX    : OUT  STD_LOGIC; --to P82B96
    
    SCL_TX    : IN   STD_LOGIC; --from P82B96, opencol !!!!
    SCL_RX_DUM: OUT  STD_LOGIC; --to   P82B96
    
    clk48     : IN   STD_LOGIC;
    
    ax_res       : IN STD_LOGIC;  -- betw(0)
    ax_clk       : OUT STD_LOGIC;  -- betw(1)
    ax_frame     : OUT STD_LOGIC;  -- betw(2)
    ax_data      : IN  STD_LOGIC;  -- betw(3);
    ax_write     : OUT STD_LOGIC;  -- betw(4)
    ax_dout      : OUT STD_LOGIC;  -- betw(5) 
    
    op           : OUT STD_LOGIC_VECTOR(4 downto 0)  --jumpers 
  ); 
  
END ENTITY ftop144_aux_F;

--
ARCHITECTURE arch OF ftop144_aux_F IS

signal sclk : STD_LOGIC;  
signal iop : STD_LOGIC_VECTOR(4 downto 0);
signal wstat : STD_LOGIC_VECTOR(23 downto 0);
signal istat : STD_LOGIC_VECTOR(23 downto 0);
signal iax_frame ,iax_clk, iax_write, iax_dout: std_logic;
signal pk_sread , pk_swrite: std_logic;
signal curr_add : std_logic_vector(7 downto 0);
signal pk_rd, pk_wr , pk_serial: std_logic;
signal pk_sdata_wr : std_logic;
signal SDA_RX_i : std_logic;

SIGNAL clk    : std_logic;
SIGNAL sda    : std_logic;
SIGNAL scl    : std_logic;
SIGNAL myReg0 : std_logic_vector(7 DOWNTO 0);
SIGNAL myReg1 : std_logic_vector(7 DOWNTO 0);
SIGNAL myReg2 : std_logic_vector(7 DOWNTO 0);
SIGNAL myReg3 : std_logic_vector(7 DOWNTO 0);
SIGNAL myReg4 : std_logic_vector(7 DOWNTO 0);
SIGNAL myReg5 : std_logic_vector(7 DOWNTO 0);
SIGNAL myReg6 : std_logic_vector(7 DOWNTO 0);
SIGNAL myReg7 : std_logic_vector(7 DOWNTO 0);

signal gate_domain_on : std_logic;
signal prog_on : std_logic;


COMPONENT i2cSlave
   PORT (
      clk    : IN     std_logic;
      rst    : IN     std_logic;
      sdaIn  : IN     std_logic;
      sdaOut : OUT    std_logic;
      scl    : IN     std_logic;
      myReg0 : OUT    std_logic_vector(7 DOWNTO 0);
      myReg1 : OUT    std_logic_vector(7 DOWNTO 0);
      myReg2 : OUT    std_logic_vector(7 DOWNTO 0);
      myReg3 : OUT    std_logic_vector(7 DOWNTO 0);
      myReg4 : IN     std_logic_vector(7 DOWNTO 0);
      myReg5 : IN     std_logic_vector(7 DOWNTO 0);
      myReg6 : IN     std_logic_vector(7 DOWNTO 0);
      myReg7 : IN     std_logic_vector(7 DOWNTO 0);
      pk_sread : OUT  std_logic;  --pk,  clock gate
      pk_swrite: OUT  std_logic;  -- pk, clock gate
      curr_add : OUT  std_logic_vector(7 downto 0); --pk
      pk_rd    : OUT std_logic; --pk
      pk_wr    : OUT std_logic;  --pk
      pk_sdata : IN  std_logic; --pk
      pk_sdata_wr: OUT std_logic; --pk
      pk_serial: IN  std_logic  --pk
   );
END COMPONENT i2cSlave;
FOR ALL : i2cSlave USE ENTITY xtovprot_lib.i2cSlave;

BEGIN

   --  hds hds_inst
  ovproti2c : i2cSlave
      PORT MAP (
         clk    => clk48,
         rst    => ax_res, 
         sdaIn  => SDA_TX,
         sdaOut => SDA_RX_i,
         scl    => SCL_TX,
         myReg0 => myReg0,
         myReg1 => myReg1,
         myReg2 => myReg2,
         myReg3 => myReg3,
         myReg4 => myReg4,
         myReg5 => myReg5,
         myReg6 => myReg6,
         myReg7 => myReg7,
         pk_sread => pk_sread,  --pk
         pk_swrite => pk_swrite, --pk
         curr_add => curr_add, --pk
         pk_rd => pk_rd, --pk
         pk_wr => pk_wr, --pk
         pk_sdata => ax_data, --pk
         pk_sdata_wr => pk_sdata_wr, --pk
         pk_serial => pk_serial --pk
         
      );
      
clk <= clk48;     
myReg4 <= istat(7 downto 0);
myReg5 <= istat(15 downto 8);
myReg6 <= istat(23 downto 16);
myReg7 <= X"00";
    
SCL_TX_A <= SCL_TX when gate_domain_on = '0' else '1';
SCL_TX_B <= '1'    when gate_domain_on = '0' else SCL_TX;     

SDA_TX_A <= SDA_TX when gate_domain_on = '0' else '1';
SDA_TX_B <= '1'    when gate_domain_on  = '0' else SDA_TX;

SDA_RX <= ((SDA_RX_A and not gate_domain_on) or 
          (SDA_RX_B and gate_domain_on) or not prog_on)   and SDA_RX_i;

SCL_RX_DUM <= '1';

gate_domain_on <= myReg0(2);
prog_on <= myReg0(3);

--************************************************************************************************
--ssak:process(clk)
--variable count : std_logic_vector(4 downto 0);

--begin
--  if(clk'event and clk = '1') then
--    if(count(4 downto 0) = "11") then 
--         iax_frame <= '0';
--    else
--         iax_frame <= '1';
--         if(iax_frame = '1') then
--               istat(23 downto 1) <= istat(22 downto 0);
--               istat(0) <= ax_data;
--         end if;
--         count := count + "00001";
--    end if; 
-- end if;        
--end process ssak;
--************************************************************************************************
--bolo:process(clk)
--begin
--if(clk'event and clk='1') then
--   iop(4 downto 0) <= iop(4 downto 0) + "00001";
-- end if;
--end process bolo;
--************************************************************************************************
--sclk <= iop(4);
ax_frame <= iax_frame;
ax_write <=iax_write;
ax_clk   <= iax_clk;
ax_dout <= iax_dout;

op(0) <= iax_frame;
op(1) <= iax_clk;
op(3) <= pk_swrite;
--op(4) <= pk_wr;
op(4) <=  gate_domain_on;

bolo:process(pk_sread,pk_swrite,curr_add,SCL_TX,pk_rd,pk_wr)
begin
  if(pk_rd = '1') then   
   if(curr_add = "00000000" or
     curr_add =  "00000001" or
     curr_add =  "00000010" or
     curr_add =  "00000011" or
     curr_add =  "00000100" or
     curr_add =  "00000101" or
     curr_add =  "00000110" or
     curr_add =  "00000111" or
     curr_add =  "00001000"
     ) then
     pk_serial <= '1';
     iax_frame <= '1';
     iax_clk <= SCL_TX and pk_sread; 
   else
    pk_serial <= '0';
    iax_frame <= '0';
    iax_clk <= '0';
   end if;
  elsif(pk_wr = '1') then 
   if(curr_add = "00000100" or
      curr_add = "00000101" or
      curr_add = "00000110" or
      curr_add = "00000111" ) then
      pk_serial <= '1';
      iax_frame <= '1';
      iax_write <= '1';
      iax_clk <= SCL_TX and pk_swrite;
      iax_dout <= SDA_TX;
   else
      pk_serial <= '0';
      iax_frame <= '0';
      iax_write <= '0';
      iax_clk <= '0';
      iax_dout <= '0';
   end if;       
  else
    iax_write <= '0';
  end if;         
end process bolo;

END ARCHITECTURE arch;

