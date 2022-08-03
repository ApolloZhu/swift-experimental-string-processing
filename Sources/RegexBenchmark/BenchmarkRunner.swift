import Foundation

struct BenchmarkRunner {
  let suiteName: String
  var suite: [any RegexBenchmark] = []
  
  let samples: Int
  var results: SuiteResult = SuiteResult()
  let quiet: Bool

  init(_ suiteName: String, _ n: Int, _ quiet: Bool) {
    self.suiteName = suiteName
    self.samples = n
    self.quiet = quiet
  }
  
  mutating func register(_ new: some RegexBenchmark) {
    suite.append(new)
  }
  
  mutating func measure(
    benchmark: some RegexBenchmark,
    samples: Int
  ) -> BenchmarkResult {
    var runtimes: [Time] = []
    var compileTimes: [Time] = []
    // Initial run to make sure the regex has been compiled
    benchmark.run()

    // Measure compilataion time
    for _ in 0..<samples {
      let start = Tick.now
      benchmark.compile()
      let end = Tick.now
      let time = end.elapsedTime(since: start)
      compileTimes.append(time)
    }
    
    compileTimes.sort()
    let compileTime = compileTimes[samples/2]
    
    // FIXME: use suspendingclock?
    for _ in 0..<samples {
      let start = Tick.now
      benchmark.run()
      let end = Tick.now
      let time = end.elapsedTime(since: start)
      runtimes.append(time)
    }

    runtimes.sort()
    let median = runtimes[samples/2]
    let sum = runtimes.reduce(0.0) {acc, next in acc + next.seconds}
    let mean = sum / Double(runtimes.count)
    let squareDiffs = runtimes.reduce(0.0) { acc, next in
      acc + pow(next.seconds - mean, 2)
    }
    let stdev = (squareDiffs / Double(runtimes.count)).squareRoot()
    return BenchmarkResult(
      compileTime: compileTime,
      median: median,
      stdev: stdev,
      samples: samples)
  }
  
  mutating func run() {
    print("Running")
    for b in suite {
      var result = measure(benchmark: b, samples: samples)
      if result.stdev > Stats.maxAllowedStdev {
        print("Warning: Standard deviation > \(Time(Stats.maxAllowedStdev)) for \(b.name)")
        print("N = \(samples), median: \(result.median), stdev: \(Time(result.stdev))")
        print("Rerunning \(b.name)")
        result = measure(benchmark: b, samples: result.samples*2)
        print("N = \(result.samples), median: \(result.median), stdev: \(Time(result.stdev))")
        if result.stdev > Stats.maxAllowedStdev {
          fatalError("Benchmark \(b.name) is too variant")
        }
      }
      if result.compileTime > Time.millisecond {
        print("Warning: Abnormally high compilation time, what happened?")
      }
      if !quiet {
        print("- \(b.name) \(result.median) (stdev: \(Time(result.stdev))) (compile time: \(result.compileTime))")
      }
      self.results.add(name: b.name, result: result)
    }
  }
    
  mutating func debug() {
    print("Debugging")
    print("========================")
    for b in suite {
      let result = measure(benchmark: b, samples: samples)
      print("- \(b.name) \(result.median) (stdev: \(Time(result.stdev)))")
      b.debug()
      print("========================")
    }
  }
}
