//  MIT License
//
//  Copyright (c) 2023 Alkenso (Vladimir Vashurkin)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#if os(macOS)

import Foundation
import SpellbookFoundation
import SwiftUI

public struct SBTableColumn<T> {
    internal let id = UUID()
    
    public var title: String
    public var width: Width?
    public var sortComparator: SBSortComparator<T>?
    public let view: (T) -> AnyView
    
    public init<Content: View>(_ title: String, @ViewBuilder view: @escaping (T) -> Content) {
        self.title = title
        self.view = { AnyView(view($0).frame(maxWidth: .infinity)) }
    }
    
    public enum Width: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
        case fixed(CGFloat)
        case flexible(min: CGFloat? = nil, max: CGFloat? = nil)
        
        public init(floatLiteral value: FloatLiteralType) {
            self = .fixed(value)
        }
        
        public init(integerLiteral value: IntegerLiteralType) {
            self = .fixed(CGFloat(value))
        }
    }
}

extension SBTableColumn: ValueBuilder {}

extension SBTableColumn {
    public init<S: StringProtocol>(_ title: String, text: @escaping (T) -> S) {
        self.init(title) {
            let value = text($0)
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(value)
        }
    }
}

@resultBuilder
public struct SBTableColumnBuilder<T> {
    public static func buildBlock(_ columns: [SBTableColumn<T>]...) -> [SBTableColumn<T>] {
        columns.flatMap { $0 }
    }
    
    public static func buildOptional(_ component: [SBTableColumn<T>]?) -> [SBTableColumn<T>] {
        component ?? []
    }
    
    public static func buildEither(first: [SBTableColumn<T>]) -> [SBTableColumn<T>] {
        first
    }

    public static func buildEither(second: [SBTableColumn<T>]) -> [SBTableColumn<T>] {
        second
    }

    public static func buildArray(_ components: [[SBTableColumn<T>]]) -> [SBTableColumn<T>] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ column: SBTableColumn<T>) -> [SBTableColumn<T>] {
        [column]
    }
    
    public static func buildLimitedAvailability(_ component: [SBTableColumn<T>]) -> [SBTableColumn<T>] {
        component
    }
}

#endif
