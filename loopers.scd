/* ***********************************************************************************************
Loopers
# by nova@deviator.si
# GNU General Public Licence
*********************************************************************************************** */

( // Synth definitions

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

( // initialize buffers
(10).do({ |n|

	// initialize a buffer
	~buffers[n] = Buffer.alloc(s, s.sampleRate * 10, 1);
	("initialized buffer"+~buffers[n]).postln;
});
)




( // GUI

"===================== starting loopers GUI =========================".postln;

~window = Window.new("Loopers", Rect(5, 600,width:1200,height:110)).front;

// LOOPERS SECTION
~loopersView  = View.new(~window,Rect(0,0,1200,100));
~loopersView.layout = HLayout();

~loopRecorders = Array.fill(10);
~loopPlayers = Array.fill(10);
~buffers = Array.fill(10);
~volSlider = Array.fill(10);
~midiCc = Array.with(12,13,14,15,28,29,30,31,44,45);

/*
~loopersView.layout.add(
		VLayout(
		Button(~loopersView, Rect())
		.states_([["panic?", Color.white, Color.grey(0.2)],["freed all synths", Color.black, Color.green(0.8)]])
		.action_({ arg button;
			if(button.value == 1, {
				(10).do({ |n|
					~loopPlayers[n].free;
					~loopRecorders[n].free;
					"freed player n...".postln;
				});
			}, {
					(10).do({ |n|

					~loopPlayers[n] = Synth(\LoopPlayer).set(\bufnum, ~buffers[n], \amp, 0, \rate, 1);
					"freed player n...".postln;	});

			});
	)
);

*/


// start iteration
(10).do({ |n|

	// initialize a buffer
	//~buffers[n] = Buffer.alloc(s, s.sampleRate * 10, 1);
	//("initialized buffer"+~buffers[n]).postln;

	~loopersView.layout.add(
		VLayout(

			// play button
			Button(~loopersView, Rect())
			.states_([[""++n, Color.white, Color.grey(0.2)],["play"++n, Color.black, Color.green]])
			.action_({ arg button;
				var player;
				if(button.value == 1, { // if button value is 1 we start a synth
					player = Synth(\LoopPlayer).set(\bufnum, ~buffers[n], \amp, 0, \rate, 1);
					~loopPlayers[n] = player;
					(""+~buffers[n]+"playing ...").postln;
				}, {
						~loopPlayers[n].free;
						(""+~buffers[n]+"stopping playback ...").postln;
				}); // else we free the synth
			}),

			// rec button
			Button(~loopersView, Rect())
			.states_([["rec"++n, Color.white, Color.grey(0.2)],["recording", Color.black, Color.red]])
			.action_({
				arg button;
				if( button.value == 1, {
					var recorder;
					recorder = Synth("BufferRecorder", [\bufnum, ~buffers[n]]);
					~loopRecorders[n] = recorder;

					(""+~buffers[n]+"recording ...").postln;
					AppClock.sched(10.0, {
						button.value = 0;
						// ~loopRecorders[n].free;
						nil; });
				})
			}),



			// reverse/backward button
			Button(~loopersView, Rect())
			.states_([["forward", Color.white, Color.grey(0.2)],["backward", Color.black, Color.grey(0.8)]])
			.action_({ arg button;
				if(button.value == 1, {
					~loopPlayers[n].set(\rate, -1);
					(""+~buffers[n]+"reverse play ...").postln;
					}, { ~loopPlayers[n].set(\rate, 1);
					(""+~buffers[n]+"forward play ...").postln;
				});
			});

		) // end of a VLayout
	);

	~loopersView.layout.add(
		// volume slider
		~volSlider[n] = Slider(~loopersView, Rect(height:30))
		.orientation_(\vertical)
		.value_(0).step_(0.001)
		.action_({ arg gain;
			~loopPlayers[n].set(\amp, gain.value.linexp(0,1,0.01,3,nil)-0.01 * 3);
			(""+~buffers[n]+"gain:"+gain.value).postln;
		})
	);

	MIDIdef.cc(\cc++n, { |val|
		~loopPlayers[n].set(\amp, val/40);
		AppClock.sched(0.1, {
			~volSlider[n].value_(val*0.1);
			val.postln;
			nil;
		});

	}, ~midiCc[n]);
});



/*
MIDIdef.cc(\cc12, { |val|
	~loopPlayers[0].set(\amp, val/70)
}, 12);
*/




~window.onClose_({
	(10).do({ |n|
		// ~buffers[n].free;
		~loopPlayers[n].free;
		~loopRecorders[n].free;
		~midiCc[n].free;
	});
});

)
/*********************************************************************************************/


( // free buffers
(10).do({ |n|
	"freeing buffer"+~buffers[n].postln;
	~buffers[n].free;
});
)

Buffer.freeAll;

///////////////////
~volSlider[0].value_(0);