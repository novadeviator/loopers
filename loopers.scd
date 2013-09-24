/* ***********************************************************************************************
Loopers

# by nova@deviator.si
# GNU General Public Licence

ROADMAP/TODO:
- recording live input into a buffer (10s?) (auto resizable?)
- control input level
- monitor input level

- playing back buffer contents - loopable
- playing in reverse
- control output level
- monitor output level

- multiple instances!

- reverb on input signal
- control amount of reverb on input signal
- reverb on output signal
- control amount of reverb in output signal

ADVANCED/FUTURE:
- view the waveform
- normalize
- set IN/OUT points of the loop
- waveform zoomout regardless of length of the buffer
- autosave buffers into soundfiles immediately after they are recorded
- switch to any previously recorded sounds
- prelisten a buffer on alternative output (3-4th channel?)
- be channel-agnostic (can record and playback n-channel buffers)?

*********************************************************************************************** */

/************************************************************************************************/

// init 10 buffers from 0-9
(0..9).collect({ |n|
	Buffer.alloc(s, s.sampleRate * 10, 1, bufnum:n)
});

( // buffer recorder Synth definition
SynthDef( "BufferRecorder", { | bufnum = 0 |

	var input;

	input = SoundIn.ar(0);
	RecordBuf.ar(input, bufnum, doneAction: 2, loop: 0);

}).add;
)


( // LoopPlayer Synth definition
SynthDef( "LoopPlayer", {

	arg amp=0, rate=1, bufnum=0;
	var out, imp, delimp, outlevel;

	out = BufRd.ar(
		numChannels: 1,
		bufnum: bufnum,
		phase: Phasor.ar( trig:1, rate: rate, start:0, end:BufFrames.kr(bufnum), resetPos:0 )
	) * amp;

	out = FreeVerb.ar(
		in:out,
		mix:LFNoise1.kr(0.2, 0.25, 0.5),
		// mix:0.6,
		room:0.9,
		damp:0.3 );

	imp = Impulse.kr(10);
    delimp = Delay1.kr(imp);
	outlevel = '/outputlevel'++bufnum;
	SendReply.kr(imp, outlevel, [Amplitude.kr(out), K2A.ar(Peak.ar(out, delimp).lag(0, 3))]);
	//outlevel.postln;

	Out.ar( // output
		[0,1], // stereo
		out );

}).add;
)
/*
(
// meter Input levels
x = { var input, noise, imp, delimp, mul = 1;
    imp = Impulse.kr(10);
    delimp = Delay1.kr(imp);
	input = SoundIn.ar(0) * mul;
    // measure rms and Peak
    SendReply.kr(imp, '/inputlevels', [Amplitude.kr(input), K2A.ar(Peak.ar(input, delimp).lag(0, 3))]);
    input * 0;
}.play;
)
*/
/*********************************************************************************************/

( // GUI



~window = Window.new("Loopers", Rect(5, 5,width:1350,height:250)).front;


// LOOPERS SECTION ////////////////////////////////////////////////////////////
~loopersView  = View.new(~window,Rect(0,0,1200,100));
~loopersView.layout = HLayout();
/*

~loopersView.layout.add(
	~inputLevelIndicator = LevelIndicator(~window, Rect(10,10,4,84)).maxWidth_(4);

			o = OSCFunc( {arg msg;
				{
					~inputLevelIndicator.value = msg[3].ampdb.linlin(-40, 0, 0, 1);
					~inputLevelIndicator.peakLevel = msg[4].ampdb.linlin(-40, 0, 0, 1);
					~inputLevelIndicator.warning_(-6.dbamp);
					~inputLevelIndicator.critical_(-3.dbamp);
					~inputLevelIndicator.drawsPeak_(true);
					~inputLevelIndicator.background_(Color.clear);
					}.defer;
				}, '/inputlevels', s.addr);
	);
*/


// start iteration
(0..9).do({ |n|
	~loopersView.layout.add(
		VLayout(
			// rec button
			Button(~loopersView, Rect())
			.states_([["rec"++n, Color.white, Color.grey(0.2)],["recording", Color.black, Color.red]])
			.action_({ arg button;
				if( button.value == 1, {
					~recorder0 = Synth("BufferRecorder", [\bufnum, n]);
					AppClock.sched(10.0, { button.value = 0; nil; });
				})
			}),

			// play button
			Button(~loopersView, Rect())
			.states_([["play"++n, Color.white, Color.grey(0.2)],["play"++n, Color.black, Color.green]])
			.action_({ arg button;
				if(button.value == 1, { // if button value is 1 we start a synth
					~loopPlayer0 = Synth(\LoopPlayer).set(\bufnum, n, \amp, 0, \rate, 1);
				}, { ~loopPlayer0.free; }); // else we free the synth
			}),

			// reverse/backward button
			Button(~loopersView, Rect())
			.states_([["forward", Color.white, Color.grey(0.2)],["backward", Color.black, Color.grey(0.8)]])
			.action_({ arg button;
				if(button.value == 1, {
					~loopPlayer0.set(\rate, -1);
				}, { ~loopPlayer0.set(\rate, 1); });
			});

		) // end of a VLayout
	);

	~loopersView.layout.add(
		// volume slider
		Slider(~loopersView, Rect(height:30))
		.orientation_(\vertical)
		.value_(0).step_(0.001)
		.action_({ arg gain; ~loopPlayer0.set(\amp, gain.value.linexp(0,1,0.01,3,nil)-0.01 * 3);
			gain.value.postln; })
	);

/*
	// output level meter
	~loopersView.layout.add(

		~outputLevelIndicator++n = LevelIndicator(~loopersView, Rect(0,0,4,100));
				o = OSCFunc( {arg msg;
					{	~outputLevelIndicator++n.value = msg[3].ampdb.linlin(-40, 0, 0, 1);
						~outputLevelIndicator++n.peakLevel = msg[4].ampdb.linlin(-40, 0, 0, 1);
						~outputLevelIndicator++n.warning_(-6.dbamp);
						~outputLevelIndicator++n.critical_(-3.dbamp);
						~outputLevelIndicator++n.drawsPeak_(true);
						~outputLevelIndicator++n.background_(Color.clear);
					}.defer;
				}, '/outputlevel'++n, s.addr);
	);
*/
});





)











/*********************************************************************************************/
/*********************************************************************************************/
/*********************************************************************************************/
// SCRATCH AREA! //////////////////////////////////////////////////////////////////////////////




// actually record!
Synth("BufferRecorder", [\bufnum, 0]);
Synth("BufferRecorder", [\bufnum, 1]);


~loopPlayer0 = Synth(\LoopPlayer).set(\bufnum, 0, \amp, 1, \rate, -1);

~loopPlayer0 = Synth(\LoopPlayer).set(\bufnum, 0);
~loopPlayer0.set(\amp, 1);
~loopPlayer0.set(\rate, -1);

~loopPlayer9 = Synth(\LoopPlayer).set(\bufnum, 9, \amp, 1, \rate, -1);
~loopPlayer4 = Synth(\LoopPlayer).set(\bufnum, 4, \amp, 1, \rate, -1);

~loopPlayer1.free;
~loopPlayer4.set(\amp, 0);
m.set(\rate, -1);
m.free


m.set(\bufnum, b, \rate, -1, \amp, 1);
m.set(\rate,0);
m.free;







// how to record live input into a 10sec buffer?

Buffer.alloc(s, s.sampleRate * 10, 1, bufnum:(0..9));
Buffer.alloc(s, s.sampleRate * 10, 1, bufnum:9);



(
x = SynthDef( "loop-rec1", { arg out=0, bufnum=0;
	var input;
	input = SoundIn.ar(0);
	// doneAction:2 is very important, otherwise your synth will continue to write into the buffer..
	RecordBuf.ar(input, bufnum, doneAction: 2, loop: 0);
}).play(s, [\out, 0, \bufnum, b]);
)

// draw it
b.plot(minval:-1,maxval:1);
/*
y = Window.screenBounds.height - 120;
w = Window.new("soundfile test", Rect(200, y, 740, 100)).alwaysOnTop_(true);
w.front;
a = SoundFileView.new(w, Rect(20,20, 700, 60));

z=SoundFileView.new;
a.setData(b);
*/











/*********************************************************************************************/

( // GUI



~window = Window.new("Loopers").front;

~window.layout = HLayout();

// start iteration
(0..9).do({|n|
	~window.layout.add (Button(~window, Rect()).states_([[n, Color.white, Color.grey(0.2)]]));



		}) // end of iteration


) // GUI ends here

/*********************************************************************************************/













(
~window.layout_(
	VLayout(
		HLayout(

			~inputLevelIndicator = LevelIndicator(~window, Rect(10,10,4,100)).maxWidth_(4),

			o = OSCFunc( {arg msg;
				{
					~inputLevelIndicator.value = msg[3].ampdb.linlin(-40, 0, 0, 1);
					~inputLevelIndicator.peakLevel = msg[4].ampdb.linlin(-40, 0, 0, 1);
					~inputLevelIndicator.warning_(-6.dbamp);
					~inputLevelIndicator.critical_(-3.dbamp);
					~inputLevelIndicator.drawsPeak_(true);
					~inputLevelIndicator.background_(Color.clear);
					}.defer;
				}, '/inputlevels', s.addr);



			// start iteration
			// (0..9).do({|n|

				VLayout(

					// rec button
					Button(~window, Rect())
					.states_([["rec", Color.white, Color.grey(0.2)],["rec", Color.black, Color.red]])
					.action_({ arg button;
						if( button.value == 1, {
							~recorder0 = Synth("BufferRecorder", [\bufnum, n]);
							AppClock.sched(10.0, { button.value = 0; nil; });
						})
					}),

					// play button
					Button(~window, Rect())
					.states_([["play", Color.white, Color.grey(0.2)],["play", Color.black, Color.green]])
					.action_({ arg button;
						if(button.value == 1, {
							~loopPlayer0 = Synth(\LoopPlayer).set(\bufnum, n, \amp, 0, \rate, 1); // if button value is 1 we start a synth
						}, { ~loopPlayer0.free; }); // else we free the synth
					}),

					// reverse/backward button
					Button(~window, Rect())
					.states_([["forward", Color.white, Color.grey(0.2)],["backward", Color.black, Color.grey(0.8)]])
					.action_({ arg button;
						if(button.value == 1, {
							~loopPlayer0.set(\rate, -1);
						}, { ~loopPlayer0.set(\rate, 1); });
					});

				),  // end of a VLayout

				// volume slider
				Slider(~window, Rect(height:30))
				.orientation_(\vertical)
				.value_(0).step_(0.001)
				.action_({ arg gain; ~loopPlayer0.set(\amp, gain.value.linexp(0,1,0.01,3,nil)-0.01 * 3); }),

				// output level meter
				~outputLevelIndicator = LevelIndicator(~window, Rect(10,10,4,100)),
				o = OSCFunc( {arg msg;
					{	~outputLevelIndicator.value = msg[3].ampdb.linlin(-40, 0, 0, 1);
						~outputLevelIndicator.peakLevel = msg[4].ampdb.linlin(-40, 0, 0, 1);
						~outputLevelIndicator.warning_(-6.dbamp);
						~outputLevelIndicator.critical_(-3.dbamp);
						~outputLevelIndicator.drawsPeak_(true);
						~outputLevelIndicator.background_(Color.clear);
					}.defer;
				}, '/outputlevel0', s.addr);



			// }) // end of iteration

	nil, nil
	), // end of HLayout
	nil, nil
	) // end of VLayout
) // end of ~window.layout_

) // GUI ends here

/*********************************************************************************************/







