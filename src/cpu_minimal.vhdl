entity cpu_minimal is
	port(
		en		: in bit;
		clk		: in bit;
		addr_out	: out bit_vector (31 downto 0);
		din		: in bit_vector (31 downto 0);
		we		: out bit;
		dout		: out bit_vector (31 downto 0)
	    );
end entity;

architecture behavioral of cpu_minimal is
	signal pcw, pcwc, ir, pc_upd, z, c, ov		: bit;
	signal regw, rs_src, reg_dst			: bit;
	signal reg_mem, i_d, alu_en, a_en		: bit;
	signal pc_src, rt_src				: bit_vector (1 downto 0);
	signal pc_bus, pc_out, rega_out, rmux2_out	: bit_vector (31 downto 0);
	signal regb_out, rega_in, regb_in, alu_reg_out	: bit_vector (31 downto 0);
	signal mdr_out, alu_out, alu_rs, alu_rt		: bit_vector (31 downto 0);
	signal f0, op					: bit_vector (5 downto 0);
	signal f1, f2, f3, f4, rmux1_out		: bit_vector (4 downto 0);
	signal aluc					: bit_vector (3 downto 0);
	signal osig					: bit_vector (31 downto 0);

	type state_t is (IFE, IDE, EXE, MEM, WRB);
	signal state			: state_t;

	component instdecod is
		port(
			en	: in bit;
			inst	: in bit_vector (31 downto 0);
			f0	: out bit_vector (5 downto 0);
			f1	: out bit_vector (4 downto 0);
			f2	: out bit_vector (4 downto 0);
			f3	: out bit_vector (4 downto 0);
			f4	: out bit_vector (4 downto 0);
			op	: out bit_vector (5 downto 0)
		    );
	end component;

	component alu is
		port(
			aluc		: in bit_vector (3 downto 0);
			en		: in bit;
			rs, rt		: in bit_vector (31 downto 0);
			z, ov, c	: out bit;
			dout		: out bit_vector (31 downto 0)
		    );
	end component;

	component alu_controller is
		port(
			aluop	: in bit_vector (5 downto 0);
			en	: in bit;
			alu_en	: out bit;
			aluc	: out bit_vector (3 downto 0)
		    );
	end component;

	component mux_32b_4x1 is
		port(
			a, b, c, d	: in bit_vector (31 downto 0);
			sel		: in bit_vector (1 downto 0);
			y		: out bit_vector (31 downto 0)
		    );
	end component;

	component mux_32b_2x1 is
		port(
			a, b	: in bit_vector (31 downto 0);
			sel	: in bit;
			y	: out bit_vector (31 downto 0)
		    );
	end component;

	component barrel_shifter is
		port(
			a, b	: in bit_vector (31 downto 0);
			cntr	: in bit;
			opr	: in bit;
			y	: out bit_vector (31 downto 0)
		    );
	end component;

	component cl_adder_32b is
		port(
			a, b	: in bit_vector (31 downto 0);
			s	: out bit_vector (31 downto 0);
			z, c, ov: out bit;
			sub	: in bit
		    );
	end component;

	component reg32 is
		port(
			din	: in bit_vector (31 downto 0);
			clk, en	: in bit;
			dout	: out bit_vector (31 downto 0)
		    );
	end component;

	component regfile is
		port(
			rs_addr, rt_addr, rd_addr	: in bit_vector (4 downto 0);
			din				: in bit_vector (31 downto 0);
			clk, en				: in bit;
			rs_out, rt_out			: out bit_vector (31 downto 0)
		    );
	end component;
begin
	pc_upd <= (z and pcwc) or pcw;
	PC: reg32 port map(
				din => pc_bus,
				clk => clk,
				en => pc_upd,
				dout => pc_out
			  );

	pc_mux: mux_32b_2x1 port map(
					a => pc_out,
					b => alu_reg_out,
					sel => i_d,
					y => addr_out
				    );

	ID: instdecod port map(
					en => ir,
					inst => din,
					f0 => f0,
					f1 => f1,
					f2 => f2,
					f3 => f3,
					f4 => f4,
					op => op
			      );

	GPR: regfile port map(
					rs_addr => f4,
					rt_addr => f3,
					rd_addr => rmux1_out,
					din => rmux2_out,
					clk => clk,
					en => regw,
					rs_out => rega_in,
					rt_out => regb_in
			     );

	rmux1: mux_32b_2x1 port map(
					a(4 downto 0) => f3,
					a(31 downto 5) => (others => '0'),
					b(4 downto 0) => f2,
					b(31 downto 5) => (others => '0'),
					sel => reg_dst,
					y(4 downto 0) => rmux1_out,
					y(31 downto 5) => osig(31 downto 5)
				   );

	rmux2: mux_32b_2x1 port map(
					a => alu_reg_out,
					b => mdr_out,
					sel => reg_mem,
					y => rmux2_out
				   );
	MDR: reg32 port map(
				din => din,
				clk => clk,
				en => '1',
				dout => mdr_out
			   );

	rega: reg32 port map(
				din => rega_in,
				clk => clk,
				en => '1',
				dout => rega_out
			    );

	regb: reg32 port map(
				din => regb_in,
				clk => clk,
				en => '1',
				dout => regb_out
			    );

	alu_rs_mux: mux_32b_2x1 port map(
						a => pc_out,
						b => rega_out,
						sel => rs_src,
						y => alu_rs
					);

	alu_rt_mux: mux_32b_4x1 port map(
						a => regb_out,
						b(2 downto 0) => "000",
						b(3) => '1',
						b(31 downto 4) => (others => '0'),
						c(15 downto 11) => f2,
						c(10 downto 6) => f2,
						c(5 downto 0) => f0,
						c(31 downto 16) => (others => '1'),
						d(17 downto 13) => f2,
						d(12 downto 8) => f2,
						d(7 downto 2) => f0,
						d(1 downto 0) => "00",
						d(31 downto 18) => (others => '1'),
						sel => rt_src,
						y => alu_rt
					);

	ALUCON: alu_controller port map(
						aluop => op,
						en => a_en,
						alu_en => alu_en,
						aluc => aluc
				     );

	ALUNIT: alu port map(
				aluc => aluc,
				en => alu_en,
				rs => alu_rs,
				rt => alu_rt,
				dout => alu_out,
				z => z,
				ov => ov,
				c => c
			 );

	alu_reg: reg32 port map(
					din => alu_out,
					clk => clk,
					en => alu_en,
					dout => alu_reg_out
				);

	alu_mux: mux_32b_4x1 port map(
					a => alu_out,
					b => alu_reg_out,
					c(31 downto 28) => pc_out(31 downto 28),
					c(27 downto 23) => f4,
					c(22 downto 18) => f3,
					c(17 downto 13) => f2,
					c(12 downto 08) => f1,
					c(7 downto 2) => f0,
					c(1 downto 0) => "00",
					d => (others => '0'),
					sel => pc_src,
					y => pc_bus
				     );

	control_unit: process(clk, din)
	begin
		if(en = '1') then
			case state is
				when IFE =>
					rs_src <= '0';
					rt_src <= "01";
					a_en <= '1';
					i_d <= '0';
					ir <= '1';
					pcw <= '1';
					pc_src <= "00";
					state <= IDE;
				when IDE =>
					rs_src <= '0';
					rt_src <= "11";
					a_en <= '1';
					state <= EXE;
				when EXE =>
					case op(5 downto 4) is
						-- Operating on ALU op is not necessary as it is
						-- being handled in alu controller, setting of a_en is needed
						when "00" =>	-- I type and nop
							rs_src <= '1';
							rt_src <= "10";
							state <= MEM;
							a_en <= '1';
						when "01" =>	-- beq
							rs_src <= '1';
							rt_src <= "00";
							pcwc <= '1';
							pc_src <= "01";
							state <= IFE;
							a_en <= '1';
						when "10" =>	-- R type
							rs_src <= '1';
							rt_src <= "00";
							state <= MEM;
							a_en <= '1';
						when "11" =>	-- J type
							pcwc <= '1';
							pc_src <= "10";
							state <= IFE;
						when others =>
							a_en <= '0';
							state <= IFE;
					end case;
				when MEM =>
					if(op(3 downto 0) = "0010") then	-- LW operation
						i_d <= '1';
						state <= WRB;
					elsif(op(3 downto 0) = "0011") then	-- SW operation
						we <= '1';
						i_d <= '1';
						state <= IFE;
					else					-- R Type instructions
						reg_dst <= '1';
						regw <= '1';
						reg_mem <= '0';
						state <= IFE;
					end if;
					a_en <= '0';
				when WRB =>
					reg_dst <= '0';
					regw <= '1';
					reg_mem <= '1';
					a_en <= '0';
					state <= IFE;
			end case;
		end if;
	end process;
end behavioral;

