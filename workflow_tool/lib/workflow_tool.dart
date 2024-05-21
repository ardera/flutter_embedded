const kRunnerImage = 'os';
const kRunnerImageNice = 'os-nice';
const kBuildEngine = 'build-engine';
const kBuildUniversal = 'build-universal';
const kFlavor = 'flavor';
const kRuntimeMode = 'runtime-mode';
const kUnoptimized = 'unoptimized';
const kNoStripped = 'nostripped';
const kSplitDebugSymbols = 'split-debug-symbols';
const kArtifactName = 'artifact-name';
const kCPU = 'cpu';
const kArmCPU = 'arm-cpu';
const kArmTune = 'arm-tune';
const kBuildX64GenSnapshot = 'build-x64-gen-snapshot';
const kBuildARMGenSnapshot = 'build-arm-gen-snapshot';
const kBuildARM64GenSnapshot = 'build-arm64-gen-snapshot';
const kX64GenSnapshotPath = 'x64-gen-snapshot-path';
const kARMGenSnapshotPath = 'arm-gen-snapshot-path';
const kARM64GenSnapshotPath = 'arm64-gen-snapshot-path';
const kJobName = 'job-name';

enum GithubRunner {
  ubuntuLatest('ubuntu-latest', 'Linux', OS.linux),
  macosLatest('macos-latest', 'MacOS', OS.macOS, arch: Arch.arm64),
  macos13('macos-13', 'MacOS', OS.macOS, arch: Arch.x64),
  windowsLatest('windows-latest', 'Windows', OS.windows);

  const GithubRunner(this.name, this.nice, this.os, {this.arch = Arch.x64});

  final String name;
  final String nice;
  final OS os;
  final Arch arch;

  @override
  String toString() => name;
}

enum OS {
  macOS,
  linux,
  windows;

  @override
  String toString() {
    return name;
  }
}

enum Arch {
  x64('X64', 'x64', 'x64'),
  arm('ARM', 'arm', 'armv7'),
  arm64('ARM64', 'arm64', 'aarch64');

  const Arch(this.ghActionsName, this.flutterCpu, this.ciName);

  final String ghActionsName;
  final String flutterCpu;
  final String ciName;

  @override
  String toString() => ciName;
}

enum CPU {
  generic('generic', 'generic'),
  pi3('cortex-a53+nocrypto', 'cortex-a53'),
  pi4('cortex-a72+nocrypto', 'cortex-a72');

  const CPU(this.compilerCpu, this.cmopilerTune);

  final String compilerCpu;
  final String cmopilerTune;

  @override
  String toString() => name;
}

enum Target {
  armv7Generic(arch: Arch.arm, name: 'armv7-generic'),
  aarch64Generic(arch: Arch.arm64, name: 'aarch64-generic'),
  x64Generic(arch: Arch.x64, name: 'x64-generic'),
  pi3(arch: Arch.arm, cpu: CPU.pi3, name: 'pi3'),
  pi3_64(arch: Arch.arm64, cpu: CPU.pi3, name: 'pi3-64'),
  pi4(arch: Arch.arm, cpu: CPU.pi4, name: 'pi4'),
  pi4_64(arch: Arch.arm64, cpu: CPU.pi4, name: 'pi4-64');

  const Target({
    this.os = OS.linux,
    required this.arch,
    this.cpu = CPU.generic,
    required this.name,
  });

  final OS os;
  final Arch arch;
  final CPU cpu;
  final String name;

  @override
  String toString() => name;
}

enum RuntimeMode {
  debug(false),
  profile(true),
  release(true);

  const RuntimeMode(this.isAOT);

  final bool isAOT;

  @override
  String toString() => name;
}

enum Flavor {
  debugUnopt('debug_unopt', RuntimeMode.debug, true),
  debug('debug', RuntimeMode.debug, false),
  profile('profile', RuntimeMode.profile, false),
  release('release', RuntimeMode.release, false);

  const Flavor(
    this.name,
    this.runtimeMode,
    this.unoptimized,
  );

  final String name;
  final RuntimeMode runtimeMode;
  final bool unoptimized;

  bool get buildGenSnapshot => runtimeMode.isAOT;

  @override
  String toString() => name;
}

Map<String, Object> genTargetConfig(Target target) {
  return {
    kArtifactName: target.toString(),
    kCPU: target.arch.flutterCpu,

    /// TODO: add arm64_cpu and arm64_tune
    if (target.arch == Arch.arm || target.arch == Arch.arm64) ...{
      kArmCPU: target.cpu.compilerCpu,
      kArmTune: target.cpu.cmopilerTune,
    }
  };
}

Map<String, Object> genEngineConfig(Flavor flavor) {
  return {
    kBuildEngine: true,
    kFlavor: flavor.toString(),
    kRuntimeMode: flavor.runtimeMode.toString(),
    kUnoptimized: flavor.unoptimized,
    kSplitDebugSymbols: true,
    kNoStripped: true,
  };
}

Map<String, Object> genRunnerConfig(GithubRunner runner) {
  return {
    kRunnerImage: runner.name,
    kRunnerImageNice: runner.nice,
  };
}

Map<String, Object> genGenSnapshotConfig(
  RuntimeMode mode, {
  required GithubRunner runner,
  required Target target,
}) {
  assert(mode.isAOT);

  return {
    kFlavor: switch (mode) {
      RuntimeMode.profile => Flavor.profile,
      RuntimeMode.release => Flavor.release,
      _ => throw StateError('Invalid runtime mode: $mode')
    }
        .toString(),
    kRuntimeMode: mode.toString(),

    // We can only cross-compile the gen_snapshots on linux right now.
    kBuildARMGenSnapshot: runner.os == OS.linux || runner.arch == Arch.arm,
    kBuildARM64GenSnapshot: runner.os == OS.linux || runner.arch == Arch.arm64,
    kBuildX64GenSnapshot: runner.os == OS.linux || runner.arch == Arch.x64,

    kX64GenSnapshotPath: runner.os == target.os && runner.arch == Arch.x64
        ? 'gen_snapshot'
        : 'clang_x64/gen_snapshot',
    kARMGenSnapshotPath: runner.os == target.os && runner.arch == Arch.arm
        ? 'gen_snapshot'
        : 'clang_arm/gen_snapshot',
    kARM64GenSnapshotPath: runner.os == target.os && runner.arch == Arch.arm64
        ? 'gen_snapshot'
        : 'clang_arm64/gen_snapshot',
  };
}

Object generateMatrix() {
  final jobs = <Map<String, dynamic>>[];

  void addJob(Map<String, dynamic> job) {
    jobs.add(job);
  }

  final targets = Target.values;

  final flavors = Flavor.values;
  final runtimeModes = RuntimeMode.values;
  final aotRuntimeModes = runtimeModes.where((mode) => mode.isAOT).toList();
  final runners = {GithubRunner.ubuntuLatest, GithubRunner.macos13};

  for (final target in targets) {
    final targetConfig = genTargetConfig(target);

    // For the tuned targets, we only build the profile and release mode engine.
    // Doesn't make sense to have a tuned version for a debug build.
    final flavorsToBuild =
        target.cpu == CPU.generic ? flavors : [Flavor.profile, Flavor.release];

    for (final flavor in flavorsToBuild) {
      // add the engine build job for that target

      // if we're building for generic CPUs, additionally build the gen_snapshot.
      final buildGenSnapshot =
          target.cpu == CPU.generic && flavor.buildGenSnapshot;

      if (buildGenSnapshot) {
        for (final runner in runners) {
          final buildEngine = runner.os == OS.linux;

          addJob({
            if (buildEngine)
              kJobName:
                  'build engine, gen_snapshot (for: ${target.os} $target $flavor, host: ${runner.os})'
            else
              kJobName:
                  'build gen_snapshot (for: ${target.os} $target $flavor, host: ${runner.os})',
            ...targetConfig,

            // Only build the engine on the linux runner.
            if (buildEngine) ...genEngineConfig(flavor),

            ...genGenSnapshotConfig(
              flavor.runtimeMode,
              runner: runner,
              target: target,
            ),

            ...genRunnerConfig(runner),
          });
        }
      } else {
        addJob({
          kJobName: 'build engine (for: ${target.os} $target $flavor)',
          ...targetConfig,
          ...genEngineConfig(flavor),
          ...genRunnerConfig(GithubRunner.ubuntuLatest),
        });
      }
    }
  }

  // add a job that builds the universal artifacts (flutter_embedder.h,
  // icudtl.dat)
  addJob({
    kJobName: 'build universal artifacts',
    kArtifactName: 'universal',
    kRunnerImage: 'ubuntu',
    kNoStripped: false,
    kBuildEngine: false,
    kBuildARMGenSnapshot: false,
    kBuildARM64GenSnapshot: false,
    kBuildX64GenSnapshot: false,
    kBuildUniversal: false,
    kSplitDebugSymbols: false,
  });

  return jobs;
}
