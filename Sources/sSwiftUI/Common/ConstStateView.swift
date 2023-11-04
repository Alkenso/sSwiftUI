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

public struct ConstStateView<T: Equatable, Content: View>: View {
    private let initial: T
    @State private var state: T
    private let content: (Binding<T>) -> Content
    
    public init(_ value: T, @ViewBuilder content: @escaping (Binding<T>) -> Content) {
        self.initial = value
        self._state = State(wrappedValue: value)
        self.content = content
    }
    
    public var body: some View {
        content(.init(get: { initial }, set: { state = $0 }))
            .onChange(of: state, perform: { value in
                guard value != initial else { return }
                DispatchQueue.main.async { state = initial }
            })
    }
}

#Preview {
    ConstStateView("qwerty") {
        TextField("", text: $0)
    }
}
