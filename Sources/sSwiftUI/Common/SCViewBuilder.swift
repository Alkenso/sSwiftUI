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

import SwiftUI

extension View {
    public func builder() -> SCViewBuilder<Self> {
        SCViewBuilder(body: self)
    }
}

@dynamicMemberLookup
public struct SCViewBuilder<Content: View>: View {
    public var body: Content
    
    public init(body: Content) {
        self.body = body
    }
    
    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Content, T>) -> T {
        get { body[keyPath: keyPath] }
        set { body[keyPath: keyPath] = newValue }
    }
}

extension SCViewBuilder {
    public func set<T>(_ keyPath: WritableKeyPath<Self, T>, _ value: T?) -> Self {
        guard let value = value else { return self }
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
    
    @ViewBuilder
    public func `if`<R: View>(_ condition: Bool, @ViewBuilder body: (Self) -> R) -> some View {
        if condition {
            body(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    public func ifLet<T, R: View>(_ value: T?, body: (Self, T) -> R) -> some View {
        if let value = value {
            body(self, value)
        } else {
            self
        }
    }
}
