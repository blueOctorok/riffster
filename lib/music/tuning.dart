import '../audio/pitch.dart';
import '../models/instrument.dart';

/// A string this close to its pitch is called in tune. A cent is a
/// hundredth of a semitone, and five is about as fine as an ear hears.
const inTuneCents = 5.0;

/// The open string a sound of [hertz] is closest to, and how far from
/// that string's pitch it is. Below zero is flat.
///
/// [string] counts from 0 at the top of the staff, the highest string,
/// which is the order [Instrument.stringNames] is in.
///
/// A tuner that names the nearest note calls a D string that has
/// slipped 60 cents "C sharp, and a little sharp". Measuring against
/// the strings says "D, 60 cents flat", which is the thing to fix.
({int string, double cents}) nearestString(
  double hertz,
  Instrument instrument,
) {
  final heard = midiOfHertz(hertz);
  final open = instrument.openStringMidi;
  var string = 0;
  for (var index = 1; index < open.length; index++) {
    if ((heard - open[index]).abs() < (heard - open[string]).abs()) {
      string = index;
    }
  }
  return (string: string, cents: (heard - open[string]) * 100);
}
