-- Testbench for the main CPLD containing the control logic
-- 
-- PA 2023

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-- empty entity
entity ftop144_prod_F_tb is
end entity ftop144_prod_F_tb;

architecture arch of ftop144_prod_F_tb is

  -- module declaration
  component ftop144_prod_F is
    port (
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
    
    uc_gt_offa : OUT STD_LOGIC;  -- off for gt 2912
    uc_gt_offb : OUT STD_LOGIC;  -- off for gt 2912
    uc_st_offa : OUT STD_LOGIC;  -- off for st 2912
    uc_st_offb : OUT STD_LOGIC;  -- off for st 2912
    
    -- ax_res       : OUT STD_LOGIC;  -- betw(0)
    ax_clk       : IN STD_LOGIC;   -- betw(1)
    ax_frame     : IN STD_LOGIC;   -- betw(2)
    ax_data      : OUT STD_LOGIC;  -- betw(3)
    ax_write     : IN STD_LOGIC;   -- betw(4)
    ax_data_in   : IN STD_LOGIC;   -- betw(5)  

    clk          : IN STD_LOGIC;   -- clock for flipflop  

    OVP_IO_STAT_delay 	: INOUT STD_LOGIC;   -- delay of output signal
	  OVP_IO_STAT_delay_2 : INOUT STD_LOGIC;   -- delay of output signal
	  OVP_IO_STAT_delay_3 : INOUT STD_LOGIC;   -- delay of output signal
	  OVP_IO_STAT_delay_4 : INOUT STD_LOGIC;   -- delay of output signal
	  OVP_IO_STAT_delay_5 : INOUT STD_LOGIC;   -- delay of output signal
	  OVP_IO_STAT_delay_6 : INOUT STD_LOGIC;   -- delay of output signal
    en                	: IN STD_LOGIC       -- enable tri-state buffer
    );
  end component;

  -- input
  signal clk   : std_logic := '0';
  signal ax_clk : std_logic := '0'; 
  signal rst_n, JMP, SHDN_1, SHDN_2 : std_logic;
  signal ax_write : std_logic := '1';
  signal ax_frame : std_logic := '0';
  signal ax_data_in : std_logic;
  signal mc_d_fltn, mc_a_fltn : std_logic_vector(3 downto 0);
  signal mc_st_fltn, mc_gt_fltn : std_logic_vector(7 downto 0);
  signal OVP_IO_A : std_logic_vector(5 downto 0) := "000000";

  -- output
  signal diodes : std_logic_vector(3 downto 0);
  signal OVP_IO_MUX, OVP_IO_STAT : std_logic;
  signal OVP_IO_STAT_delay, OVP_IO_STAT_delay_2, OVP_IO_STAT_delay_3 : std_logic;
  signal OVP_IO_STAT_delay_4, OVP_IO_STAT_delay_5, OVP_IO_STAT_delay_6 : std_logic;
  signal uc_a_rstn, uc_a_shdwn, uc_a_off, uc_d_shdwn : std_logic;
  signal uc_gt_offa, uc_gt_offb, uc_st_offa, uc_st_offb : std_logic;
  signal ax_data : std_logic;

  signal i : integer range 0 to 33 := 0; 
  signal data_reg : std_logic_vector(32-1 downto 0) := "00000000000000000000000011111100";
  signal finished : std_logic;
  signal en       : std_logic;
  constant delay  : time := 250 ns;



begin
  clk   <= not clk  after 10.4 ns;  -- 48 MHz clock

  --ax_clk <= not ax_clk after 10.4 ns when finished /= '1' else '1';
  ax_clk <= not ax_clk after 0.5 ns when finished /= '1' else '1';
  
  -- active high : jumper off => engineering mode
  JMP <= '0';

  -- reset signals
  --SHDN_2 <= '0';
  --SHDN_1 <= '1';
  SHDN_1<= '1', '0' after 900 ns, '1' after 950 ns;
  -- delay with tri-state buffer
  en <= '1';

  -- read in data
  process 
  begin
    wait until rising_edge(ax_clk);
      if (i <= 31) then
        finished <= '0';
        ax_frame <= '1';
        ax_data_in <= data_reg(i);
        i <= i+1;
      else
        ax_write <= '0';
        finished <= '1';
      end if;
  end process;

  
  rst_n <= '0', '1' after 100 ns; -- produces reset

  mc_d_fltn <= "1111";
  mc_a_fltn <= "1111", "1101" after 510 ns, "1111" after 500 ns+delay; --Channel fault in analog domain
  mc_gt_fltn <= "11111111";
  mc_st_fltn <= "11111111";



  -- module input
  dut : ftop144_prod_F
    port map (
    mc_d_fltn  => mc_d_fltn,
    mc_a_fltn  => mc_a_fltn,
    mc_st_fltn => mc_st_fltn,  
    mc_gt_fltn => mc_gt_fltn,
    
    --SHDN_2 => SHDN_2,
    SHDN_1 => SHDN_1,
    
    rst_n  => rst_n,
    JMP    => JMP,
    diodes => diodes,
    OVP_IO_MUX => OVP_IO_MUX,
    OVP_IO_STAT => OVP_IO_STAT,
    OVP_IO_A => OVP_IO_A,
  
    uc_a_rstn  => uc_a_rstn,
    uc_a_shdwn => uc_a_shdwn, 
    uc_a_off   => uc_a_off, 
    
    uc_d_shdwn => uc_d_shdwn, 
    
    uc_gt_offa => uc_gt_offa,
    uc_gt_offb => uc_gt_offb, 
    uc_st_offa => uc_st_offa, 
    uc_st_offb => uc_st_offb,  
    
   -- ax_res     => ax_res,  
    ax_clk     => ax_clk,  
    ax_frame   => ax_frame,  
    ax_data    => ax_data,
    ax_write   => ax_write,  
    ax_data_in => ax_data_in,  

    clk => clk,

    OVP_IO_STAT_delay => OVP_IO_STAT_delay,
	 OVP_IO_STAT_delay_2 => OVP_IO_STAT_delay_2,
	 OVP_IO_STAT_delay_3 => OVP_IO_STAT_delay_3,
	 OVP_IO_STAT_delay_4 => OVP_IO_STAT_delay_4,
	 OVP_IO_STAT_delay_5 => OVP_IO_STAT_delay_5,
	 OVP_IO_STAT_delay_6 => OVP_IO_STAT_delay_6,
    en                => en
      );

end architecture;