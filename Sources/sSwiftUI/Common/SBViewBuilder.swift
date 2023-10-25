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
    public func scSet<T>(_ keyPath: WritableKeyPath<Self, T>, _ value: T?) -> Self {
        guard let value = value else { return self }
        var copy = self
        copy[keyPath: keyPath] = value
        return copy
    }
    
    @ViewBuilder
    public func scIf(_ condition: Bool, @ViewBuilder then: (Self) -> some View) -> some View {
        scIf(condition, then: then, else: { $0 })
    }
    
    @ViewBuilder
    public func scIf(_ condition: Bool, @ViewBuilder then: (Self) -> some View, @ViewBuilder else: (Self) -> some View) -> some View {
        if condition {
            then(self)
        } else {
            `else`(self)
        }
    }
    
    @ViewBuilder
    public func scIfLet<T>(_ value: T?, then: (Self, T) -> some View) -> some View {
        scIfLet(value, then: then, else: { $0 })
    }
    
    @ViewBuilder
    public func scIfLet<T>(_ value: T?, then: (Self, T) -> some View, @ViewBuilder else: (Self) -> some View) -> some View {
        if let value = value {
            then(self, value)
        } else {
            `else`(self)
        }
    }
    
    @ViewBuilder
    func scDecorate(@ViewBuilder _ decorator: (Self) -> some View) -> some View {
        decorator(self)
    }
}
