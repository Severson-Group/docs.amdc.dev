# Speed of math operations on the AMDC

Mathematical operations from the <[math.h](https://pubs.opengroup.org/onlinepubs/009696799/basedefs/math.h.html)> library as well as common operations and casts were timed and benchmarked

## Benchmark Methodology

For each test, each operation was run 100 times with different operands.\
Clock cycles were counted for the total 100 operations, then a baseline number of clock cycles were subtracted from this total.\
The baseline was also gathered empirically for every test. It was how many clock cycles it took to set the output variable of the operations to an increasing value.\

To understand the sequence of events, take the example of the addi test:
- First, the baseline was calculated. The global variable mathCommandOutputInt was set to (1 + 0) and the number of clock cycles taken to perform the operation was logged. Then mathCommandOutputInt was set to (1 + 1), then (1 + 2), etc. The total number of clock cycles for 100 sets of the variable was summed.
- Then, the operations were performed. Two random numbers (from 0 to 1024) were selected for the inputs to addi. Lets use the examples 639 and 912. The time taken to set mathCommandOutputInt to (639 + 912 + 0) is recorded. Then mathCommandOutputInt is set to (639 + 912 + 1), then (639 + 912 + 2), etc, and the clock cycles taken for all 100 operations are summed. The reason for the changing variable is to avoid caching of the results and ensure that the processor must redo the add operation every time.
- With the measured and baseline numbers of clock cycles logged, the totals are subtracted from each other. The average number of clock cycles is calculated as (measured - baseline) / 100.0 clock cycles.

Additional information:
- In some cases, the time taken to perform the operation was less than the baseline, like in the case of addf. This results in a negative number on the graph. I don't know how this is possible but it is safe to say that the operation is extremely fast. Perhaps it was able to do multiple of these in a single clock cycle, or it's using SIMD magic.
- Tests were ran on the debug version of the code. This uses the -O2 optimization flag with the gcc compiler
- The code that ran these tests lives [here](https://github.com/Severson-Group/RyansRepo/blob/math/AMDC-Firmware/sdk/app_cpu1/user/usr/math/cmd/cmd_math.c) and the python driver code is [here](https://github.com/Severson-Group/RyansRepo/blob/math/AMDCmathBenchmarks.py)
- Different output variables were used for integers, floats, and doubles to avoid implicit casting.
- It was difficult to control caching speedups. Operands to the operations were either constants or declared as register to try to mitigate this problem, but with more complex operations there are many factors that cannot be controlled.

## Results

### Common Operations
![alt text](math-operations-images/commonOperationsNanoseconds.svg)

The addi, subi, muli, and divi refer to integer addition, subtraction, multiplication, and division.\
Similarily addf, subf, mulf, and divf refer to 32-bit floating point operations.\
Finally, the add, sub, mul, and div refer to 64-bit floating point (double) operations.

### All Operations
![alt text](math-operations-images/allOperationsNanoseconds.svg)

With exception of the common operations, all of these functions come from the <math.h> library.

## Casts

Casting tests have not yet been written

## Results

The numbers in the graphs are in nanoseconds, not clock cycles. However the conversion is simple. At a current frequency of 666.666 MHz, 1 clock cycle equals 1.5 nanoseconds.\
Changing the frequency of the clock will not change the number of clock cycles needed to complete an operation, but it will change the number of nanoseconds per clock cycle.

Quick analysis:
- Integer division and modulo is the slowest common operation by far
- Both float and double common operations tended to outperform their integer counterparts.
- the sqrt function was significantly faster than others in a similar complexity group
- Inverse trig operations outperformed normal trig operations.
- Normal trig and inverse trig operations outperformed hyperbolic trig and inverse trig operations. With the exception of tanh and atanh which performed much faster than expected.
- ceiling and floor operations were slower than I thought, being much slower than any floating point common operations and almost as slow as sqrt
- By far the slowest operation was pow, which is likely because it takes in two doubles and also allows negative inputs
- The natural log was quite a bit faster than log base 10.
- cbrt was significantly slower than sqrt

## Acceleration strategies

Integer division is so slow. I think it's literally faster to cast both inputs to doubles, do double division, and then cast that back to an integer.
I think that would still be correct (maybe). I need to finish the casting tests to say for sure though.