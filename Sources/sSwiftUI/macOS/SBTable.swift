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
import SpellbookFoundation
import SwiftUI

public struct SBTable<T: Identifiable>: View {
    fileprivate let items: Items
    fileprivate let columns: [SBTableColumn<T>]
    public var contextMenu: [SBTableContextMenu] = []
    
    // In-Out:
    public var selection: Binding<Set<T.ID>>?
    
    // Out:
    public var onDoubleClick: ((Int) -> Void)?
    // Setting `onSort` property through ObjectBuilder triggers known Swift bug
    // and cause crash in runtime.
    public let onSort: (([SBSortComparator<T>]) -> Void)?
    
    // In:
    public var scrollTo: Binding<T.ID?> = .constant(nil)
    
    // Properties:
    public var allowsMultipleSelection = true
    public var allowsEmptySelection = true
    public var allowsColumnSelection = false
    public var allowsColumnReordering = true
    public var allowsColumnResizing = true
    public var columnAutoresizingStyle: NSTableView.ColumnAutoresizingStyle = .uniformColumnAutoresizingStyle
    
    public init(items: [T], columns: [SBTableColumn<T>], onSort: (([SBSortComparator<T>]) -> Void)? = nil) {
        self.items = .direct(items)
        self.columns = columns
        self.onSort = onSort
    }
    
    public init(items: [T.ID], provider: @escaping (T.ID) -> T?, columns: [SBTableColumn<T>], onSort: (([SBSortComparator<T>]) -> Void)? = nil) {
        self.items = .reference(items, provider)
        self.columns = columns
        self.onSort = onSort
    }
    
    public var body: some View {
        _TableImpl(rep: self)
    }
}

extension SBTable {
    public init(items: [T.ID], provider: @escaping (T.ID) -> T?, @SBTableColumnBuilder<T> columns: () -> [SBTableColumn<T>], onSort: (([SBSortComparator<T>]) -> Void)? = nil) {
        self.init(items: items, provider: provider, columns: columns(), onSort: onSort)
    }
    
    public init(items: [T], @SBTableColumnBuilder<T> columns: () -> [SBTableColumn<T>], onSort: (([SBSortComparator<T>]) -> Void)? = nil) {
        self.init(items: items, columns: columns(), onSort: onSort)
    }
}

extension SBTable: ValueBuilder {}

extension SBTable {
    fileprivate enum Items {
        case direct([T])
        case reference([T.ID], (T.ID) -> T?)
    }
}

extension SBTable.Items {
    var ids: [T.ID] {
        switch self {
        case .direct(let values):
            return values.map(\.id)
        case .reference(let values, _):
            return values
        }
    }
}

public enum SBTableContextMenu {
    case item(_ title: String, _ action: (Int, IndexSet) -> Void)
    case separator
}

private struct _TableImpl<T: Identifiable>: NSViewRepresentable {
    let rep: SBTable<T>
    
    func makeNSView(context: Context) -> _TableView<T> {
        let ns = _TableView<T>(columns: rep.columns, contextMenu: rep.contextMenu)
        updateNSView(ns, context: context)
        return ns
    }
    
    func updateNSView(_ nsView: _TableView<T>, context: Context) {
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

private class _TableView<T: Identifiable>: NSView, NSTableViewDelegate, NSTableViewDataSource, ValueBuilder {
    private let columns: [SBTableColumn<T>]
    private let contextMenu: [KeyValue<NSMenuItem, SBTableContextMenu>]
    private var tableView: NSTableView!
    
    var onDoubleClick: ((Int) -> Void)?
    var selection: Binding<Set<T.ID>>?
    var onSort: (([SBSortComparator<T>]) -> Void)?
    
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
    
    init(columns: [SBTableColumn<T>], contextMenu: [SBTableContextMenu] = []) {
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
    
    var items: SBTable<T>.Items = .direct([])
    
    func reload() {
        DispatchQueue.main.async { [self] in
            tableView?.reloadData()
            if let selectedIDs = selection?.wrappedValue {
                let selection = items.ids.enumerated().filter { selectedIDs.contains($0.element) }.map(\.offset)
                tableView.selectRowIndexes(IndexSet(selection), byExtendingSelection: false)
            }
        }
    }
    
    func scrollTo(id: T.ID) {
        guard let row = items.ids.firstIndex(where: { $0 == id }) else { return }
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
        return items.ids.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn.flatMap({ UUID(uuidString: $0.identifier.rawValue) }) else { return nil }
        guard let column = columns.first(where: { $0.id == columnID }) else { return nil }
        
        let item: T?
        switch items {
        case .direct(let values):
            item = values[safe: row]
        case .reference(let values, let access):
            item = values[safe: row].flatMap(access)
        }
        guard let item else { return nil }
        let view = NSHostingView(rootView: column.view(item))
        
        return view
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let selection else { return }
        guard let tableView = notification.object as? NSTableView else { return }
        let ids = Set(tableView.selectedRowIndexes.compactMap { items.ids[safe: $0] })
        if selection.wrappedValue != ids {
            selection.wrappedValue = Set(ids)
        }
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let onSort else { return }
        let comparators: [SBSortComparator<T>] = tableView.sortDescriptors.compactMap {
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

#Preview {
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
                SBTable(
                    items: items.map(\.id),
                    provider: { id in  items.first { $0.id == id } },
                    columns: {
                        SBTableColumn("Name") { $0.name }
                            .set(\.width, 159)
                            .set(\.sortComparator, .keyPath(\.name))
                        SBTableColumn("Code") { String($0.code) }
                    },
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
    
    return Foo()
}

#endif
