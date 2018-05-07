import java.io.File;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import java.nio.file.Paths;
import java.util.Arrays;
import java.util.List;
import java.util.Objects;

class Assembler {

    private static final String  FORMAT                = "mti";
    private static final char    ADDR_RADIX            = 'd';
    private static final char    DATA_RADIX            = 'b';
    private static final double  VERSION               = 1.0;
    private static final Integer WORDS_PER_LINE        = 1;
    private static final String  MEMORY_FILE_EXTENSION = ".mem";
    private static final String  INSTRUCTION_FILE_IDENTIFIER = "_intructions";
    private static final String  DATA_FILE_IDENTIFIER = "_data";

    private static final List<String> Operations = Arrays.asList(
            "NOP",  "ADD",  "SUB",  "AND", "OR",  "RLC", "RRC", "SHL",
            "SHR",  "SETC", "CLRC", "NOT", "INC", "DEC",

            "MOV", "MUL", "PUSH", "POP", "OUT", "IN",  "JZ",  "JN",
            "JC",  "JMP", "CALL", "RET", "RTI", "LDM", "LDD", "STD"
    );

    private static final String MEMORY_FILE_HEADER =
            "// memory data file (do not edit the following line - required for mem load use)\n"
                    + "// format=" + FORMAT + ' '
                    + "addressradix=" + ADDR_RADIX + ' '
                    + "dataradix=" + DATA_RADIX + ' '
                    + "version=" + String.valueOf(VERSION) + ' '
                    + "wordsperline=" + String.valueOf(WORDS_PER_LINE)
                    + "\n";

    private static final Integer CHACHE_H = 512, CHACHE_W = 16;
    private static final Integer PC_CACHE_INDEX = 0, INT_CACHE_INDEX = 1;
    private static String[] mInstructionsCache = new String[CHACHE_H], mDataCache = new String[CHACHE_H];
    private static int mInstructionsCacheIndex = 0, mDataCacheIndex = INT_CACHE_INDEX + 1;
    private static final String INITIAL_CACHE_VALUE = String.format("%0" + CHACHE_W + "d", 0);
    private static final String NO_REG = new String(new char[3]).replace("\0", "0");
    private static final String NOT_USED_BITS = new String(new char[5]).replace("\0", "0");

    private BufferedReader mReader = null;
    private BufferedWriter mInstructionsWriter = null, mDataWriter = null;

    private class CompilationErrorException extends RuntimeException{
        CompilationErrorException(String message) {
            super(message);
        }
    }

    void CompileFile(String inpFilename, String memoryFolder){
        try{
            File inpFile  = new File(inpFilename);
            File instructionsFile = Paths.get(
                    inpFilename.substring(0, inpFilename.lastIndexOf('.'))
                            + INSTRUCTION_FILE_IDENTIFIER
                            + MEMORY_FILE_EXTENSION).toFile();
            File dataFile = Paths.get(
                    inpFilename.substring(0, inpFilename.lastIndexOf('.'))
                            + DATA_FILE_IDENTIFIER
                            + MEMORY_FILE_EXTENSION).toFile();

            mReader = new BufferedReader(new FileReader(inpFile));
            mInstructionsWriter = new BufferedWriter(new FileWriter(instructionsFile));
            mDataWriter = new BufferedWriter(new FileWriter(dataFile));

            mInstructionsWriter.write(MEMORY_FILE_HEADER);
            mDataWriter.write(MEMORY_FILE_HEADER);

            for(int i=0; i<CHACHE_H; ++i) {
                mInstructionsCache[i] = INITIAL_CACHE_VALUE;
                mDataCache[i] = INITIAL_CACHE_VALUE;
            }

            parseFileToCaches();
            writeCachesToFiles();
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            try {
                if (mReader != null) {
                    mReader.close();
                }
                if (mInstructionsCache != null){
                    mInstructionsWriter.close();
                    mDataWriter.close();
                }
            }catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private void parseFileToCaches() throws IOException{
        String line;

        line = mReader.readLine();
        mDataCache[PC_CACHE_INDEX]  = String.format("%16s",
                Integer.toBinaryString(Integer.parseInt(line.replaceAll("\\D.*", ""))))
                .replace(' ', '0');
        System.out.println("PC starting address: " + mDataCache[PC_CACHE_INDEX]);

        line = mReader.readLine();
        mDataCache[INT_CACHE_INDEX] = String.format("%16s",
                Integer.toBinaryString(Integer.parseInt(line.replaceAll("\\D.*", ""))))
                .replace(' ', '0');
        System.out.println("INT address: " + mDataCache[INT_CACHE_INDEX]);

        while((line = mReader.readLine()) != null && line.length() == 0); // empty lines and ; data segment

        // parse data segment and ; code segment
        while ((line = mReader.readLine()) != null) {
            if(line.length() != 0){
                if(!Character.isDigit(line.charAt(0))){
                    break;
                }
                mDataCache[mDataCacheIndex++] = String.format("%16s",
                        Integer.toBinaryString(Integer.parseInt(line.replaceAll("\\D.*", ""))))
                        .replace(' ', '0');
            }
        }

        // parse code segment
        while ((line = mReader.readLine()) != null) {
            if(line.length() != 0){
                if(line.charAt(0) == '.'){
                    break;
                }
                for(String parsedLine : Objects.requireNonNull(parseLine(line))){
                    mInstructionsCache[mInstructionsCacheIndex++] = parsedLine;
                }
            }
        }

        // parse .addresses
        do{
            int index = Integer.parseInt(Objects.requireNonNull(line).substring(1).replaceAll("\\D.*", ""));
            while((line = mReader.readLine()) != null){
                if(line.length() != 0){
                    if(line.charAt(0) == '.'){
                        break;
                    }
                    if(index < mInstructionsCacheIndex ){
                        System.out.println("Writing to instruction cache in address < "
                                + "instructions cache index : "
                                + String.valueOf(index));
                    }
                    for(String parsedLine : Objects.requireNonNull(parseLine(line))){
                        mInstructionsCache[index++] = parsedLine;
                    }
                }
            }
        } while(line != null);
    }

    private String[] parseLine(String line){
        if(line.length() == 0)
            return null;

        String lineWithoutComment = line.split(";")[0];
        String codeParts[] = lineWithoutComment.split(" ");
        String instruction = codeParts[0];
        String operands[] = null;
        if(codeParts.length>1)
            operands = codeParts[1].split(",");

        return parseInstruction(instruction, operands);
    }

    private String[] parseInstruction(String instr, String[] operands){
        int size5  = ((int) Math.pow(2, 5));

        // No operands
        if(instr.matches("\\b(?i)(nop|(set|clr)c|r(et|ti))\\b"))
            return new String[] { Integer.toBinaryString(size5 | Operations.indexOf(instr.toUpperCase())).substring(1)
                    + NO_REG
                    + NO_REG
                    + NOT_USED_BITS
            };

            // Single operands in dst with NO imm or ea
        else if(instr.matches("\\b(?i)(r[l|r]c|pop|out|in|not|(in|de)c|j[z|n|c]|jmp|call)\\b"))
            return new String [] { Integer.toBinaryString(size5 | Operations.indexOf(instr.toUpperCase())).substring(1)
                    + NO_REG
                    + parseOperand(operands[0])
                    + NOT_USED_BITS
            };

            // Single operands in dst with imm or ea
        else if(instr.matches("\\b(?i)(ld[d|m])\\b"))
            return new String [] { Integer.toBinaryString(size5 | Operations.indexOf(instr.toUpperCase())).substring(1)
                    + NO_REG
                    + parseOperand(operands[0])
                    + NOT_USED_BITS,

                    String.format("%16s", Integer.toBinaryString(Integer.parseInt(operands[1].replaceAll("\\D.*", ""))))
                            .replace(' ', '0')
            };

            // Single operands in src with NO imm or ea
        else if(instr.matches("\\b(?i)(push)\\b"))
            return new String[] { Integer.toBinaryString(size5 | Operations.indexOf(instr.toUpperCase())).substring(1)
                    + parseOperand(operands[0])
                    + NO_REG
                    + NOT_USED_BITS
            };

            // Single operands in src with imm or ea
        else if(instr.matches("\\b(?i)(std)\\b"))
            return new String[] { Integer.toBinaryString(size5 | Operations.indexOf(instr.toUpperCase())).substring(1)
                    + parseOperand(operands[0])
                    + NO_REG
                    + NOT_USED_BITS,

                    String.format("%16s", Integer.toBinaryString(Integer.parseInt(operands[1].replaceAll("\\D.*", ""))))
                            .replace(' ', '0')
            };

            // Double operands with NO imm or ea
        else if(instr.matches("\\b(?i)(mov|a[n|d]d|mul|sub|or)\\b"))
            return new String[] { Integer.toBinaryString(size5 | Operations.indexOf(instr.toUpperCase())).substring(1)
                    + parseOperand(operands[0])
                    + parseOperand(operands[1])
                    + NOT_USED_BITS
            };

            // Double operands with imm or ea
        else if(instr.matches("\\b(?i)(sh[r|l])\\b"))
            return new String[] {
                    Integer.toBinaryString(size5 | Operations.indexOf(instr.toUpperCase())).substring(1)
                            + parseOperand(operands[0])
                            + parseOperand(operands[2])
                            + NOT_USED_BITS,

                    String.format("%16s", Integer.toBinaryString(Integer.parseInt(operands[1].replaceAll("\\D.*", ""))))
                            .replace(' ', '0')
            };

        else
            throw new CompilationErrorException("Illegal Instruction: " + instr);
    }

    private String parseOperand(String operand) throws CompilationErrorException{
        String parsedOp = "";

        int regNum = Integer.parseInt(operand.replaceAll("[\\D]", ""));
        parsedOp += Integer.toBinaryString(((int) Math.pow(2, 3)) | regNum).substring(1);

        if(regNum > 5)
            throw new CompilationErrorException("Illegal Operand: " + operand);

        return  parsedOp;
    }

    private void writeCachesToFiles() throws IOException{
        for (int i = CHACHE_H-1; i>=0; --i){
            mInstructionsWriter.write(String.format("%4d", i)+ ": " + mInstructionsCache[i]+"\n");
            mDataWriter.write(String.format("%4d", i)+ ": " + mDataCache[i]+"\n");
        }
    }
}

class main {
    public static void main(String[] args) {

        if (args.length < 2) {
            System.out.println("Usage Assembler: filename memory-folder");
            System.exit(1);
        }

        new Assembler().CompileFile(args[0], args[1]);
    }
}
