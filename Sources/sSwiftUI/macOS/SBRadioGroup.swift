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

import SpellbookFoundation
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct RadioGroup<Content: View, Selection: Hashable>: View {
    @Binding private var selection: Selection
    @ViewBuilder let content: () -> Content
    
    public init(selection: Binding<Selection>, @ViewBuilder content: @escaping () -> Content) {
        self._selection = selection
        self.content = content
    }
    
    public var body: some View {
        content()
            .environment(\.radioGroupSelection, .init($selection))
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {
    public func radioGroupItem(@ViewBuilder label: @escaping () -> some View) -> some View {
        modifier(RadioGroupItem(label: label))
    }
    
    public func radioGroupDisabledOpacity(_ opacity: Double) -> some View {
        environment(\.radioGroupDisabledOpacity, opacity)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct RadioGroupItem<Label: View>: ViewModifier {
    @ViewBuilder let label: () -> Label

    @Environment(\.radioGroupSelection) var selection
    @Environment(\.sbTag) var tag
    @Environment(\.radioGroupDisabledOpacity) var disabledOpacity
    
    @FocusState var isFocused
    
    func body(content: Content) -> some View {
        if let selection {
            VStack(alignment: .leading) {
                Picker("", selection: selection) {
                    content.scIfLet(tag) { $0.tag($1) }
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                label()
                    .focused($isFocused)
                    .disabled(tag == nil)
                    .padding(.leading)
            }
            .opacity(selection.wrappedValue == tag ? 1.0 : disabledOpacity)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded {
                tag.flatMap { selection.wrappedValue = $0 }
            })
            .onChange(of: isFocused) {
                guard $0 else { return }
                tag.flatMap { selection.wrappedValue = $0 }
            }
            .onChange(of: selection.wrappedValue, perform: { value in
                guard let tag else { return }
                guard selection.wrappedValue != tag else { return }
                isFocused = false
            })
        }
    }
}

private struct ItemEnvironmentKey: EnvironmentKey {
    static var defaultValue: Binding<AnyHashable>? = nil
}

extension EnvironmentValues {
    fileprivate var radioGroupSelection: Binding<AnyHashable>? {
        get { self[ItemEnvironmentKey.self] }
        set { self[ItemEnvironmentKey.self] = newValue }
    }
}

private struct DisabledOpacityEnvironmentKey: EnvironmentKey {
    static var defaultValue: Double = 1.0
}

extension EnvironmentValues {
    fileprivate var radioGroupDisabledOpacity: Double {
        get { self[DisabledOpacityEnvironmentKey.self] }
        set { self[DisabledOpacityEnvironmentKey.self] = newValue }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
#Preview {
    StatefulPreviewWrapper(1) {
        RadioGroup(selection: $0) {
            Text("11 wer wer qwe rqwe r")
                .radioGroupItem {
                    TextField("Second body", text: .constant(""))
                    TextField("Second body3", text: .constant(""))
                }
                .sbTag(1)
            Text("22 ewq rew rwq erwe r")
                .radioGroupItem {
                    TextField("Second body", text: .constant(""))
                }
                .sbTag(2)
        }
        .radioGroupDisabledOpacity(0.5)
    }
}
