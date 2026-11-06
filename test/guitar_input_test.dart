import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:riffster/audio/guitar_ear.dart';

InputDevice _device(String label) {
  return InputDevice(id: label, label: label);
}

void main() {
  test('the Rocksmith cable is the guitar, and a room mic is not', () {
    final devices = [
      _device('Microphone Array (AMD Audio Device)'),
      _device('Microphone (Logitech BRIO)'),
      _device('Rocksmith USB Guitar Adapter'),
    ];

    expect(guitarInput(devices)?.label, 'Rocksmith USB Guitar Adapter');
    expect(isRocksmithCable('Real Tone Cable'), isTrue);
    expect(isRocksmithCable('Microphone Array'), isFalse);
  });

  test('the Rocksmith cable wins when an iRig input is also listed', () {
    final devices = [
      _device('Microphone (iRig USB)'),
      _device('Rocksmith USB Guitar Adapter'),
    ];

    expect(guitarInput(devices)?.label, 'Rocksmith USB Guitar Adapter');
  });

  test('an iRig input is used when the Rocksmith cable is absent', () {
    final devices = [
      _device('Microphone Array (AMD Audio Device)'),
      _device('Microphone (iRig USB)'),
    ];

    expect(guitarInput(devices)?.label, 'Microphone (iRig USB)');
  });
}
