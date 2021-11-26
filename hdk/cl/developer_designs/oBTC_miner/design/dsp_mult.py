import random

def dsp_mult(M0,M1,X0,X1):
    A = M1 * (2**12) + M0
    B = X1 * (2**12) + X0
    C = A * B
    M1X0 = M1 * X0
    #M1*X1 = C[31:24]
    M1X1= (C >> 24) & 255
    #M0*X0 = C[7:9]
    M0X0= C & 255
    #M1*X0 + M0*X1 = C[20:12]
    M1X0_M0X1 = (C >> 12) & 511
    M0X1 = M1X0_M0X1 - M1X0
    return M0X0, M0X1, M1X0, M1X1
# random int
M0 = random.randint(0,15)
M1 = random.randint(0,15)
X0 = random.randint(0,15)
X1 = random.randint(0,15)

for i in range(1000000):
    
    x,y,z,t = dsp_mult(M0,M1,X0,X1)
    # print("MOXO:",x)
    # print("MO*XO:",M0*X0)
    # print("MOX1:",y)
    # print("MO*X1:",M0*X1)
    # print("M1XO:",z)
    # print("M1*XO:",M1*X0)
    # print("M1X1:",t)
    # print("M1*X1:",M0*X0)

    if(x != M0*X0):
        print("Error M0X0")
        break
    elif(y != M0*X1):
        print("Error M0X1")
        break
    elif(z != M1*X0):
        print("Error M1X0")
        break
    elif(t != M1*X1):
        print("Error M1X1")
        break

print("Success!")

