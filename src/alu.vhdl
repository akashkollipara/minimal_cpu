entity alu is
	port(
		aluc		: in bit_vector (3 downto 0);
		en		: in bit;
		rs, rt		: in bit_vector (31 downto 0);
		z, ov, c	: out bit;
		dout		: out bit_vector (31 downto 0)
	    );
end entity;

architecture behavioral of alu is
	signal ol_or, ol_nor, ol_and, ol_nand	: bit_vector (31 downto 0);
	signal ol_xor, ol_lui, oa_add, ob_shift	: bit_vector (31 downto 0);
	signal sh_cnt, sh_op, add_sub		: bit;

	component logic_mix is
		port(
			a, b            : in bit_vector (31 downto 0);
			o_and, o_or     : out bit_vector (31 downto 0);
			o_xor, o_lui    : out bit_vector (31 downto 0);
			o_nor, o_nand   : out bit_vector (31 downto 0)
		    );
	end component;

	component barrel_shifter is
		port(
			a, b    : in bit_vector (31 downto 0);
			cntr    : in bit;
			opr     : in bit;
			y       : out bit_vector (31 downto 0)
		    );
	end component;

	component cl_adder_32b is
		port(
			a, b    : in bit_vector (31 downto 0);
			sub     : in bit;
			s       : out bit_vector (31 downto 0);
			z, c, ov: out bit
		    );
	end component;
begin
	alu_logic: logic_mix port map(
						a => rs,
						b => rt,
						o_and => ol_and,
						o_or => ol_or,
						o_nand => ol_nand,
						o_nor => ol_nor,
						o_xor => ol_xor,
						o_lui => ol_lui
				     );

	alu_shift: barrel_shifter port map(
						a => rs,
						b => rt,
						cntr => sh_cnt,
						opr => sh_op,
						y => ob_shift
					  );

	alu_adder: cl_adder_32b port map(
						a => rs,
						b => rt,
						sub => add_sub,
						s => oa_add,
						z => z,
						c => c,
						ov => ov
					);

	process(en, aluc, rs, rt)
	begin
		case aluc is
			when "0000" =>		-- add
				add_sub <= '0';
				dout <= oa_add;
			when "0001" =>		-- sub
				add_sub <= '1';
				dout <= oa_add;
			when "0010" =>		-- or
				dout <= ol_or;
			when "0011" =>		-- nor
				dout <= ol_nor;
			when "0100" =>		-- and
				dout <= ol_and;
			when "0101" =>		-- nand
				dout <= ol_nand;
			when "0110" =>		-- xor
				dout <= ol_xor;
			when "0111" =>		-- lui
				dout <= ol_lui;
			when "1000" =>		-- sll
				sh_cnt <= '0';
				dout <= ob_shift;
			when "1001" =>		-- srl
				sh_cnt <= '1';
				sh_op <= '0';
				dout <= ob_shift;
			when "1010" =>		-- sra
				sh_cnt <= '1';
				sh_op <= '1';
				dout <= ob_shift;
			when others =>
				sh_cnt <= '0';
				sh_op <= '0';
				add_sub <= '0';
				dout <= (others => '0');
		end case;
	end process;
end behavioral;

entity alu_controller is
	port(
		aluop	: in bit_vector(5 downto 0);
		en	: in bit;
		alu_en	: out bit;
		aluc	: out bit_vector(3 downto 0)
	    );
end entity;

architecture behavioral of alu_controller is
begin
	process(aluop, en)
	begin
		case aluop(5 downto 4) is
			when "00" =>			-- I Type instruction
				if(aluop(1) = '1') then
					aluc <= "0000";
					alu_en <= en;
				else
					alu_en <= '0';	-- nop instruction
				end if;
			when "10" =>			-- R type instruction
				aluc <= aluop(3 downto 0);
				alu_en <= en;
			when "01" =>			-- beq instruction using I format
				aluc <= "0001";
				alu_en <= en;
			when "11" =>			-- J type instruction
				aluc <= "0000";
				alu_en <= '1';
		end case;
	end process;
end behavioral;

entity alu_tb is
end entity;

architecture test of alu_tb is
	signal aluc	: bit_vector (3 downto 0);
	signal dout	: bit_vector (31 downto 0);
	signal rs, rt	: bit_vector (31 downto 0);
	signal en	: bit;
	component alu is
		port(
			aluc		: in bit_vector (3 downto 0);
			en		: in bit;
			rs, rt		: in bit_vector (31 downto 0);
			z, ov, c	: out bit;
			dout		: out bit_vector (31 downto 0)
		    );
	end component;
	constant delay : time := 100 ps;

begin
	alu_test : alu port map(
					aluc => aluc,
					en => en,
					rs => rs,
					rt => rt,
					dout => dout
			       );
	test: process
	begin
		rs(0) <= '1';
		rt(1 downto 0) <= "11";
		en <= '0';
		aluc <= "0000";
		wait for delay;
		en <= '1';
		wait for delay;
		en <= '0';
		aluc <= "0001";
		wait for delay;
		en <= '1';
		wait for delay;
		wait;
	end process;
end test;

