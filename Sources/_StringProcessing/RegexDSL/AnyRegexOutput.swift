//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021-2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import _MatchingEngine

extension Regex where Output == AnyRegexOutput {
  public init(_ pattern: String) throws {
    self.init(ast: try parse(pattern, .traditional))
  }
}

extension Regex.Match where Output == AnyRegexOutput {
  // Ensures `.0` always refers to the whole match.
  public subscript(
    dynamicMember keyPath: KeyPath<(Substring, _doNotUse: ()), Substring>
  ) -> Substring {
    input[range]
  }
}

public struct AnyRegexOutput {
  let input: String
  fileprivate let _elements: [ElementRepresentation]

  /// The underlying representation of the element of a type-erased regex
  /// output.
  fileprivate struct ElementRepresentation {
    /// The depth of `Optioals`s wrapping the underlying value. For example,
    /// `Substring` has optional depth `0`, and `Int??` has optional depth `2`.
    let optionalDepth: Int
    /// The bounds of the output element.
    let bounds: Range<String.Index>?
  }
}

extension AnyRegexOutput {
  /// Creates a type-erased regex output from an existing output.
  ///
  /// Use this initializer to fit a regex with strongly typed captures into the
  /// use site of a dynamic regex, i.e. one that was created from a string.
  public init<Output>(_ match: Regex<Output>.Match) {
    // Note: We use type equality instead of `match.output as? ...` to prevent
    // unexpected optional flattening.
    if Output.self == AnyRegexOutput.self {
      self = match.output as! AnyRegexOutput
      return
    }
    fatalError("FIXME: Not implemented")
    // self.init(input: match.input, _elements: <elements of output tuple>)
  }
}

extension AnyRegexOutput {
  internal init<C: Collection>(
    input: String, elements: C
  ) where C.Element == StructuredCapture {
    self.init(input: input, _elements: elements.map(ElementRepresentation.init))
  }
}

extension AnyRegexOutput.ElementRepresentation {
  init(_ element: StructuredCapture) {
    self.init(
      optionalDepth: element.optionalCount,
      bounds: element.storedCapture.flatMap(\.range))
  }

  func value(forInput input: String) -> Any {
    // Ok for now because `existentialMatchComponent`
    // wont slice the input if there's no range to slice with
    //
    // FIXME: This is ugly :-/
    let input = bounds.map { input[$0] } ?? ""

    return constructExistentialOutputComponent(
      from: input,
      in: bounds,
      value: nil,
      optionalCount: optionalDepth)
  }
}

extension AnyRegexOutput: RandomAccessCollection {
  public struct Element {
    fileprivate let representation: ElementRepresentation
    let input: String

    public var range: Range<String.Index>? {
      representation.bounds
    }

    public var substring: Substring? {
      range.map { input[$0] }
    }
  }

  public var startIndex: Int {
    _elements.startIndex
  }

  public var endIndex: Int {
    _elements.endIndex
  }

  public var count: Int {
    _elements.count
  }

  public func index(after i: Int) -> Int {
    _elements.index(after: i)
  }

  public func index(before i: Int) -> Int {
    _elements.index(before: i)
  }

  public subscript(position: Int) -> Element {
    .init(representation: _elements[position], input: input)
  }
}
