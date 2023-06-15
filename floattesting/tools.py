import struct
import re

class Tools:

    def binary_to_float(self, binary, numExponent, numFraction, bytes):
        # check for 0 
        # print(binary)
        if binary[1:bytes*8] == "0" * (1 + numExponent + numFraction):
            if binary[0] == "0":
                return 0.0
            else:
                return -0.0
        
        # Extract sign, exponent, and fraction bits
        sign_bit = binary[0]
        exponent_bits = binary[1:1 + numExponent]
        fraction_bits = binary[1 + numExponent:]
        # print("sign", binary[0])
        # print("exponent",exponent_bits)
        # print("fraction",fraction_bits)
        # Convert sign bit
        sign = -1 if sign_bit == 49 else 1

        bias = (2 ** (numExponent - 1))-1
        # print("bias",bias)
        # Convert exponent bits
        exponent = int(exponent_bits, 2) - bias
        # print("exponent",exponent)
        # Convert fraction bits
        # fraction = 1.0
        # for i in range(numFraction):
        #     fraction += int(fraction_bits[i]) * (2 ** -(i + 1))
        fraction = int(fraction_bits, 2) / (2 ** numFraction)
        fraction += 1
        # print("fraction",fraction)
        # Calculate the final value
        value = sign * fraction * (2 ** exponent)
        # print("value",value)
        return value




    def read_float(self, file, float_size, Type):
        G = file.read(float_size)
        print(self.bitstring_to_hex(G))
        if (float_size == 32):
            return self.binary_to_float(G, 8, 23, 4)
            G = struct.pack("I", int(G, 2))
            return struct.unpack('f', G)[0]
        elif (float_size == 16):
            return self.binary_to_float(G, 8, 7, 2)
        elif (float_size == 8):
            if (Type == "E4M3"):
                return self.binary_to_float(G, 4, 3, 1)
            elif (Type == "E5M2"):
                return self.binary_to_float(G, 5, 2, 1)

    def calculate_error(self, calculated_value, actual_value):
        error = abs((calculated_value - actual_value)/actual_value)
        percentage_error = error * 100
        return percentage_error

    def extract_numbers(text):
        pattern = r'\d+'  # Regex pattern to match one or more digits
        # Find all matches of the pattern in the text
        matches = re.findall(pattern, text)
        return matches[0]
    
    def bitstring_to_hex(self, bitstring):
        # Calculate the number of characters required for padding

        # Convert the padded bit string to hexadecimal
        hex_string = hex(int(bitstring, 2)).upper()

        return hex_string
    # def binary_to_float(binary):
    #      # Convert binary string to bytes
    #     print(binary)
    #     byte_string = int(binary, 2).to_bytes(2, 'big')

    #     # Unpack bytes as unsigned short (16-bit integer)
    #     integer_value = struct.unpack('>H', byte_string)[0]

    #     # Create binary representation with 16 bits
    #     binary_string = bin(integer_value)[2:].zfill(16)
    #     if binary_string[1:16] == "0"*15:
    #         if binary_string[0] == "0":
    #             return 0
    #         else:
    #             return -0.0
    #     # Extract sign, exponent, and fraction bits
    #     sign_bit = int(binary_string[0])
    #     exponent_bits = binary_string[1:9]
    #     fraction_bits = binary_string[9:]

    #     # Convert sign bit
    #     sign = -1 if sign_bit else 1

    #     # Convert exponent bits
    #     exponent = int(exponent_bits, 2) - 127

    #     # Convert fraction bits
    #     fraction = 1.0
    #     for i in range(7):
    #         fraction += int(fraction_bits[i]) * (2 ** -(i+1))
            
    #     # Calculate the final value
    #     value = sign * fraction * (2 ** exponent)
    #     return value



