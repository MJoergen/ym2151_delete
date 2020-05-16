# 2020 May 15
This is the initial checkin of the project. I have made a previous attempt at
implementing the YM2151, but I have decided to start from scratch, and keep a
log of my progress.

So why did I decide to start from scratch? Well, in my previous attempt I had
used a DSP to perform multiplication rather than using a lookup into a table of
exponentials. However, that turns out to be a bad idea, because there is a need
for (at least) three multiplications.

Instead, I will use the exponential method. The implementaion will therefore
much more closely resemble that of [jotego/jt51](https://github.com/jotego/jt51/).
Essentially, this will be a translation of jotego's implementation to VHDL.

So the first checkin establishes the directory structure, where the files for synthesis
are placed in the [src](src) directory, while files for simulation are placed in
the [sim](sim) directory. Furthermore, an example design for the Nexys4DDR board is
placed in the [nexys4ddr](nexys4ddr) directory.

## doc
The doc directory contains the original user guide from Yamaha.

## src
The src directory so far only contains the top-level module for the YM2151.
This is to specify the interface. The configuration interface consists of an
8-bit address and 8-bit data. Furthermore, I've chosen an AXI-style valid/ready
signaling. The ready signal is pulled low when the YM2151 is busy, in which
case it just ignores the inputs. So far, these ports are not used.

The waveform output is 16-bit unsigned integer, which represents a fractional
value between logical 0 and logical 1.

The YM2151 module must be clocked with a frequency of 3.579 MHz, and the output
can be sampled as 1/32th of that frequency, i.e. 112 kHz.

The top level implementation for now just generates a saw tooth waveform at a
frequency of approximately 437 Hz.

## sim
This directory is for simulating the YM2151. It contains a testbench file to
instantiate the YM2151 and then connects the output to the module wav2file.
This module converts the output to a WAV file.

To run the simulation, just type "make". When the simulation has completed,
this will automatically open up the waveform viewer.  Optionally, the generated
WAV file can be viewed/analyzed using audacity.

## nexys4ddr
This directory contains a simple example design to run on the Nexys4DDR board.
The top level file nexys4ddr.vhd instantiates the YM2151 module and a PWM
(Pulse Width Modulation) module. The latter is required to connect to the
on-board low-pass filter.

The PWM module runs at a frequency exactly 64 times faster, and therefore no
special consideration is needed when passing from the YM2151 clock domain to
the PWM clock domain.

The design can be run on the Nexys4DDR board, and the output can be read and
analyzed by audacity.

# 2020 May 15
Another update today. This time, I've implemented the ROM's for calculating the
sine function. This is actually two ROM's; one calculates the logarithm of the
sine, and the other calculates the exponential function.

Much of the inspiration has come from this
[repo](https://github.com/sauraen/YM2612/blob/master/Source/operator.vhd), but
where I have tried to rewrite it into a more readable form.

The heart of the waveform generator is being able to calculate the sine of an
angle. Rather than doing this in a single ROM lookup, the calculation is split
into two different ROMs:
* logsin, which calculates y=-log2(sin(x)).
* exp, which calculates z=0.5^y.
Composing these two functions gives indeed z=sin(x).

The reason for splitting the sine calculation in two like this, is to make the
envelope generation much easier, as this can now be achieved by a simple
addition.

The devil is in the details, as the saying goes, and so it is here too. In
particular, the binary representation of the numbers adds considerable
complexity.

In the following I'm referring to the file
[calc\_sine.vhd](src/calc\_sine.vhd). The calculation is split into a number of
stages.

## Stage 0
The input phase\_i represents an angle between 0 to 2\*pi, and has a resolution
of 10 bits.

First some symmetries of the sine function is used to reduce the angle to the
first quadrant, i.e. between 0 to pi/2, with a resolution of 8 bits. The sign
of the result is stored separately.

## Stage 1
Here we use the first ROM, logsin, to calculate y=-log2(sin(x)). The input has
resolution of 8 bits, and the output has resolution of 12 bits.

The result is in units of 1/256'th powers of 0.5.

## Stage 2
The upper four bits of logsin are the exponent part (in base 2).  They indicate
how many bits to shift (between 0 and 15).  The lower eight bits of logsin are
fed to the second ROM, exp, to calculate z=0.5^y, which is the mantissa.  The
output of this ROM has resolution of 11 bits.

## Stage 3
This last stage instantiates the block float2fixed, which combines the sign,
the exponent, and the mantissa to generate the output value.

Finally, I've updated the file ym2151.vhd to instantiate this new calc\_sine
block.  Note, that there is a conversion from signed to unsigned, i.e. a shift
by 0.5. This is achieved simply by negating the MSB.

The widths of the various signals are chosen to match those of
[jotego/jt51](https://github.com/jotego/jt51/).

# 2020 May 16
The next step is to introduce the frequency calculation. All frequencies are
translated to a "phase increment", which is read from yet another ROM.

The current phase is stored with 20-bit precision, where the upper 10 bits are
fed to the sine table calculation. The phase is updated once every 32 clock
cycles, just like in the final version.  Each time the phase is updated with
the phase increment.  This is what happens in the p\_phase process in
ym2151.vhd.

The phase increment is calculated in calc\_freq based on the current note being
played.  The ROM has 10 bits of input and 12 bits of output.  The values in the
ROM correspond to octave 0.  For instance, the key A0 (with frequency 13.75 Hz)
corresponds to index 0x280 (640) and has the value 0x80E (2062).

The update frequency is 3579545/32 Hz, i.e. 112 kHz. The phase increment at
each update is 13.75/111860 = 1.229\*10^-4.  Scaling this by a factor of 2^24
gives indeed 2062.

Oh, and I wrote a section about the [jt51](jt51.md).

