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
  public struct Component<RegexOutput>: RegexComponent {
    public let regex: Regex<RegexOutput>
    
    @usableFromInline
    init(regex: Regex<RegexOutput>) {
      self.regex = regex
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
    _ expression: R
  ) -> Component<R.RegexOutput> {
    .init(regex: expression.regex)
  }
  
  // TODO: ApolloZhu availability marker
  @_alwaysEmitIntoClient
  public static func buildFinalResult<R: RegexComponent>(
    _ component: R
  ) -> R {
    component
  }
  
  @_alwaysEmitIntoClient
  public static func buildDebuggable<Output>(
    _ component: Component<Output>,
    debugInfoProvider: DSLDebugInfoProvider
  ) -> Component<Output> {
    .init(regex: makeFactory()
      .debuggable(component.regex, debugInfoProvider))
  }
  
  // TODO: ApolloZhu availability marker
  @_alwaysEmitIntoClient
  public static func buildDebuggable<Output>(
    _ component: Regex<Output>,
    debugInfoProvider: DSLDebugInfoProvider
  ) -> Regex<Output> {
    makeFactory().debuggableFinalResult(component.regex, debugInfoProvider)
  }
}
