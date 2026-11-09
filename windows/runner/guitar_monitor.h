#ifndef RUNNER_GUITAR_MONITOR_H_
#define RUNNER_GUITAR_MONITOR_H_

#include <flutter/binary_messenger.h>
#include <windows.h>

// Opens the guitar cable in exclusive mode and copies each buffer straight
// to the speakers on an audio thread. Dart only receives a copy for pitch.
void GuitarMonitorAttach(HWND hwnd, flutter::BinaryMessenger* messenger);
void GuitarMonitorDetach();

// True when |message| was the PCM ping and has been handled.
bool GuitarMonitorHandleMessage(UINT message);

#endif  // RUNNER_GUITAR_MONITOR_H_
