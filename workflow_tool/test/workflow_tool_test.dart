import 'package:test/expect.dart';
import 'package:workflow_tool/workflow_tool.dart';
import 'package:test/test.dart';

void main() {
  final anyDebugFlavor = anyOf('debug_unopt', 'debug');
  final anyTunedArtifact = anyOf('pi3', 'pi3-64', 'pi4', 'pi4-64');

  test('only build profile & release engines for cpu-tuned targets', () {
    final matrix = generateMatrix();

    expect(
      matrix,
      isNot(contains(allOf(
        containsPair('os', anything),
        containsPair('artifact-name', anyTunedArtifact),
        containsPair('flavor', anyDebugFlavor),
      ))),
    );
  });

  test('don\t build gen_snapshot for cpu-tuned targets', () {
    final matrix = generateMatrix();

    expect(
      matrix,
      isNot(contains(allOf(
        containsPair('os', anything),
        containsPair('artifact-name', anyTunedArtifact),
        containsPair('build-gen-snapshot', true),
      ))),
    );
  });

  test('don\t build gen_snapshot for debug engines', () {
    final matrix = generateMatrix();

    expect(
      matrix,
      isNot(contains(allOf(
        containsPair('os', anything),
        containsPair('runtime-mode', 'debug'),
        containsPair('build-gen-snapshot', true),
      ))),
    );
  });

  test('all targets have a release and profile mode engine', () {
    final matrix = generateMatrix();

    expect(
      matrix,
      containsAll([
        for (final artifact in [
          'pi3',
          'pi3-64',
          'pi4',
          'pi4-64',
          'armv7-generic',
          'aarch64-generic',
          'x64-generic'
        ]) ...[
          allOf(
            containsPair('artifact-name', artifact),
            containsPair('flavor', 'release'),
          ),
          allOf(
            containsPair('artifact-name', artifact),
            containsPair('flavor', 'profile'),
          )
        ]
      ]),
    );
  });

  test('all generic targets have a release and profile mode gen_snapshot', () {
    final matrix = generateMatrix();

    expect(
      matrix,
      containsAll([
        for (final artifact in [
          'armv7-generic',
          'aarch64-generic',
          'x64-generic'
        ]) ...[
          allOf(
            containsPair('artifact-name', artifact),
            containsPair('runtime-mode', 'release'),
            containsPair('build-gen-snapshot', true),
          ),
          allOf(
            containsPair('artifact-name', artifact),
            containsPair('runtime-mode', 'profile'),
            containsPair('build-gen-snapshot', true),
          )
        ]
      ]),
    );
  });

  test(
      'all generic targets have a debug, debug_unopt, release and profile mode engine',
      () {
    final matrix = generateMatrix();

    expect(
      matrix,
      containsAll([
        for (final artifact in [
          'armv7-generic',
          'aarch64-generic',
          'x64-generic'
        ]) ...[
          allOf(
            containsPair('artifact-name', artifact),
            containsPair('flavor', 'debug_unopt'),
          ),
          allOf(
            containsPair('artifact-name', artifact),
            containsPair('flavor', 'debug'),
          ),
          allOf(
            containsPair('artifact-name', artifact),
            containsPair('flavor', 'release'),
          ),
          allOf(
            containsPair('artifact-name', artifact),
            containsPair('flavor', 'profile'),
          )
        ]
      ]),
    );
  });

  test('all gen_snaphots are built from macos and linux', () {
    final matrix = generateMatrix();

    expect(
      matrix,
      containsAll([
        for (final artifact in [
          'armv7-generic',
          'aarch64-generic',
          'x64-generic',
        ])
          for (final runtimeMode in ['release', 'profile'])
            for (final os in ['macos-latest', 'ubuntu-latest'])
              allOf(
                containsPair('artifact-name', artifact),
                containsPair('runtime-mode', runtimeMode),
                containsPair('build-gen-snapshot', true),
                containsPair('os', os),
              ),
      ]),
    );
  });
}
