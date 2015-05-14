//
//  ExecuteSQLViewController.swift
//  SqLT-Cafe
//
//  Created by 杉山元和 on 2015/05/12.
//  Copyright (c) 2015年 __MEXEL_STUDIO__. All rights reserved.
//

import Foundation
import Cocoa

class ExecuteSQLViewController: NSViewController, NSTextViewDelegate, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var executeButton: NSButton!

    var result: [[String: AnyObject]] = []

    required init?(coder: (NSCoder!)) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for column in tableView.tableColumns {
            tableView.removeTableColumn(column as! NSTableColumn)
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        }
    }

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return result.count
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return result[row][tableColumn!.identifier]
    }

    @IBAction func executeSQL(sender: NSButton) {
        executeButton.enabled = false
        _viewController?.db.open()

        result.removeAll(keepCapacity: false)
        for column in tableView.tableColumns {
            tableView.removeTableColumn(column as! NSTableColumn)
        }

        if let r: FMResultSet = _viewController?.db.executeQuery(textView.string, withArgumentsInArray: nil) {
            if r.columnNameToIndexMap.count > 0 {
                for key: String in r.columnNameToIndexMap.allKeys as! [String] {
                    let tableColumn: NSTableColumn = NSTableColumn(identifier: key)
                    tableColumn.title = key
                    tableView.addTableColumn(tableColumn)
                }
                for dic in r.columnNameToIndexMap {
                    tableView.moveColumn(tableView.columnWithIdentifier(dic.key as? String), toColumn: dic.value as! Int)
                }
            }
            while r.next() {
                var tmpDic: [String: AnyObject] = [:]
                for tableColumn in tableView.tableColumns {
                    tmpDic.updateValue(r.objectForColumnName(tableColumn.identifier), forKey: tableColumn.identifier)
                }
                result.append(tmpDic)
            }
        }

        _viewController?.db.close()
        executeButton.enabled = true

        tableView.reloadData()
    }
    
}