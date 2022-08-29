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
    @usableFromInline
    let value: Value
    private let debugInfoProvider: DSLDebugInfoProvider?
    
    @usableFromInline
    init(value: Value, debugInfoProvider: DSLDebugInfoProvider? = nil) {
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
  
  // TODO: ApolloZhu availability marker
  @_alwaysEmitIntoClient
  public static func buildExpression<R: RegexComponent>(
    _ regex: R
  ) -> Component<R> {
    .init(value: regex)
  }
  
  // TODO: ApolloZhu availability marker
  @_alwaysEmitIntoClient
  public static func buildDebuggable<R>(
    _ component: Component<R>,
    debugInfoProvider: DSLDebugInfoProvider
  ) -> Component<R> {
    .init(value: component.value, debugInfoProvider: debugInfoProvider)
  }
}
