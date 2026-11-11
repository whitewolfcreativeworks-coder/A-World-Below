#!/usr/bin/env python3
"""Render original MIT-licensed looping cues. Offline production only: NumPy + ffmpeg."""
from pathlib import Path
import numpy as np
import wave, subprocess

ROOT = Path(__file__).resolve().parents[1]
RATE, SECONDS = 22050, 32
t = np.arange(RATE * SECONDS) / RATE
out = ROOT / 'assets/audio'
out.mkdir(exist_ok=True)
chords = [(110, 130.8128, 164.8138), (87.3071, 110, 130.8128),
          (130.8128, 164.8138, 195.9977), (97.9989, 123.4708, 146.8324)]
for genre in ('ambient', 'electronic', 'downtempo', 'piano'):
    y = np.zeros_like(t)
    for index, chord in enumerate(chords):
        start = index * 8
        local = t - start
        envelope = np.where((local >= 0) & (local < 8), np.sin(np.pi * np.clip(local / 8, 0, 1)) ** 2, 0)
        for frequency in chord:
            y += .055 * envelope * np.sin(2*np.pi*frequency*t)
            y += .018 * envelope * np.sin(2*np.pi*frequency*2*t)
        if genre != 'ambient':
            for beat in range(16):
                age = t - (start + beat*.5)
                active = (age >= 0) & (age < 1.8)
                note = chord[beat % 3] * (4 if genre == 'piano' else 2)
                decay = np.exp(-np.maximum(age,0)*(4 if genre == 'piano' else 7)) * active
                y += .14 * decay * (np.sin(2*np.pi*note*age) + .25*np.sin(2*np.pi*note*2*age))
                if genre in ('electronic','downtempo') and beat % (2 if genre == 'electronic' else 4) == 0:
                    a = np.maximum(age, 0)
                    y += .18 * np.exp(-a*20) * active * np.sin(2*np.pi*(48*a + 2*(1-np.exp(-a*25))))
    # All envelopes return to zero at the loop boundary; allow Ogg encoder padding.
    y = np.tanh(y * 1.4) * .65
    wav = Path('/tmp/awb-' + genre + '.wav')
    with wave.open(str(wav), 'wb') as f:
        f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        f.writeframes((y*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-loglevel','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','3',str(out/(genre+'.ogg'))],check=True)
    print(genre, (out/(genre+'.ogg')).stat().st_size)
