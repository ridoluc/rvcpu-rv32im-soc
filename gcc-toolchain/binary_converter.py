import struct

def convert(input_file, output_file):
    # Read the binary file
    with open(input_file, "rb") as f:
        data = f.read()

    # Convert binary data to binary strings
    with open(output_file, "w") as f_out:
        for i in range(0, len(data), 4):
            instruction = struct.unpack('<I', data[i:i+4])[0]  # Read 4 bytes as 32-bit little-endian
            binary_instruction = format(instruction, '032b')    # Convert to 32-bit binary string
            f_out.write(binary_instruction + "\n")              # Write to output file


if __name__ == "__main__":
    #take the input and output file names as arguments
    import sys
    input_file = sys.argv[1]
    output_file = sys.argv[2]
    convert(input_file, output_file)