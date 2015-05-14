//
//  ViewController.swift
//  SqLT-Cafe
//
//  Created by 杉山元和 on 2015/04/16.
//  Copyright (c) 2015年 __MEXEL_STUDIO__. All rights reserved.
//

import Cocoa

var _viewController: ViewController?

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var tableTableView: NSTableView!
    @IBOutlet weak var recordTableView: NSTableView!

    var tables: [String] = []
    var tableInfo: [[String]] = []
    var recordInfo: [[AnyObject]] = []
    var db: FMDatabase = FMDatabase()

    override func viewDidLoad() {
        super.viewDidLoad()
        _viewController = self
        for column in recordTableView.tableColumns {
            recordTableView.removeTableColumn(column as! NSTableColumn)
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        }
    }

    // 何行？
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if tableView == tableTableView {
            return tables.count
        } else {
            return recordInfo.count
        }
    }

    // データセット時
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if tableView == tableTableView {
            return tables[row]
        } else {
            if let tc: NSTableColumn = tableColumn {

                for (idx, info) in enumerate(tableInfo) {
                    if info[0] == tc.identifier {
                        return recordInfo[row][idx]
                    }
                }
            }
            return "NO DATA"
        }
    }

    // 選択時
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if tableView == tableTableView {
            println(tables[row])
            db.open()

            var result: FMResultSet = db.executeQuery("PRAGMA TABLE_INFO(\(tables[row]));", withArgumentsInArray: nil)
            tableInfo = []
            while result.next() {
                tableInfo += [[result.objectForColumnIndex(1) as! String, result.objectForColumnIndex(2) as! String]]
            }

            for column in recordTableView.tableColumns {
                recordTableView.removeTableColumn(column as! NSTableColumn)
            }

            for columnInfo in tableInfo {
                var column = NSTableColumn(identifier: columnInfo[0])
                column.title = columnInfo[0]
                column.width = 100
                recordTableView.addTableColumn(column)
            }
            result = db.executeQuery("SELECT * FROM \(tables[row])", withArgumentsInArray: nil)
            recordInfo.removeAll(keepCapacity: false)
            while result.next() {
                var tmpArray: [AnyObject] = []
                for var i = Int32(0); i < Int32(result.columnCount()); i++ {
                    let obj: AnyObject = result.objectForColumnIndex(i)
                    if obj is NSNull {
                        tmpArray += [NSNull()]
                    } else {
                        switch tableInfo[Int(i)][1] {
                        case "INTEGER":
                            tmpArray += [Int(result.intForColumnIndex(i))]
                            break
                        case "TIMESTAMP":
                            tmpArray += [Double(result.doubleForColumnIndex(i))]
                            break
                        case "VARCHAR":
                            tmpArray += [String(result.stringForColumnIndex(i))]
                            break
                        default:
                            tmpArray += [result.objectForColumnIndex(i)]
                            break
                        }
                    }
                }
                recordInfo += [tmpArray]
            }

            db.close()

            recordTableView.reloadData()
        } else {

        }

        return true
    }

    func openSqlite(path: String) {
        db = FMDatabase(path: path)

        db.open()

        tables.removeAll(keepCapacity: false)
        var result: FMResultSet = db.executeQuery("select name from sqlite_master where type=\"table\"", withArgumentsInArray: nil)
        while result.next() {
            tables += [result.objectForColumnIndex(0) as! String]
        }
        
        db.close()

        tableTableView.reloadData()
    }
}

