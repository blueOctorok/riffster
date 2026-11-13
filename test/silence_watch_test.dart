import 'package:flutter_test/flutter_test.dart';
import 'package:riffster/audio/silence_watch.dart';

void main() {
  test('an open input that sends nothing is reopened on the second look', () {
    final watch = SilenceWatch();

    expect(watch.look(open: true), isFalse);
    expect(watch.silent, isFalse);
    expect(watch.look(open: true), isTrue);
    expect(watch.silent, isTrue);
  });

  test('a dead input is retried every second look, and stays silent', () {
    final watch = SilenceWatch();
    watch
      ..look(open: true)
      ..look(open: true);

    expect(watch.look(open: true), isFalse);
    expect(watch.silent, isTrue);
    expect(watch.look(open: true), isTrue);
  });

  test('sound between looks keeps the input open', () {
    final watch = SilenceWatch();

    for (var look = 0; look < 5; look++) {
      watch.heard();
      expect(watch.look(open: true), isFalse);
    }
    expect(watch.silent, isFalse);
  });

  test('one empty look right after opening is forgiven', () {
    final watch = SilenceWatch();

    expect(watch.look(open: true), isFalse);
    watch.heard();
    expect(watch.look(open: true), isFalse);
    // The count started over, so this is a first empty look again.
    expect(watch.look(open: true), isFalse);
  });

  test('sound arriving again clears the silence', () {
    final watch = SilenceWatch();
    watch
      ..look(open: true)
      ..look(open: true);
    expect(watch.silent, isTrue);

    watch.heard();
    expect(watch.look(open: true), isFalse);
    expect(watch.silent, isFalse);
  });

  test('inputs that are switched off are never called silent', () {
    final watch = SilenceWatch();

    for (var look = 0; look < 5; look++) {
      expect(watch.look(open: false), isFalse);
    }
    expect(watch.silent, isFalse);
  });
}
