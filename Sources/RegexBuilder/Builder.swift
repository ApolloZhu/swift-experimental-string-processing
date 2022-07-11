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

@_spi(RegexBuilder) import _StringProcessing

@available(SwiftStdlib 5.7, *)
@resultBuilder
public enum RegexComponentBuilder {
  // TODO: ApolloZhu doc
  // TODO: ApolloZhu availability marker
  public struct Component<Value: RegexComponent>: RegexComponent {
    private let value: Value
    private let debugInfoProvider: DSLDebugInfoProvider?
    
    @usableFromInline
    init(value: Value, debugInfoProvider: DSLDebugInfoProvider?) {
      self.value = value
      self.debugInfoProvider = debugInfoProvider
    }
    
    public var regex: Regex<Value.RegexOutput> {
      if let debugInfoProvider {
        return _RegexFactory().debuggable(value, debugInfoProvider)
      }
      return value.regex
    }
  }
  
  public static func buildBlock() -> Regex<Substring> {
    _RegexFactory().empty()
  }

  public static func buildPartialBlock<R: RegexComponent>(
    first component: R
  ) -> Regex<R.RegexOutput> {
    component.regex
  }
  
  // TODO: ApolloZhu is optional callback a good idea? (no debugInfoProvider other than -Onone
  // TODO: ApolloZhu autocomplete or near miss checker?
  // TODO: ApolloZhu what if they only have one version of buildExpression that takes debugInfoProvider?
  // They'll probably get a compile time error in release mode, so not a problem?
  // Do we allow a buildExpression with debugInfoProvider only (and no buildExpression in other cases?)
  // TODO: ApolloZhu @escaping checker?
  // TODO: ApolloZhu availability marker
  @_alwaysEmitIntoClient
  public static func buildExpression<R: RegexComponent>(
    _ regex: R,
    debugInfoProvider: DSLDebugInfoProvider? = nil
  ) -> Component<R> {
    .init(value: regex, debugInfoProvider: debugInfoProvider)
  }
}
