library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HDMI_TX is
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
end HDMI_TX;

architecture behavioral of HDMI_TX is

	component pll
		PORT
		(
			areset		: IN STD_LOGIC  := '0';
			inclk0		: IN STD_LOGIC  := '0';
			c0			: OUT STD_LOGIC 
		);
	end component;
	
	-- 1920x1080p60 148.5MHZ 	
	constant h_total: 	integer := 2199;
	constant h_sync: 	integer := 43;
	constant h_start: 	integer := 189;
	constant h_end: 	integer := 2109;
	constant v_total: 	integer := 1124;
	constant v_sync: 	integer := 4;
	constant v_start: 	integer := 40;
	constant v_end: 	integer := 1120;
	
	-- 1024x768@60 65MHZ (XGA)
	--	constant h_total: 	integer := 1343;
	--	constant h_sync: 	integer := 135;
	--	constant h_start: 	integer := 293;
	--	constant h_end: 	integer := 1317;
	--	constant v_total: 	integer := 805;
	--	constant v_sync: 	integer := 5;
	--	constant v_start: 	integer := 34;
	--	constant v_end: 	integer := 802;

	signal h_count: 	integer := 0;
	signal v_count: 	integer := 0;
	
	signal h_act:		std_logic := '0';
	signal v_act:		std_logic := '0';

	signal h_max, hs_end, hr_start, hr_end: std_logic;
	signal v_max, vs_end, vr_start, vr_end: std_logic;
	
	signal pixel_clk:	std_logic;
	
	-- RAM 
	signal h_px_count: 	integer := 0;
	signal v_px_count: 	integer := 0;
	signal h_addr: 		integer := 0;
	signal v_addr: 		integer := 0;
	signal addr:		std_logic_vector(15 DOWNTO 0);
begin

	pixel_pll: pll 
		port map (
			areset => not rst_n,
			inclk0 => clk,
			c0 => pixel_clk
		);

	pclk_out 	<= not pixel_clk;
		
	h_max 		<= '1' when h_count  = h_total 	else '0';
	hs_end 		<= '1' when h_count >= h_sync 	else '0';
	hr_start 	<= '1' when h_count  = h_start 	else '0';
	hr_end 		<= '1' when h_count  = h_end 	else '0';
	
	v_max 		<= '1' when v_count  = v_total 	else '0';
	vs_end 		<= '1' when v_count >= v_sync 	else '0';
	vr_start 	<= '1' when v_count  = v_start 	else '0';
	vr_end 		<= '1' when v_count  = v_end 	else '0';

	
	horizontal_ctrl: process (pixel_clk)
	begin
		if rising_edge(pixel_clk) then
			if rst_n = '0' then
				h_count <= 0;
				h_act <= '0';
			else

				-- Check if we reached the end of the screen
				if h_max = '1' then
					h_count <= 0;
				else
					h_count <= h_count + 1;
				end if;	

				-- We are in the active zone
				if hr_start = '1' then
					h_act <= '1';
				elsif hr_end = '1' then
					h_act <= '0';
				end if;

				-- horizontal sync
				if hs_end = '1' then
					hs <= '1';
				else
					hs <= '0';
				end if;	

			end if;
		end if;
	end process;


	vertical_ctrl: process (pixel_clk)
	begin
		if rising_edge(pixel_clk) then
			if rst_n = '0' then
				v_count <= 0;
				v_act <= '0';
			else

				-- Check if we reached the end of the screen
				if h_max = '1' then
					if v_max = '1' then
						v_count <= 0;
					else
						v_count <= v_count + 1;
					end if;	
				end if ;

				-- We are in the active zone
				if vr_start = '1' then
					v_act <= '1';
				elsif vr_end = '1' then
					v_act <= '0';
				end if;

				-- vertical sync
				if vs_end = '1' then
					vs <= '1';
				else
					vs <= '0';
				end if;	

			end if;
		end if;
	end process;

	signal_gen: process(pixel_clk)
	begin
		if falling_edge(pixel_clk) then
			if v_act = '1' and h_act = '1' then
				de <= '1';
				
				if h_px_count = 5 then
					h_px_count <= 0;
					h_addr <= h_addr + 1;
				else
					h_px_count <= h_px_count + 1;
				end if;

			else
				de <= '0';
			end if;
				
			if h_max = '1' and v_act = '1' then
				if v_px_count = 5 then
					v_px_count <= 0;
					v_addr <= v_addr + 1;
				else
					v_px_count <= v_px_count + 1;
				end if;
			end if;

			if v_max = '1' then
				v_addr <= 0;
			end if;

			if h_max = '1' then
				h_addr <= 0;
			end if;

			ram_addr <= std_logic_vector(to_unsigned(v_addr * 320 + h_addr, addr'length));
			
			
			r <= ram_data(17 downto 12) & b"00";
			g <= ram_data(11 downto 6) & b"00";
			b <= ram_data(5 downto 0) & b"00";

		end if;
	end process;



end behavioral ; -- behavioral