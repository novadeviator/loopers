/* ***********************************************************************************************
Loopers
# by nova@deviator.si
# GNU General Public Licence

*********************************************************************************************** */

// Synth definitions
(

// buffer recorder
SynthDef( "BufferRecorder", { | bufnum = 0 |

	var input;

	input = SoundIn.ar(0);
	RecordBuf.ar(input, bufnum, doneAction: 2, loop: 0);

}).add;

// LoopPlayer Synth definition
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


/*********************************************************************************************/

( // GUI


"===================== starting loopers GUI =========================".postln;

~window = Window.new("Loopers", Rect(5, 5,width:1350,height:250)).front;


// LOOPERS SECTION ////////////////////////////////////////////////////////////
~loopersView  = View.new(~window,Rect(0,0,1200,100));
~loopersView.layout = HLayout();

// start iteration
(100..109).do({ |n|

	// initialize a buffer
	("init buffer number"+n.value).postln;
	Buffer.alloc(s, s.sampleRate * 10, 1, bufnum:n);


	~loopersView.layout.add(
		VLayout(
			// rec button
			Button(~loopersView, Rect())
			.states_([["rec"++n, Color.white, Color.grey(0.2)],["recording", Color.black, Color.red]])
			.action_({ arg button;
				if( button.value == 1, {
					~recorder0 = Synth("BufferRecorder", [\bufnum, n]);
					("buffer"+n.value+"recording ...").postln;
					AppClock.sched(10.0, { button.value = 0; nil; });
				})
			}),

			// play button
			Button(~loopersView, Rect())
			.states_([["play"++n, Color.white, Color.grey(0.2)],["play"++n, Color.black, Color.green]])
			.action_({ arg button;
				if(button.value == 1, { // if button value is 1 we start a synth
					~loopPlayer0 = Synth(\LoopPlayer).set(\bufnum, n, \amp, 0, \rate, 1);
					("buffer"+n.value+"playing ...").postln;
				}, { ~loopPlayer0.free;
						("buffer"+n.value+"stopping playback ...").postln;
				}); // else we free the synth
			}),

			// reverse/backward button
			Button(~loopersView, Rect())
			.states_([["forward", Color.white, Color.grey(0.2)],["backward", Color.black, Color.grey(0.8)]])
			.action_({ arg button;
				if(button.value == 1, {
					~loopPlayer0.set(\rate, -1);
					("buffer"+n.value+"reverse play ...").postln;
				}, { ~loopPlayer0.set(\rate, 1);
					("buffer"+n.value+"forward play ...").postln;
				});
			});

		) // end of a VLayout
	);

	~loopersView.layout.add(
		// volume slider
		Slider(~loopersView, Rect(height:30))
		.orientation_(\vertical)
		.value_(0).step_(0.001)
		.action_({ arg gain;
			~loopPlayer0.set(\amp, gain.value.linexp(0,1,0.01,3,nil)-0.01 * 3);
			("player"+n.value+"gain:"+gain.value).postln;
		})
	);
});

)

/*********************************************************************************************/







