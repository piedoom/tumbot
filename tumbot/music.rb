require 'midilib'
include MIDI

module Tumbot
	class Music

		attr_accessor :en, :qn, :wn, :filename

		def initialize
			@seq = Sequence.new()
			@track = Track.new(@seq)
			@track.events << Tempo.new(Tempo.bpm_to_mpq(180))
			@track.events << MetaEvent.new(META_SEQ_NAME, 'Sequence Name')
			@filename = nil
	
			#create a track to hold notes
			@track = Track.new(@seq)
			@seq.tracks << @track
	
			#give instruments
			@track.name = 'My new Track'
			@track.instrument = GM_PATCH_NAMES[0]
			# Add a volume controller event (optional).
			@track.events << Controller.new(0, CC_VOLUME, 127)
			# Add events to the track: a major scale. Arguments for note on and note off
			# # constructors are channel, note, velocity, and delta_time. Channel numbers
			# # start at zero. We use the new Sequence#note_to_delta method to get the
			# delta time length of a single quarter note.
			@track.events << ProgramChange.new(0, 0, 0)

			#set general times for later use
			@en = @seq.note_to_delta('eighth')
			@qn = @seq.note_to_delta('quarter')
			@wn = @seq.note_to_delta('whole')
			
					
			# a two dimensional array of chords
			@chordbank = {
				'maj': [
					# major third
					[0,4], 
					# major triad
					[0,4,7],
					# major seventh
					[0,4,7,10],
					# major triad octave
					[0,4,7,12],
					# ?
					[0,5,9],
				], 
				'min': [
					# minor third
					[0,3], 
					# minor triad
					[0,3,7],
					# minor seventh
					[0,3,7,10]
				], 
				'per': [
					# single note
					[0],
					# fourth
					[0,5],
					# fifth
					[0,7]
				]
			}
		end

		# happy emotions are true
		# octave adds a bass note
		def random_chord is_happy=true, octave=true
			# since perfect chords exist in major and minor comps, we'll combine them
			major = @chordbank[:maj] #+ @chordbank[:per]
			minor = @chordbank[:min] #+ @chordbank[:per]
			chord = is_happy ? major[rand(0..major.length - 1)] : minor[rand(0..minor.length - 1)]
			chord.unshift(-12) if octave
		end

		def chordprog
			[-7,-5,0,5,7].sample
		end

		def random_time
			[@en, @qn, @wn].sample
		end

		# channel, pitch, velocity, duration
		def chord_builder notes, pitch=0, velocity=127, duration=@quarter_note, channel=0
			# add bass note
			notes.each do |note|
				#@track.events << NoteOn.new(0, 64 + pitch + note, velocity, 0) 
				@track.events << MIDI::NoteOnEvent.new(channel, 64 + pitch + note, velocity)
			end
			notes.each_with_index do |note, i|
				# fixes weird duration staggering
				@track.events << MIDI::NoteOffEvent.new(channel, 64 + pitch + note, velocity, duration - duration*i)
			end
		end

		# creates song with major chords if happy, minor if sad
		def create_song is_happy
			rand(4..8).times do
				chord_builder(random_chord(is_happy), chordprog, rand(59..127), random_time)
			end
		end

		def save_and_render
			# make sure song isn't cut off when rendered.  this is pretty hacky.
			@track.events << NoteOn.new(0,0,0,0)
			@track.events << NoteOff.new(0,0,0,7000)
			songname = Time.now.to_i
			basepath = "./tumbot/"
			# selecting a random soundfont
			soundfont = (Dir.entries(basepath + "soundfont").select {|f| !File.directory? f}).sample

			# this is all very bad programming and very vulnerable.
			# like this is seriously BAD
			# sorry
			File.open(basepath + "songs/midi/#{songname}.mid", 'wb') { |file| @seq.write(file) }
			system "fluidsynth -R on -C on -F #{basepath}/songs/rendered/#{songname}.wav #{basepath}soundfont/#{soundfont} #{basepath}/songs/midi/#{songname}.mid"
			system "sox #{basepath}songs/rendered/#{songname}.wav #{basepath}songs/rendered/#{songname}_new.wav reverb -w 100 speed 1"
			system "lame -V2 #{basepath}songs/rendered/#{songname}_new.wav #{basepath}songs/rendered/#{songname}.mp3 && rm #{basepath}songs/rendered/#{songname}.wav && rm #{basepath}/songs/rendered/#{songname}_new.wav"
			@filename = "#{basepath}songs/rendered/#{songname}.mp3"

		end
	end
end


#song = Tumbot::Music.new
## create a happy song
#song.create_song true
#song.save_and_render()
#song.filename
