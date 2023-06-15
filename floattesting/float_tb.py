import struct
import re
from tools import Tools
import os
import sys

sys.path.append(os.getcwd())
if os.path.exists("./printLog.txt"):
    os.remove("./printLog.txt")
sys.stdout = open("./printLog.txt", "w")

TO = Tools()
extension = "Inputs.txt"
file_path = './floattesting/'
i = 1

# instructions -----------------
# 1. Change the operation to "add", "sub", "mul"
# 2. Change the bits to 32, 16, or 8
# 3. Change the Type to "E4M3" or "E5M2"
# 4. If you change the hex ram_content.hex please run the testbench
# to get the baords outputs then copy and paste the binary vaules into
# the Inputs.txt files in the floattesting folder. Skip the first number given by the test bench
# 5. Run this script and check the printLog.txt file for the results


# Configurations ----------------
operation = "sub" # "add", "sub", "mul
bits = 8 # 32 or 16 or 8
Type = "" # 32 or 16
# Type = "E4M3"
Type = "E5M2"
# -------------------------------



# Open the file in binary mode
with open(file_path + Type+str(bits)+operation+extension, 'rb') as file:
    # Loop through each line in the file
    for line in file:
        print("Test case", i)
        A = TO.read_float(file, bits, Type)
        B = TO.read_float(file, bits, Type)
        C = TO.read_float(file, bits, Type)

        # Perform the multiplication
        if operation == "add":
            result = A + B
        elif operation == "sub":
            result = A - B
        elif operation == "mul":
            result = A * B

        if C != 0 or result != 0:
            print("A:", A, "B:", B)
            print("C:", C, "result:", result)
            percentage_error = abs(TO.calculate_error(C,result))
            if percentage_error < 1:
                print("The value is correct!")
            else:
                print("The value is incorrect!")
            print("Percentage error:", percentage_error)
            print()
            
        else:
            print("A:", A, "B:", B)
            print("C:", C, "result:", result)
            print("Percentage error:", 0, " Cant find error of 0")
            print()
            
        i += 1
        



