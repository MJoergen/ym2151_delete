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

