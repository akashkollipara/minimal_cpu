entity engine is
end engine;

architecture behavioral of engine is
	signal clk, we, cpu_en, we1	: bit;
	signal ao, di, do, do1		: bit_vector (31 downto 0);
	signal delay			: time := 100 ps;

	component cpu_minimal is
		port(
			clk		: in bit;
			en		: in bit;
			addr_out	: out bit_vector (31 downto 0);
			din		: in bit_vector (31 downto 0);
			we		: out bit;
			dout		: out bit_vector (31 downto 0)
		    );
	end component;

	component ram is
		port(
			addr		: in bit_vector (31 downto 0);
			din		: in bit_vector (31 downto 0);
			clk, en		: in bit;
			dout		: out bit_vector (31 downto 0)
		    );
	end component;

begin
	cpu: cpu_minimal port map(
					en => cpu_en,
					clk => clk,
					addr_out => ao,
					din => di,
					we => we,
					dout => do
				 );
	mem: ram port map(
				addr => ao,
				din => do1,
				clk => clk,
				en => we1,
				dout => di
			 );

	test: process
	begin
		cpu_en <= '0';
		we1 <= '1';
		ao(3 downto 0) <= "0000";
		do1 <= "10000000010000110000100000000000";	-- add r1, r2, r3 -> r1 = r2 + r3
		clk <= '1';
		wait for delay;
		clk <= '0';
		wait for delay;
		ao(3 downto 0) <= "0100";
		do1 <= "00001000010000010000000000010100";	-- ld r1, 20(r2)
		clk <= '1';
		wait for delay;
		clk <= '0';
		wait for delay;
		ao(3 downto 0) <= "1000";
		do1 <= "00001100010000010000000000010100";	-- sw r1, 20(r2)
		clk <= '1';
		wait for delay;
		clk <= '0';
		wait for delay;
		ao(3 downto 0) <= "1100";
		do1 <= "10001100010000110000100000000000";	-- nor r1, r2, r3
		clk <= '1';
		wait for delay;
		clk <= '0';
		wait for delay;
		ao(4 downto 0) <= "10000";
		do1 <= "01000000001000100000000000000101";	-- beq r1, r2, 5
		clk <= '1';
		wait for delay;
		clk <= '0';
		wait for delay;
		ao(4 downto 0) <= "10100";
		do1 <= "00000000000000000000000000000000";	-- nop
		clk <= '1';
		wait for delay;
		clk <= '0';
		wait for delay;
		-- Start cpu
		cpu_en <= '1';
		do1 <= do;
		we1 <= we;
		for i in 0 to 30 loop
			clk <= '1';
			wait for delay;
			clk <= '0';
			wait for delay;
		end loop;
	end process;
end behavioral;
