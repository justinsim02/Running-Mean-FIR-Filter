# Running Mean FIR Filter - SystemVerilog Project

## Introduction
The DE1-SoC board is equipped with an audio CODEC capable of sampling sound from a microphone and
providing it as an input to a circuit. By default, the CODEC provides 48000 samples per second (48 kHz),
which is sufficient to accurately represent audible sounds (by the Nyquist-Shannon sampling theorem).

To simplify this lab, a system that can record and playback sounds on the board is provided as a “starter
kit.” The system comprises a Clock Generator, an Audio CODEC Interface, and an Audio/Video
Configuration module (Figure 3). For this lab, we will assume that our audio will be split into two
channels, left and right, that are intended to be played from multiple speakers (e.g., left and right
earbuds/headphones).

The left column of signals in Figure 3 are the inputs and outputs of the system. These I/O ports supply
the clock inputs and connect the Audio CODEC and Audio/Video Configuration modules to the
corresponding peripheral devices on the DE1-SoC board. The right column of signals connects the Audio CODEC Interface module to your circuit and allows your circuit to record sounds from a microphone and
play them back via speakers.
![](https://github.com/justinsim02/Running-Mean-FIR-Filter/blob/main/Screenshot%202024-03-04%20203046.png)

## About Audio Interface

- Upon reset, the Audio/Video Configuration begins an auto-initialization sequence. The sequence
sets up the audio device to sample microphone input at a rate of 48 kHz and produce output
through the speakers at the same rate.

- Once the auto-initialization is complete, the Audio CODEC begins reading the data from the
microphone once every 48,000-th of a second and sends it to the Audio CODEC Interface core in
the system.

- Once received, a sample is stored in a 128-element buffer in the Audio CODEC Interface core. The
first element of the buffer is always visible on the readdata_left and readdata_right
outputs (i.e., 2 channels for 1 sample), but the data is only valid when the read_ready signal is
asserted. When you assert the read signal, the current sample is replaced by the next element
one or more clock cycles later, indicated by read_ready being reasserted.

- The procedure to output sound through the speakers is similar. Your circuit should monitor the
write_ready signal. When the Audio CODEC is ready for a write operation, then your circuit can
write a sample to the writedata_left and writedata_right inputs and assert the write
signal. This operation stores a sample in a buffer inside of the Audio CODEC Interface, which will
then send the sample to the speakers at the right time.

![](https://github.com/justinsim02/Running-Mean-FIR-Filter/blob/main/Screenshot%202024-03-04%20203056.png)

## About FIR Filter
This circuit first divides the input sample by 𝑁 . Then, the
resulting value is stored in a First-In First-Out (FIFO) buffer of length 𝑁 and added to the accumulator.
To make sure the value in the accumulator is the average of the last 𝑁 samples, the circuit subtracts the
value that comes out of the FIFO, which represents the (𝑁 + 1)th sample.
![](https://github.com/justinsim02/Running-Mean-FIR-Filter/blob/main/Screenshot%202024-03-04%20203104.png)

## References
This lab is adopted from Intel's University Program
[More Information about Audio core for Intel DE-Series Boards](https://ftp.intel.com/Public/Pub/fpgaup/pub/Intel_Material/18.1/University_Program_IP_Cores/Audio_Video/Audio.pdf)
