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

import SpellbookFoundation
import SwiftUI

extension View {
    @available(macOS 12.0, *)
    public func sbOnEvent(type: NSEvent.EventTypeMask, whenFocused: Bool = true, action: @escaping (NSEvent) -> NSEvent?) -> some View {
        NSEventMonitorView(content: self, type: type, whenFocused: whenFocused, action: action)
    }
}

@available(macOS 12.0, *)
private struct NSEventMonitorView<Content: View>: View {
    @FocusState private var isFocused
    @State private var subscription: Any?
    
    let content: Content
    let type: NSEvent.EventTypeMask
    let whenFocused: Bool
    let action: (NSEvent) -> NSEvent?
    
    var body: some View {
        content
            .focused($isFocused)
            .onAppear(perform: subscribe)
            .onDisappear(perform: unsubscribe)
            .onChange(of: type) { _ in
                DispatchQueue.main.async {
                    unsubscribe()
                    subscribe()
                }
            }
    }
    
    private func subscribe() {
        subscription = NSEvent.addLocalMonitorForEvents(matching: type) {
            guard !whenFocused || isFocused else { return $0 }
            return action($0)
        }
    }
    
    private func unsubscribe() {
        updateSwap(&subscription, nil).flatMap(NSEvent.removeMonitor)
    }
}

#endif
