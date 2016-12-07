# mobile-sensing-apps
Projects for CSE 5/7323 Mobile Sensing and Learning with Professor Eric Larson

#TODO

###Sound samples:
YEAH HO

Bass drum

Floor tom

Snare drum

Hanging toms

Hi-hat

Crash cymbal/Ride cymbal

###Recording capabilities:
Not interpreted, simply records an audio file from the microphone out, which is timestamped, not a compilation of the sounds played or anything like that

###Build your own kit:
Have a UI picture element that is a drumset silhouette that has selectable "zones" that allow for selecting which parts of the drum you want to play (default: all)

###ML Stuff:
Keeping Random Forest and existing web stack as a stop gap measure

Logistic Regression has relatively poor correlation - "we'll see if it's ass" - but this should allow us to get local calc to get rid of the web dependency for training

###Core Motion:
Tweaks to orientation awareness, hit detection, actually use fft, instead of time domain boundaries as a .5 second sample determine beginning and end of gestures

###Core Audio:
Have multiple players so we can stack samples instead of having a playback queue, so writing audio to the buffer is not blocking

##OPTIONAL
###Tutorial mode:
Where we have simple animations to show how to perform specific gestures

###Web fixes
fix tornado's ioloop to be not blocking
