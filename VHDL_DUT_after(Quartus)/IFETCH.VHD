-- Ifetch module (provides the PC and instruction 
--memory for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY Ifetch IS
	generic ( MEMwitdh : integer :=12); 
	PORT(	SIGNAL Instruction 		: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        	SIGNAL PC_plus_4_out 		: OUT	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
        	SIGNAL Branch_or_jr 		: IN 	STD_LOGIC_VECTOR( MEMwitdh-3 DOWNTO 0 );
        	SIGNAL Branch 			: IN 	STD_LOGIC;
		SIGNAL Jump 			: IN 	STD_LOGIC;
        	SIGNAL Zero 			: IN 	STD_LOGIC;
      		SIGNAL PC_out 			: OUT	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
        	SIGNAL clock, reset 	: IN 	STD_LOGIC);
END Ifetch;

ARCHITECTURE behavior OF Ifetch IS
	SIGNAL PC, PC_plus_4,Mem_Addr : STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
	SIGNAL next_PC : STD_LOGIC_VECTOR( MEMwitdh-3 DOWNTO 0 );
	SIGNAL INST : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
BEGIN
						--ROM for Instruction Memory
inst_memory: altsyncram
	
	GENERIC MAP (
		operation_mode => "ROM",
		width_a => 32,
		widthad_a => 12,
		numwords_a=>4096,
		lpm_hint => "ENABLE_RUNTIME_MOD = YES, INSTANCE_NAME = ITCM" ,
		lpm_type => "altsyncram",
		outdata_reg_a => "UNREGISTERED",
		init_file => "E:\CPU_LAB\Project-CPU\Quartus\asmcode\asm_new_isa\program.hex",
		intended_device_family => "Cyclone"
	)
	PORT MAP (
		clock0     => clock,
		address_a 	=> Mem_Addr, 
		q_a 		=> INST );

		Instruction  <= INST;
					-- Instructions always start on word address - not byte
		PC(1 DOWNTO 0) <= "00";
					-- copy output signals - allows read inside module
		PC_out 			<= PC;
		PC_plus_4_out 	<= PC_plus_4;
						-- send address to inst. memory address register
		Mem_Addr <= Next_PC & "00";
						-- Adder to increment PC by 4        
PC_plus_4( MEMwitdh-1 DOWNTO 2 )  <= PC( MEMwitdh-1 DOWNTO 2) + 1;
   PC_plus_4( 1 DOWNTO 0 )  <= "00";


PROCESS(RESET,BRANCH,ZERO,JUMP,PC_plus_4,Branch_or_jr)
	BEGIN
	IF Reset = '1' THEN
		Next_PC  <= (others =>'0');
	ELSIF(( Branch = '1' ) AND ( Zero = '1' ) ) or (INST(31 downto 26) = "000000" and INST(5 downto 0) = "001000") THEN
		Next_PC  <= Branch_or_jr;
	ELSIF JUMP = '1' THEN
		Next_PC  <=  PC_plus_4(MEMwitdh-1 DOWNTO MEMwitdh-2) & INST(MEMwitdh-5 DOWNTO 0);
	ELSE
		Next_PC <= PC_plus_4( MEMwitdh-1 DOWNTO 2);
	END IF;
END PROCESS;

PROCESS(clock,reset)
	BEGIN
		IF reset = '1' THEN
				   PC( MEMwitdh-1 DOWNTO 2) <= (others =>'0') ;  
		ELSif ( clock'EVENT ) AND ( clock = '1' )then 
				   PC( MEMwitdh-1 DOWNTO 2 ) <= next_PC;
		END IF;
	END PROCESS;
END behavior;


