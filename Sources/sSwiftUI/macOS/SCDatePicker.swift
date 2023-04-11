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

import SwiftConvenience
import SwiftUI

public struct SCDatePicker: View {
    fileprivate var datePickerStyle: NSDatePicker.Style
    fileprivate var datePickerElements: NSDatePicker.ElementFlags
    fileprivate let datePickerMode: NSDatePicker.Mode
    @Binding fileprivate var selection: ClosedRange<Date>
    
    public var roundToDayBoundaries = false
    public var isBezeled: Bool?
    public var isBordered: Bool?
    public var drawsBackground: Bool?
    public var backgroundColor: NSColor?
    public var textColor: NSColor?
    public var calendar: Calendar?
    public var locale: Locale?
    public var timeZone: TimeZone?
    public var minDate: Date?
    public var maxDate: Date?
    
    public init(
        style: NSDatePicker.Style,
        elements: NSDatePicker.ElementFlags,
        selection: Binding<ClosedRange<Date>>,
        roundToDayBoundaries: Bool = false,
        minDate: Date? = nil,
        maxDate: Date? = nil,
        calendar: Calendar? = nil,
        locale: Locale? = nil,
        timeZone: TimeZone? = nil,
        isBezeled: Bool? = nil,
        isBordered: Bool? = nil,
        drawsBackground: Bool? = nil,
        backgroundColor: NSColor? = nil,
        textColor: NSColor? = nil
    ) {
        self.datePickerStyle = style
        self.datePickerElements = elements
        self.datePickerMode = .range
        self._selection = selection
        self.roundToDayBoundaries = roundToDayBoundaries
        self.minDate = minDate
        self.maxDate = maxDate
        self.calendar = calendar
        self.locale = locale
        self.timeZone = timeZone
        self.isBezeled = isBezeled
        self.isBordered = isBordered
        self.drawsBackground = drawsBackground
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
    public init(
        style: NSDatePicker.Style,
        elements: NSDatePicker.ElementFlags,
        selection: Binding<Date>,
        roundToDayBoundaries: Bool = false,
        minDate: Date? = nil,
        maxDate: Date? = nil,
        calendar: Calendar? = nil,
        locale: Locale? = nil,
        timeZone: TimeZone? = nil,
        isBezeled: Bool? = nil,
        isBordered: Bool? = nil,
        drawsBackground: Bool? = nil,
        backgroundColor: NSColor? = nil,
        textColor: NSColor? = nil
    ) {
        self.datePickerStyle = style
        self.datePickerElements = elements
        self.datePickerMode = .single
        self._selection = Binding<ClosedRange<Date>>(
            get: { selection.wrappedValue...selection.wrappedValue },
            set: { selection.wrappedValue = $0.lowerBound }
        )
        self.roundToDayBoundaries = roundToDayBoundaries
        self.minDate = minDate
        self.maxDate = maxDate
        self.calendar = calendar
        self.locale = locale
        self.timeZone = timeZone
        self.isBezeled = isBezeled
        self.isBordered = isBordered
        self.drawsBackground = drawsBackground
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
    public var body: some View {
        _SCDatePicker(rep: self)
    }
}

private struct _SCDatePicker: NSViewRepresentable {
    let rep: SCDatePicker
    
    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker(frame: .zero)
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.onPickerSelectionChange)
        
        return picker
    }
    
    func updateNSView(_ picker: NSDatePicker, context: Context) {
        picker.dateValue = rep.selection.lowerBound
        picker.timeInterval = rep.selection.upperBound.timeIntervalSince(rep.selection.lowerBound)
        picker.datePickerStyle = rep.datePickerStyle
        picker.datePickerElements = rep.datePickerElements
        picker.datePickerMode = rep.datePickerMode
        
        rep.isBezeled.flatMap { picker.isBezeled = $0 }
        rep.isBordered.flatMap { picker.isBordered = $0 }
        rep.drawsBackground.flatMap { picker.drawsBackground = $0 }
        rep.backgroundColor.flatMap { picker.backgroundColor = $0 }
        rep.textColor.flatMap { picker.textColor = $0 }
        rep.calendar.flatMap { picker.calendar = $0 }
        rep.locale.flatMap { picker.locale = $0 }
        rep.timeZone.flatMap { picker.timeZone = $0 }
        rep.minDate.flatMap { picker.minDate = $0 }
        rep.maxDate.flatMap { picker.maxDate = $0 }
        
        let size = picker.intrinsicContentSize
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.widthAnchor.constraint(equalToConstant: size.width).isActive = true
        picker.heightAnchor.constraint(equalToConstant: size.height).isActive = true
    }
    
    func makeCoordinator() -> Coordinator {
        let roundingCalendar = rep.roundToDayBoundaries ? rep.calendar ?? .iso8601UTC : nil
        return Coordinator(calendar: roundingCalendar, selection: rep.$selection)
    }
}

private class Coordinator: NSObject {
    private let calendar: Calendar?
    @Binding private var selection: ClosedRange<Date>
    
    init(calendar: Calendar?, selection: Binding<ClosedRange<Date>>) {
        self.calendar = calendar
        self._selection = selection
        
        super.init()
        
        if calendar != nil {
            DispatchQueue.main.async {
                self.selection = self.roundedRange(self.selection)
            }
        }
    }
    
    @objc
    func onPickerSelectionChange(_ picker: NSDatePicker) {
        selection = roundedRange(picker.dateValue...picker.dateValue.addingTimeInterval(picker.timeInterval))
    }
    
    private func roundedRange(_ range: ClosedRange<Date>) -> ClosedRange<Date> {
        guard let calendar else { return range }
        return calendar.startOfDay(for: range.lowerBound)...calendar.endOfDay(for: range.upperBound)
    }
}

#if DEBUG
struct SCDatePicker_Previews: PreviewProvider {
    static var previews: some View {
        SCDatePicker(
            style: .clockAndCalendar,
            elements: .yearMonthDay,
            selection: .constant(Date()...Date().addingTimeInterval(500000))
        )
    }
}
#endif

#endif
