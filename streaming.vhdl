library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ethernet_pkg.all;

entity streaming is
	port (
		--  CLOCK 
		ADC_CLK_10: 	in std_logic;
		MAX10_CLK1_50: 	in std_logic;
		MAX10_CLK2_50: 	in std_logic;

		--  KEY 
		KEY: 			in std_logic_vector(1 downto 0);

		--  LED 
		LED: 			out 	std_logic_vector(7 downto 0) := b"11111111";

		--  HDMI-TX 
		HDMI_I2C_SCL:	inout std_logic;
		HDMI_I2C_SDA:	inout std_logic;
		HDMI_I2S:		inout std_logic_vector(3 downto 0);
		HDMI_LRCLK:		inout std_logic;
		HDMI_MCLK:		inout std_logic;
		HDMI_SCLK:		inout std_logic;
		HDMI_TX_CLK:	out std_logic;
		HDMI_TX_D:		out std_logic_vector(23 downto 0);
		HDMI_TX_DE:		out std_logic;
		HDMI_TX_HS:		out std_logic;
		HDMI_TX_INT:	in std_logic;
		HDMI_TX_VS:		out std_logic;

		--  Ethernet 
		NET_COL:		in		std_logic := '0';
		NET_CRS:		in 		std_logic := '0';
		NET_MDC:		out 	std_logic := '0';
		NET_MDIO:		inout 	std_logic := '0';
		NET_PCF_EN:		out 	std_logic := '0';
		NET_RESET_n:	out 	std_logic := '0';
		NET_RX_CLK:		in 		std_logic := '0';
		NET_RX_DV:		in 		std_logic := '0';
		NET_RX_ER:		in 		std_logic := '0';
		NET_RXD:		in 		std_logic_vector(3 downto 0);
		NET_TX_CLK:		in 		std_logic := '0';
		NET_TX_EN:		out 	std_logic := '0';
		NET_TXD:		out 	std_logic_vector(3 downto 0) := x"0";

		--  SW 
		SW: 			in 		std_logic_vector(1 downto 0)
	);

end streaming;

architecture behavioral of streaming is

	component ethernet
		generic (
			PACKET_DATA_SIZE: 		integer := 100;
			MAC_SOURCE: 			std_logic_vector(47 downto 0) := x"001122334455";
			MAC_DESTINATION: 		std_logic_vector(47 downto 0) := x"00D86119493B"
		);
		port (
			eth_rst_n:		in 		std_logic := '0';
			
			rx_clk:			in 		std_logic := '0';
			rx_dv:			in 		std_logic := '0';
			rxd:			in 		std_logic_vector(3 downto 0);
			rx_fifo_en:		in	 	std_logic;
			rx_fifo_dout: 	out		std_logic_vector(3 downto 0);
			rx_pkt_rdy:		out 	std_logic;
			fifo_pout:		out		std_logic_vector(8*PACKET_DATA_SIZE-1 downto 0);
			fifo_clr:		in		std_logic := '0'
		);
	end component;

	component HDMI_TX
		port (
			clk: 		in 		std_logic;
			rst_n: 		in 		std_logic;
			pclk_out: 	out		std_logic;
			de:			out		std_logic;
			hs:			out		std_logic;
			vs:			out		std_logic;
			r:			out		std_logic_vector(7 downto 0);
			g:			out		std_logic_vector(7 downto 0);
			b:			out		std_logic_vector(7 downto 0);
			
			ram_addr:	out		std_logic_vector(15 DOWNTO 0);
			ram_data:	in		std_logic_vector(17 DOWNTO 0)
		);
	end component;
	
	component I2C_HDMI_Config
		port (
			iCLK:		in		std_logic;
			iRST_N:		in		std_logic;
			I2C_SCLK:	out		std_logic;
			I2C_SDAT:	inout	std_logic;
			HDMI_TX_INT:in		std_logic
		);
	end component;
	
	component ram
		PORT
		(
			data		: IN STD_LOGIC_VECTOR (17 DOWNTO 0);
			rdaddress	: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			rdclock		: IN STD_LOGIC ;
			wraddress	: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
			wrclock		: IN STD_LOGIC  := '1';
			wren		: IN STD_LOGIC  := '0';
			q			: OUT STD_LOGIC_VECTOR (17 DOWNTO 0)
		);
	end component;
	
	
	constant ETHERNET_DATA_SIZE: integer := 1500;
	
	
	signal reset_n:		std_logic;
	
	signal ram_wen: 	std_logic;
	signal ram_raddr: 	std_logic_vector(15 DOWNTO 0) := (others => '0');
	signal ram_waddr: 	std_logic_vector(15 DOWNTO 0) := (others => '0');
	signal ram_dout: 	std_logic_vector(17 DOWNTO 0) := (others => '0');
	signal ram_din: 	std_logic_vector(17 DOWNTO 0) := (others => '0');
	
	signal packet:		std_logic_vector(ETHERNET_DATA_SIZE*8-1 downto 0);
	signal packet_rdy:	std_logic_vector(ETHERNET_DATA_SIZE*8-1 downto 0);
	signal fifo_en:		std_logic;
	signal fifo_dout:	std_logic_vector(3 downto 0);
	signal pkt_rdy:		std_logic;
	
	-- FSM Loading data in ram
	type t_STATE is (IDLE, LOAD);
	signal state: 				t_STATE := IDLE;
	signal next_state: 			t_STATE := IDLE;
	signal counter:				integer := 0;
	
	signal pixel_clk:	std_logic;
	
	signal fifo_clr:	std_logic := '0';
	
begin

	reset_n <= KEY(1);
	LED <= x"ff";

	hdmi_conf: I2C_HDMI_Config 
		port map (
			iCLK => MAX10_CLK2_50,
			iRST_N => reset_n,		
			I2C_SCLK => HDMI_I2C_SCL,
			I2C_SDAT => HDMI_I2C_SDA,
			HDMI_TX_INT => HDMI_TX_INT
		);

	HDMI_TX_CLK <= pixel_clk;
		
	hdmi: HDMI_TX 
		port map (
			clk => MAX10_CLK2_50,
			rst_n => reset_n,
			pclk_out => pixel_clk,
			de => HDMI_TX_DE,
			hs => HDMI_TX_HS,
			vs => HDMI_TX_VS,
			r => HDMI_TX_D(23 downto 16),
			g => HDMI_TX_D(15 downto 8),
			b => HDMI_TX_D(7 downto 0),
			
			ram_addr => ram_raddr,
			ram_data => ram_dout
		);
		
	image_ram: ram
		port map (
			rdclock => pixel_clk,
			wrclock => MAX10_CLK2_50,
			data => ram_din,
			rdaddress => ram_raddr,
			wraddress => ram_waddr,
			wren => ram_wen,
			q => ram_dout
		);

	
	NET_RESET_n <= reset_n;
	eth1: ethernet
		generic map (
			PACKET_DATA_SIZE => ETHERNET_DATA_SIZE
		)
		port map (
			eth_rst_n => reset_n,
			
			rx_clk => NET_RX_CLK,
			rx_dv => NET_RX_DV,
			rxd => NET_RXD,
			rx_fifo_en => fifo_en,
			rx_fifo_dout => fifo_dout,
			rx_pkt_rdy => pkt_rdy,
			fifo_pout => packet,
			fifo_clr => fifo_clr
		);
		
		
	state <= next_state;

	load_ram: process(NET_RX_CLK)
	begin
		if rising_edge(NET_RX_CLK) then
			if reset_n = '0' then
				next_state <= IDLE;
				counter <= 0; 
				ram_waddr <= (others => '0');
			else
			
				if unsigned(ram_waddr) >= 320*180-1 then
					ram_waddr <= (others => '0');
				end if;
			
				case (state) is 
				
					when IDLE =>
						counter <= 0;
						ram_wen <= '0';
						
						if pkt_rdy = '1' then
							next_state <= LOAD;
							ram_wen <= '1';
							
							-- shift packet
							packet_rdy <= packet(ETHERNET_DATA_SIZE*8-25 downto 0) & x"000000";
							-- get data
							ram_din(17 downto 0) <= packet(ETHERNET_DATA_SIZE*8-1 downto ETHERNET_DATA_SIZE*8-6) & packet(ETHERNET_DATA_SIZE*8-9 downto ETHERNET_DATA_SIZE*8-14) & packet(ETHERNET_DATA_SIZE*8-17 downto ETHERNET_DATA_SIZE*8-22);
						else
							next_state <= IDLE;
						end if;
						
					when LOAD =>
						if counter = ETHERNET_DATA_SIZE/3-1 then
							next_state <= IDLE;
							ram_wen <= '0';
							fifo_clr <= '0';
						else
							counter <= counter + 1;
							fifo_clr <= '1';
						end if;
						
						ram_waddr <= std_logic_vector(unsigned(ram_waddr) + 1);
						
						
						ram_din(17 downto 0) <= packet_rdy(ETHERNET_DATA_SIZE*8-1 downto ETHERNET_DATA_SIZE*8-6) & packet_rdy(ETHERNET_DATA_SIZE*8-9 downto ETHERNET_DATA_SIZE*8-14) & packet_rdy(ETHERNET_DATA_SIZE*8-17 downto ETHERNET_DATA_SIZE*8-22);
						packet_rdy <= packet_rdy(ETHERNET_DATA_SIZE*8-25 downto 0) & x"000000";
				end case;
			
			end if;
		end if;
	end process;

end behavioral;



























