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

import Foundation

public struct SBSortComparator<T> {
    public var ascending: Bool
    public var isLess: (T, T) -> Bool
    
    public init(ascending: Bool = true, isLess: @escaping (T, T) -> Bool) {
        self.ascending = ascending
        self.isLess = { isLess($0, $1) }
    }
}

extension SBSortComparator {
    public func compare(_ lhs: T, _ rhs: T) -> Bool {
        isLess(lhs, rhs) == ascending
    }
}

extension SBSortComparator {
    public init(ascending: Bool = true) where T: Comparable {
        self = .keyPath(\.self, ascending: ascending)
    }
    
    public static func optional<U>(ascending: Bool = true, lessThanNil: Bool = true, isLess: @escaping (U, U) -> Bool) -> SBSortComparator<T> where T == U? {
        .init(ascending: ascending) {
            compareOptionals(lessThanNil: lessThanNil, $0, $1, isLess: isLess)
        }
    }
    
    public static func optional<U: Comparable>(ascending: Bool = true, lessThanNil: Bool = true) -> SBSortComparator<T> where T == U? {
        .init(ascending: ascending) {
            compareOptionals(lessThanNil: lessThanNil, $0, $1, isLess: { $0 < $1 })
        }
    }
}
    
extension SBSortComparator {
    public static func keyPath<U>(_ keyPath: KeyPath<T, U>, ascending: Bool = true, isLess: @escaping (U, U) -> Bool) -> SBSortComparator<T> {
        .init(ascending: ascending) {
            isLess($0[keyPath: keyPath], $1[keyPath: keyPath])
        }
    }
    
    public static func keyPath<U: Comparable>(_ keyPath: KeyPath<T, U>, ascending: Bool = true) -> SBSortComparator<T> {
        .keyPath(keyPath, ascending: ascending, isLess: { $0 < $1 })
    }
    
    public static func optional<U>(_ keyPath: KeyPath<T, U?>, ascending: Bool = true, lessThanNil: Bool = true, isLess: @escaping (U, U) -> Bool) -> SBSortComparator<T> {
        .keyPath(keyPath, ascending: ascending) {
            compareOptionals(lessThanNil: lessThanNil, $0, $1, isLess: isLess)
        }
    }
    
    public static func optional<U: Comparable>(_ keyPath: KeyPath<T, U?>, ascending: Bool = true, lessThanNil: Bool = true) -> SBSortComparator<T> {
        .optional(keyPath, ascending: ascending, lessThanNil: lessThanNil) { $0 < $1 }
    }
}

@inline(__always)
private func compareOptionals<T>(lessThanNil: Bool, _ lhs: T?, _ rhs: T?, isLess: (T, T) -> Bool) -> Bool {
    switch (lhs, rhs) {
    case (.some(let lhs), .some(let rhs)):
        return isLess(lhs, rhs)
    case (.some, .none):
        return lessThanNil
    case (.none, .some):
        return !lessThanNil
    case (.none, .none):
        return false
    }
}
