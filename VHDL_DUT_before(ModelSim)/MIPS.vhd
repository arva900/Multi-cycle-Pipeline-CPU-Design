				-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;



ENTITY MIPS IS
	generic ( MEMwitdh : integer :=12);
	PORT( reset, clock					: IN 	STD_LOGIC; 
		PC						: OUT  STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
		ALU_result_out, read_data_1_out, read_data_2_out, writeback_data_out,	
     		Instruction_out					: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Branch_out,Jump_out, 
		Memwrite_out,MemRead_out, Regwrite_out					: OUT 	STD_LOGIC ;
		wrenBUS_out				: OUT 	STD_LOGIC ;
		addressBUS			: OUT 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
		DATA_bus 			: INOUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 )
		);
END MIPS;


ARCHITECTURE structure OF MIPS IS

	COMPONENT Ifetch
	generic ( MEMwitdh : integer :=12);
   	     PORT(	Instruction			: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		PC_plus_4_out 			: OUT  	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
        		Branch_or_jr 			: IN 	STD_LOGIC_VECTOR( MEMwitdh-3 DOWNTO 0 );
        		Branch 				: IN 	STD_LOGIC;
			Jump 				: IN 	STD_LOGIC;
        		Zero 				: IN 	STD_LOGIC;
        		PC_out 				: OUT 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
        		clock,reset 		: IN 	STD_LOGIC );
	END COMPONENT; 

	COMPONENT Idecode
 	     PORT(	read_data_1 		: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		read_data_2 		: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		Instruction 		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		read_data 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		ALU_result 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		RegWrite, MemtoReg 	: IN 	STD_LOGIC;
        		RegDst 				: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
        		Sign_extend 		: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		clock, reset		: IN 	STD_LOGIC );
	END COMPONENT;

	COMPONENT control
	     PORT( 	Opcode 				: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
             	RegDst 				: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
             	ALUSrc 				: OUT 	STD_LOGIC;
             	MemtoReg 			: OUT 	STD_LOGIC;
             	RegWrite 			: OUT 	STD_LOGIC;
             	MemRead 			: OUT 	STD_LOGIC;
             	MemWrite 			: OUT 	STD_LOGIC;
             	Branch 				: OUT 	STD_LOGIC;
		Jump 				: OUT 	STD_LOGIC;
             	ALUop 				: OUT 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
             	clock, reset		: IN 	STD_LOGIC );
	END COMPONENT;

	COMPONENT  Execute
	generic ( MEMwitdh : integer :=12);
   	     PORT(	Read_data_1 		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
                Read_data_2 		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
               	Sign_Extend 		: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
               	Function_opcode		: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
		instr_opcode		: IN 	STD_LOGIC_VECTOR( 5 DOWNTO 0 );
               	ALUOp 				: IN 	STD_LOGIC_VECTOR( 1 DOWNTO 0 );
               	ALUSrc 				: IN 	STD_LOGIC;
               	Zero 				: OUT	STD_LOGIC;
               	ALU_Result 			: OUT	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
               	Branch_or_jr 			: OUT	STD_LOGIC_VECTOR( MEMwitdh-3 DOWNTO 0 );
               	PC_plus_4 			: IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
               	clock, reset		: IN 	STD_LOGIC );
	END COMPONENT;


	COMPONENT dmemory
	generic ( MEMwitdh : integer :=12);
	     PORT(	read_data 			: OUT 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		address 			: IN 	STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
        		write_data 			: IN 	STD_LOGIC_VECTOR( 31 DOWNTO 0 );
        		MemRead, Memwrite 		: IN 	STD_LOGIC;
        		Clock,reset			: IN 	STD_LOGIC );
	END COMPONENT;

					-- declare signals used to connect VHDL components
	SIGNAL PC_plus_4 		: STD_LOGIC_VECTOR( MEMwitdh-1 DOWNTO 0 );
	SIGNAL read_data_1 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data_2 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Sign_Extend 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Branch_or_jr 		: STD_LOGIC_VECTOR( MEMwitdh-3 DOWNTO 0 );
	SIGNAL ALU_result 		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data,MEMORYread  		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL ALUSrc 			: STD_LOGIC;
	SIGNAL Branch,Jump 		: STD_LOGIC;
	SIGNAL RegDst 			: STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL Regwrite 		: STD_LOGIC;
	SIGNAL Zero 			: STD_LOGIC;
	SIGNAL MemWrite 		: STD_LOGIC;
	SIGNAL MemtoReg 		: STD_LOGIC;
	SIGNAL MemRead 			: STD_LOGIC;
	SIGNAL ALUop 			: STD_LOGIC_VECTOR(  1 DOWNTO 0 );
	SIGNAL Instruction		: STD_LOGIC_VECTOR( 31 DOWNTO 0 );

SIGNAL wrenBUS 			: STD_LOGIC;

BEGIN
					-- copy important signals to output pins for easy 
					-- display in Simulator
   Instruction_out 	<= Instruction;
   ALU_result_out 	<= ALU_result;
   read_data_1_out 	<= read_data_1;
   read_data_2_out 	<= read_data_2;
   writeback_data_out  	<= read_data WHEN MemtoReg = '1' ELSE ALU_result;
   Branch_out 		<= Branch;
   Jump_out		<= Jump; 				
   RegWrite_out 	<= RegWrite;
   MemWrite_out 	<= MemWrite;	
   Memread_out		<= MemRead;
					

addressBUS <= ALU_result(MEMwitdh-1 DOWNTO 0);
	
	

memLIM: process(DATA_bus,Instruction,MEMORYread,ALU_result)
begin
	if (ALU_result( MEMwitdh-1 DOWNTO 0 ) > x"7FC") then
		read_data <= DATA_bus;
		wrenBUS <= '1' AND MemWrite;
	ELSE
		read_data <= MEMORYread;
		wrenBUS <= '0';
	end if;
end process;

DATA_bus <= read_data_2 when wrenBUS = '1' else (others => 'Z');
wrenBUS_out <= wrenBUS ;   

-- connect the 5 MIPS components
  IFE : Ifetch generic map(MEMwitdh)
	PORT MAP (		Instruction 	=> Instruction,
    	    			PC_plus_4_out 	=> PC_plus_4,
				Branch_or_jr 		=> Branch_or_jr,
				Branch 			=> Branch,
				Jump			=> Jump,
				Zero 			=> Zero,
				PC_out 			=> PC,        		
				clock 			=> clock,  
				reset 			=> reset );

   ID : Idecode
   	PORT MAP (	read_data_1 	=> read_data_1,
        		read_data_2 	=> read_data_2,
        		Instruction 	=> Instruction,
        		read_data 		=> read_data,
				ALU_result 		=> ALU_result,
				RegWrite 		=> RegWrite,
				MemtoReg 		=> MemtoReg,
				RegDst 			=> RegDst,
				Sign_extend 	=> Sign_extend,
        		clock 			=> clock,  
				reset 			=> reset );


   CTL:   control
	PORT MAP ( 	Opcode 			=> Instruction( 31 DOWNTO 26 ),
				RegDst 			=> RegDst,
				ALUSrc 			=> ALUSrc,
				MemtoReg 		=> MemtoReg,
				RegWrite 		=> RegWrite,
				MemRead 		=> MemRead,
				MemWrite 		=> MemWrite,
				Branch 			=> Branch,
				Jump			=> Jump,
				ALUop 			=> ALUop,
               			clock 			=> clock,
				reset 			=> reset );

   EXE:  Execute generic map(MEMwitdh)
   	PORT MAP (	Read_data_1 	=> read_data_1,
             		Read_data_2 	=> read_data_2,
			Sign_extend 	=> Sign_extend,
               		Function_opcode	=> Instruction( 5 DOWNTO 0 ),
			instr_opcode	=> Instruction( 31 DOWNTO 26 ),
			ALUOp 			=> ALUop,
			ALUSrc 			=> ALUSrc,
			Zero 			=> Zero,
                	ALU_Result		=> ALU_Result,
			Branch_or_jr 		=> Branch_or_jr,
			PC_plus_4		=> PC_plus_4,
               		Clock			=> clock,
			Reset			=> reset );

   MEM:  dmemory generic map(MEMwitdh)
	PORT MAP (		read_data 		=> MEMORYread,
				address 		=> ALU_Result ( MEMwitdh-1 DOWNTO 0),
				write_data 		=> read_data_2,
				MemRead 		=> MemRead, 
				Memwrite 		=> MemWrite, 
                		clock 			=> clock,  
				reset 			=> reset );
END structure;

