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

import Cocoa
import SwiftConvenience
import SwiftUI

public struct SCTable<T: Identifiable>: View {
    public let items: [T]
    public let columns: [SCTableColumn<T>]
    public var contextMenu: [SCTableContextMenu] = []
    
    // In-Out:
    public var selection: Binding<Set<T.ID>>?
    
    // Out:
    public var onDoubleClick: ((Int) -> Void)?
    // Setting `onSort` property through ObjectBuilder triggers known Swift bug
    // and cause crash in runtime.
    public let onSort: (([SCSortComparator<T>]) -> Void)?
    
    // In:
    public var scrollTo: Binding<T.ID?> = .constant(nil)
    
    // Properties:
    public var allowsMultipleSelection = true
    public var allowsEmptySelection = true
    public var allowsColumnSelection = false
    public var allowsColumnReordering = true
    public var allowsColumnResizing = true
    public var columnAutoresizingStyle: NSTableView.ColumnAutoresizingStyle = .uniformColumnAutoresizingStyle
    
    public init(items: [T], columns: [SCTableColumn<T>], onSort: (([SCSortComparator<T>]) -> Void)? = nil) {
        self.items = items
        self.columns = columns
        self.onSort = onSort
    }
    
    public var body: some View {
        SCTableImpl(rep: self)
    }
}

extension SCTable: ObjectBuilder {}

public struct SCTableColumn<T> {
    fileprivate let id = UUID()
    
    public var title: String
    public var width: Width?
    public var sortComparator: SCSortComparator<T>?
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

extension SCTableColumn: ObjectBuilder {}

extension SCTableColumn {
    public init<S: StringProtocol>(_ title: String, text: @escaping (T) -> S) {
        self.init(title) {
            Text(text($0))
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

public enum SCTableContextMenu {
    case item(_ title: String, _ action: (Int, IndexSet) -> Void)
    case separator
}

private struct SCTableImpl<T: Identifiable>: NSViewRepresentable {
    let rep: SCTable<T>
    
    func makeNSView(context: Context) -> SCTableView<T> {
        let ns = SCTableView<T>(columns: rep.columns, contextMenu: rep.contextMenu)
        updateNSView(ns, context: context)
        return ns
    }
    
    func updateNSView(_ nsView: SCTableView<T>, context: Context) {
        nsView.items = rep.items
        nsView.selection = rep.selection
        nsView.reload()
        
        nsView.onDoubleClick = rep.onDoubleClick
        nsView.onSort = rep.onSort
        
        if let scrollTo = rep.scrollTo.wrappedValue {
            nsView.scrollTo(id: scrollTo)
            DispatchQueue.main.async { rep.scrollTo.wrappedValue = nil }
        }
        
        nsView.allowsMultipleSelection = rep.allowsMultipleSelection
        nsView.allowsEmptySelection = rep.allowsEmptySelection
        nsView.allowsColumnSelection = rep.allowsColumnSelection
        nsView.allowsColumnReordering = rep.allowsColumnReordering
        nsView.allowsColumnResizing = rep.allowsColumnResizing
        nsView.columnAutoresizingStyle = rep.columnAutoresizingStyle
    }
}

private class SCTableView<T: Identifiable>: NSView, NSTableViewDelegate, NSTableViewDataSource, ObjectBuilder {
    private let columns: [SCTableColumn<T>]
    private let contextMenu: [KeyValue<NSMenuItem, SCTableContextMenu>]
    private var tableView: NSTableView!
    
    var onDoubleClick: ((Int) -> Void)?
    var selection: Binding<Set<T.ID>>?
    var onSort: (([SCSortComparator<T>]) -> Void)?
    
    var allowsMultipleSelection = true
    { didSet { tableView?.allowsMultipleSelection = allowsMultipleSelection } }
    var allowsEmptySelection = true
    { didSet { tableView?.allowsEmptySelection = allowsEmptySelection } }
    var allowsColumnSelection = false
    { didSet { tableView?.allowsColumnSelection = allowsColumnSelection } }
    var allowsColumnReordering = true
    { didSet { tableView?.allowsColumnReordering = allowsColumnReordering } }
    var allowsColumnResizing = true
    { didSet { tableView?.allowsColumnResizing = allowsColumnResizing } }
    var columnAutoresizingStyle: NSTableView.ColumnAutoresizingStyle = .uniformColumnAutoresizingStyle
    { didSet { tableView?.columnAutoresizingStyle = columnAutoresizingStyle } }
    
    init(columns: [SCTableColumn<T>], contextMenu: [SCTableContextMenu] = []) {
        self.columns = columns
        self.contextMenu = contextMenu.map {
            let menuItem: NSMenuItem
            switch $0 {
            case .item(let title, _):
                menuItem = NSMenuItem(title: title, action: #selector(contextMenuItemSelected(_:)), keyEquivalent: "")
            case .separator:
                menuItem = .separator()
            }
            return .init(menuItem, $0)
        }
        
        super.init(frame: .zero)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
    
    var items: [T] = []
    
    func reload() {
        DispatchQueue.main.async { [self] in
            tableView?.reloadData()
            if let selectedIDs = selection?.wrappedValue {
                let selection = items.enumerated().filter { selectedIDs.contains($0.element.id) }.map(\.offset)
                tableView.selectRowIndexes(IndexSet(selection), byExtendingSelection: false)
            }
        }
    }
    
    func scrollTo(id: T.ID) {
        guard let row = items.firstIndex(where: { $0.id == id }) else { return }
        tableView?.scrollRowToVisible(row)
    }
    
    private func setupView() {
        tableView = NSTableView(frame: bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = allowsMultipleSelection
        tableView.allowsEmptySelection = allowsEmptySelection
        tableView.allowsColumnSelection = allowsColumnSelection
        tableView.allowsColumnReordering = allowsColumnReordering
        tableView.allowsColumnResizing = allowsColumnResizing
        tableView.columnAutoresizingStyle = columnAutoresizingStyle
        
        columns.forEach {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: $0.id.uuidString))
            column.title = $0.title
            switch $0.width {
            case .some(.fixed(let width)):
                column.width = width
                column.minWidth = width
                column.maxWidth = width
            case .some(.flexible(let min, let max)):
                min.flatMap { column.minWidth = $0 }
                max.flatMap { column.maxWidth = $0 }
            case .none:
                break
            }
            if let sortComparator = $0.sortComparator {
                column.sortDescriptorPrototype = .init(key: $0.id.uuidString, ascending: sortComparator.ascending)
            }
            tableView.addTableColumn(column)
        }
        
        tableView.doubleAction = #selector(onDoubleClick(_:))
        
        if !contextMenu.isEmpty {
            let menu = NSMenu()
            contextMenu.forEach {
                menu.addItem($0.key)
                $0.key.target = self
            }
            tableView.menu = menu
        }
        
        let scrollView = NSScrollView(frame: bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        addSubview(scrollView)
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn.flatMap({ UUID(uuidString: $0.identifier.rawValue) }) else { return nil }
        guard let column = columns.first(where: { $0.id == columnID }) else { return nil }
        
        let item = items[row]
        let view = NSHostingView(rootView: column.view(item))
        
        return view
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        let ids = tableView.selectedRowIndexes.map { items[$0].id }
        selection?.wrappedValue = Set(ids)
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let onSort else { return }
        let comparators: [SCSortComparator<T>] = tableView.sortDescriptors.compactMap {
            guard let key = $0.key else { return nil }
            guard let column = columns.first(where: { $0.id.uuidString == key }) else { return nil }
            guard var sortComparator = column.sortComparator else { return nil }
            sortComparator.ascending = $0.ascending
            return sortComparator
        }
        onSort(comparators)
    }
    
    @objc
    private func onDoubleClick(_ sender: AnyObject) {
        onDoubleClick?(tableView.clickedRow)
    }

    @objc
    private func contextMenuItemSelected(_ sender: NSMenuItem) {
        guard let item = contextMenu.first(where: { $0.key === sender })?.value else { return }
        guard case .item(_, let action) = item else { return }
        action(tableView.clickedRow, tableView.selectedRowIndexes)
    }
}

#if DEBUG
struct SCTableView_Previews: PreviewProvider {
    struct Item: Identifiable {
        let id = UUID()
        var name = "name"
        var code =  123
    }
    
    struct Foo: View {
        @State var lastAction = ""
        @State var selection: Set<UUID> = []
        @State var items: [Item] = (0..<100).map { Item(name: "name_\($0)", code: $0) }
        
        var body: some View {
            VStack {
                Text("Last action: \(lastAction)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Selected: \(selection.count)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                SCTable(
                    items: items,
                    columns: [
                        .init("Name") { $0.name }
                            .set(\.width, 159)
                            .set(\.sortComparator, .keyPath(\.name)),
                        .init("Code") { String($0.code) },
                    ],
                    onSort: {
                        guard let pred = $0.first else { return }
                        items.sort(by: pred.compare)
                    }
                )
                .set(\.selection, $selection)
                .set(\.onDoubleClick, { lastAction = "Double click on \($0)" })
                .set(\.columnAutoresizingStyle, .uniformColumnAutoresizingStyle)
            }
            .padding()
        }
    }
    
    static var previews: some View {
        Foo()
    }
}
#endif

#endif
