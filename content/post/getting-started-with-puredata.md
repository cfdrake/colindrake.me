---
title: "Getting Started with Pure Data"
date: 2015-08-03
---

[Pure Data](http://puredata.info/) is a cross platform and open source visual programming language allowing you to work with audio, video, and more in a simple [dataflow](https://en.wikipedia.org/wiki/Dataflow#Software_architecture) programming model. Over the past week or so, I've been exploring Pd for music and audio use and figured that a series of blog posts documenting my path of learning would be fun, helpful for others, and a good way to reinforce what I've covered.

This is the first entry in this potential series: we'll be covering installation for Mac OS X, some basic dataflow programming concepts, and a few simple audio object types. In the end, we'll build a simple Hi-Hat patch with a few tweakable parameters.

## Installation
Pure Data comes in two flavors:

- **Pure Data Vanilla**: A basic setup, but will cover everything you need to get started.
- **Pure Data Extended**: Vanilla plus some very helpful documentation, libraries, and packages.

I'd recommend installing [Pure Data Extended](http://puredata.info/downloads/pd-extended), as it comes with a variety of useful objects types that you would otherwise be missing. Additionally, I've noticed that many times Cycling74/Pure Data forum threads will reference objects built-in to only the Extended version (the helpful `[sfv~]` for instance).

On Mac OS X, you can either [manually download](http://puredata.info/downloads) these or install them with the `brew` command, if you are familiar.

    $ brew search pd
    Caskroom/cask/pd-extended
    Caskroom/cask/pd

_Note: I haven't tested the Homebrew versions to see how up-to-date or functional they are. YMMV._

Before continuing, I'll assume you have a little bit of familiarity with the Pd [interface](http://en.flossmanuals.net/pure-data/the-interface/the-interface/), i.e. that you have at least explored around it before reading this article. Additionally, some experience with sound synthesis will help out, but I'll attempt to link out for further reading when needed.

## Dataflow Model
The dataflow programming model of Pure Data allows you to abstract out your ideas into sequences of composable functions that immediately react to new values produced by inputs. In the audio world, this allows you to build out your instruments with a DSP-centric model of the world.

Within Pure Data, this is graphically represented by objects with wires connecting their inputs to the outputs of other objects. For example, the following patch will print out the number sent as input to the print function. Upon, changing the value of the number in Play mode (Command-E to toggle between Edit/Play modes), `[print]` will automatically react and print the value to the console window.

<p class="smaller-img"><img src="/images/pure-data/pd-print.png" title="WIP Hi-Hat Patch" /></p>

This automatic reaction to inputs is what lets us easily build interactive synthesizers, instruments, etc. Note that these inputs may come from a variety of sources: manual user input, MIDI messages, [OSC](https://en.wikipedia.org/wiki/Open_Sound_Control), serial port data from an [Arduino](http://playground.arduino.cc/Interfacing/PD), and more. We'll stick with manual user input from the GUI for now.

Next, we'll cover some of the object and data types that are available for us to use and start building with.

## Object Types
The following are the most basic forms of data and types that Pure Data supports:

* **Object**: Think of this as similar to a function. `[print]`, `[+]`, `[*]` are examples. They may take input via pins at the top, and will produce output via pins at the bottom.
* **Number Box**: This data type allows you to input and edit a numerical (integer or float) value. This may be sent to an input pin of an object and will re-send whenever the value changes.
* **Message Box**: List of data that may be sent to an object upon click from the user. For example, you may describe a sequence of sampled amplitudes to send to an audio object. In a way, these are similar to function arguments.
* **Bang**: Upon clicking, this will "trigger" another object in realtime. May be used to begin a sound's audio envelope, etc.

Additionally, many UI components such as sliders, VU meters, etc. are supported to make your patch more usable to other people.

When it comes to the audio domain, most of what we'll work with will be simple Object types, or functions. Sound generators, audio filters, and more are all provided as objects in Pure Data that generate potentially constantly changing signals over time. It's worthy of note that audio objects typically have names ending in `~`, such as `[phasor~]`.

## Audio Patches
Let's start out by exploring the simplest generator available to us.

#### Generating Sound

The `[osc~]` object outputs a [constant (co)sine wave](https://en.wikipedia.org/wiki/Pure_tone) at the specified frequency. You can provide a frequency to this object via a couple of methods:

1. `[osc~ 440]` will generate a constant 440-Hz sine wave.
2. A plain `[osc~]` with a Number Box connected to the top left pin will allow you to adjust the frequency of the wave at will. You may also use the first form with a Number Box attached, providing a default value that is user changeable.

`[dac~]`, the digital to analog convertor object, allows you to output a signal to the left and right output stereo channels of your computer. When you create this object, you'll note it has two pins: the left and right pins (obviously) map to the left and right sound output channels.

Try to set up the two prior configurations (one at a time) with output connected to the DAC in Pure Data. Press Command-/ to enable audio and Command-. to disable it. You should hear a pure, constantly sounding tone. Your patches should look something like these:

<p class="small-img"><img src="/images/pure-data/osc.png" title="Osc Patch" /></p>

Next, we'll try to modify (process) this audio signal before sending it to the speaker.

#### Processing Sound
The simplest case for modifying a signal is by affecting the the amplitude. The `[*~]` object will multiply N audio signals together over time. By multiplying a signal by zero, you silence it, and by multiplying it by one, you leave it unaffected. Less than one is negative gain, and greater than one is positive gain. Lets build a user-editable volume control for our oscillator by using a Number box:

<p class="smaller-img"><img src="/images/pure-data/amplitude.png" title="Volume Control Patch" /></p>

Be careful when entering gain values greater than one for this patch. Given that `[osc~]` produces a waveform with a peak of one for amplitude, increasing this value will cause the signal to hard-clip.

By connecting up some additional machinery, we can verify that the signal is being affected as we're expecting. Here's a graph showing the output of the oscillator (you can see that the amplitude looks like one-quarter of the height of the graph, per the 0.25 amplitude factor):

<p class="small-img"><img src="/images/pure-data/volgraph.png" title="Volume Control Patch with Graph" /></p>

It's actually possible for the `[*~]` object to multiply two changing audio signals as well, creating a sort of amplitude/volume modulation. Instead of passing in a constant number, let's replace it with another sine wave so that the volume changes periodically over time. You're able to see how the amplitude of the wave changes from the graph:

<p class="small-img"><img src="/images/pure-data/volmod.png" title="Volume Control Patch with Graph" /></p>

Feel free to experiment with the frequency at which the volume is modulating. By setting the frequency of the modulation to a frequency in the audible spectrum (for example, 880), you can achieve what's known to musicians as a [tremelo](https://en.wikipedia.org/wiki/Tremolo).

Here's a fun exercise: Create a [vibrato](https://en.wikipedia.org/wiki/Vibrato) effect by _ever so slightly_ modulating the frequency, not amplitude, of the original oscillator over time at an audible speed.

## Sample Patch
Next, we're going to take what we now know and turn it into a playable patch. This section is going to cover how to create a classic white-noise based [Hi-Hat](https://en.wikipedia.org/wiki/Hi-hat) instrument.

We're going to start with the `[noise~]` object, an audio generator that outputs [white noise](https://en.wikipedia.org/wiki/White_noise), a random signal with each area of the audible spectrum equally represented. This harsh sound actually can form the basis of many other percussion instruments, such as a snare drum. If you connect `[noise~]` directly to `[dac~]`, you'll hear a sound that's quite harsh, so we're going to filter out some frequencies using a [bandpass filter](https://en.wikipedia.org/wiki/Band-pass_filter).

<p class="smaller-img"><img src="/images/pure-data/noise.png" title="WIP Hi-Hat Patch" /></p>

The `[vcf~]` (voltage-controlled filter) object takes three parameters: an input audio signal to filter, the base frequency at which the filtering will occur, and a Q (resonance) value that determines how "far out" the filtering will reach. Go ahead and connect the output of `[noise~]` to the input of a new `[vcf~]`, with number boxes inputting 1.1kHZ (11000) and 5 for frequency and Q, respectively. Connecting this to `[dac~]` will produce something a _little_ less irritating, however it's still just a constantly playing sound, not an instrument. What we've done here is setup a tight [filter](http://en.flossmanuals.net/pure-data/ch027_filters/) that only allows a specific range of high frequencies from the original signal to come through, emulating the high pitch of a real hi-hat.

<p class="smaller-img"><img src="/images/pure-data/noise-filtered.png" title="WIP Hi-Hat Patch" /></p>

An [ASDR envelope](https://en.wikipedia.org/wiki/Synthesizer#ADSR_envelope) can shape a waveform's amplitude over a period of time, which is what we'll want to be able to trigger. By triggering changes in the amplitude (which should be at zero normally) on a button press, we can get the distinctive short, percussive "blip" sound of a Hi-Hat from this filtered noise. The `[line~]` object is a simple way to accomplish this in Pure Data.

`[line~]` takes a list of amplitudes and times and generates a linearly interpolated audio waveform according to the values passed in. For example, if you use a message box to feed in `1, 0.7 40, 0 30` to `[line~]`, when triggered it will generate a waveform that initially has an amplitude of 1, moves down to 0.7 after 40ms, and falls back down to 0 after 30ms. By multiplying (`*~`) this with our white noise audio signal, we can create a new, snappy signal that varies over time when the envelope is triggered (via a click in Play Mode), and otherwise stays quiet. This is the basis of creating "playable" instruments within Pure Data.

For bonus points, you can hook up a Button to the ASDR message box, providing a more user-friendly (in a way) mechanism to toggle the sound. Clicking the button in Play mode will send a `bang` to the message box, triggering the envelope and temporarily lifting the amplitude.

If you've followed the above, you'll hopefully have something similar to the following:

<p class="small"><img src="/images/pure-data/hihat.png" title="Hi-Hat Patch" /></p>

<audio controls>
  <source src="/audio/pure-data/HiHat.wav" type="audio/wav">
  Your browser does not support the audio element.
</audio>

It turns out that many classic drum synthesizers create sounds in similar (but perhaps more complex) ways. Bass drums can be synthesized using low-frequency sine waves, and snares can be also be created by combining a low-frequency sine wave mixed with some white noise to simulate the "snap". Once you get started here, the possibilities are pretty much endless, only limited by your imagination.

## Further Tips and Notes

#### MidiMock

I've found it helpful to download [MidiMock](https://itunes.apple.com/us/app/midi-mock/id438240325?mt=12) from the App Store, and create a setup similar to the Input Stage of the demo synthesizer from the Pd tutorial on [FLOSS Manuals](http://en.flossmanuals.net/pure-data/ch032_4-stage-sequencer/) to explore your patch more naturally with an onscreen piano.

Check the "Mac OS X" section of the Pure Data documentation on [MIDI Input](https://puredata.info/docs/faq/midiinput) to get your computer wired properly.

#### Max/MSP and Max4Live

[Max/MSP](https://cycling74.com/) and [Max4Live](https://www.ableton.com/en/live/max-for-live/) are two excellent products by Cycling74 and Ableton. The former is a commercial Pure Data-like programming environment with an excellent GUI, documentation, and more, and the latter is a collaboration between C74 and Ableton allowing you to seamlessly interact with Max patches as an Ableton device in your tracks. I would highly recommend both.

#### Other Resources

[FLOSS Manuals](http://en.flossmanuals.net/pure-data/index/) provides an excellent, deep guide to getting started using Pure Data. Additionally, they also maintain a glossary of available [objects](http://en.flossmanuals.net/pure-data/list-of-objects/introduction/).

## Conclusion

Overall, I've found Pure Data/Max wonderful to work with, and it's nice to have the ability to open up some M4L patches and see what's going on under the covers. Additionally, just having the ability to quickly mock up an instrument idea without having to learn a VST library, etc. is phenomenal. Hopefully this guide was able to transfer some of my excitement over to you! My plan for the next article in this series is to build a MIDI-capable, monophonic, two-oscillator synthesizer.
