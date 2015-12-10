// TreeSourceView
// Written in 2015 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

import UIKit

/// An internal helper class, hiding the backing `UITableView` of `TreeSourceView` by implementing the data source and
/// delegate protocols outside of that class.
internal class TreeSourceViewHelper: NSObject
{
    /// The associated tree source view.
    weak var treeSourceView: TreeSourceView?
}

extension TreeSourceViewHelper: UITableViewDataSource
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        // the sections are:
        // 0: upward navigation
        // 1: root sections or current navigation - selected section cell is reused
        // 2: downward navigation
        return treeSourceView?.dataSource != nil ? 3 : 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if let treeSourceView = self.treeSourceView, dataSource = treeSourceView.dataSource
        {
            let selectedIndexPath = treeSourceView.selectedIndexPath
            
            switch section
            {
            case 0:
                return selectedIndexPath.length ?? 0
            case 1:
                if selectedIndexPath.length == 0
                {
                    return dataSource.treeSourceView(treeSourceView, numberOfChildrenAtIndexPath: NSIndexPath())
                }
                else
                {
                    return 1
                }
            case 2:
                if selectedIndexPath.length > 0
                {
                    return dataSource.treeSourceView(treeSourceView, numberOfChildrenAtIndexPath: selectedIndexPath)
                }
                else
                {
                    return 0
                }
            default:
                fatalError("Invalid tree source view section")
            }
        }
        else
        {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if let treeSourceView = self.treeSourceView, dataSource = treeSourceView.dataSource
        {
            let reuse = "\(treeSourceView.cellType)"
            let cell = treeSourceView.tableView.dequeueReusableCellWithIdentifier(reuse)
                ?? treeSourceView.cellType.init(style: .Default, reuseIdentifier: reuse)
            
            let selectedIndexPath = treeSourceView.selectedIndexPath
            
            switch indexPath.section
            {
            case 0:
                let count = tableView.numberOfRowsInSection(indexPath.section)
                
                var path = selectedIndexPath
                
                for _ in 0..<(count - indexPath.row)
                {
                    path = path.indexPathByRemovingLastIndex()
                }
                
                dataSource.treeSourceView(
                    treeSourceView,
                    updateCell: cell,
                    forIndexPath: path,
                    withCellStyle: .Upward
                )
            case 1:
                let isRoot = selectedIndexPath.length == 0
                let item = isRoot ? indexPath.item : selectedIndexPath.indexAtPosition(0)
                
                dataSource.treeSourceView(
                    treeSourceView,
                    updateCell: cell,
                    forIndexPath: NSIndexPath(index: item),
                    withCellStyle: isRoot ? .Root : .Current
                )
            case 2:
                dataSource.treeSourceView(
                    treeSourceView,
                    updateCell: cell,
                    forIndexPath: selectedIndexPath.indexPathByAddingIndex(indexPath.row),
                    withCellStyle: .Downward
                )
                
            default:
                fatalError("Invalid tree source view section")
            }
            
            return cell
        }
        else
        {
            fatalError("Requested a cell, but no data source")
        }
    }
}

extension TreeSourceViewHelper: UITableViewDelegate
{
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        guard let treeSourceView = self.treeSourceView else {
            fatalError("Received delegate callback, but no TreeSourceView")
        }
        
        let previousSelectedPath = treeSourceView.selectedIndexPath
        
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        switch indexPath.section
        {
        case 0:
            let count = tableView.numberOfRowsInSection(indexPath.section)
            
            treeSourceView._selectedIndexPath = previousSelectedPath.indexPathByRemovingIndices(count - indexPath.item)
            
            tableView.beginUpdates()
            
            // remove the upwards navigation rows
            let upwardsPaths = (treeSourceView.selectedIndexPath.length..<previousSelectedPath.length).map({ row in
                NSIndexPath(forRow: row, inSection: 0)
            })
            
            tableView.deleteRowsAtIndexPaths(upwardsPaths, withRowAnimation: .Bottom)
            
            // remove rows for downwards navigation
            let previousChildren = treeSourceView.dataSource?.treeSourceView(
                treeSourceView,
                numberOfChildrenAtIndexPath: previousSelectedPath
            ) ?? 0
            
            let previousDownwardPaths = (0..<previousChildren).map({ row in
                NSIndexPath(forRow: row, inSection: 2)
            })
            
            tableView.deleteRowsAtIndexPaths(previousDownwardPaths, withRowAnimation: .Bottom)
            
            if treeSourceView.selectedIndexPath.length == 0
            {
                // insert the new root rows
                let currentSelectedRoot = previousSelectedPath.indexAtPosition(0)
                let beforePaths = (0..<currentSelectedRoot).map({ row in
                    NSIndexPath(forRow: row, inSection: 1)
                })
                
                let totalRootRows = treeSourceView.dataSource?.treeSourceView(treeSourceView, numberOfChildrenAtIndexPath: NSIndexPath()) ?? 0
                let afterPaths = ((currentSelectedRoot + 1)..<totalRootRows).map({ row in
                    NSIndexPath(forRow: row, inSection: 1)
                })
                
                tableView.insertRowsAtIndexPaths(beforePaths, withRowAnimation: .Top)
                tableView.insertRowsAtIndexPaths(afterPaths, withRowAnimation: .Fade)
            }
            else
            {
                // add the rows for the new upwards navigation
                let children = treeSourceView.dataSource?.treeSourceView(treeSourceView, numberOfChildrenAtIndexPath: treeSourceView.selectedIndexPath) ?? 0
                let downwardPaths = (0..<children).map({ row in
                    NSIndexPath(forRow: row, inSection: 2)
                })
                
                tableView.insertRowsAtIndexPaths(downwardPaths, withRowAnimation: .Fade)
            }
            
            tableView.endUpdates()
            
            let toRoot = treeSourceView.selectedIndexPath.length == 0
            let treePath = toRoot ? NSIndexPath(index: previousSelectedPath.indexAtPosition(0)) : treeSourceView.selectedIndexPath
            let tablePath = NSIndexPath(forRow: toRoot ? treePath.indexAtPosition(0) : 0, inSection: 1)
            
            if let cell = tableView.cellForRowAtIndexPath(tablePath)
            {
                UIView.animateWithDuration(0.33, animations: {
                    treeSourceView.dataSource?.treeSourceView(
                        treeSourceView,
                        updateCell: cell,
                        forIndexPath: treePath,
                        withCellStyle: toRoot ? .Root : .Current
                    )
                })
            }
            
        case 1:
            if treeSourceView.selectedIndexPath.length == 0
            {
                treeSourceView._selectedIndexPath = treeSourceView.selectedIndexPath.indexPathByAddingIndex(indexPath.row)
                
                tableView.beginUpdates()
                
                // remove the non-selected root rows
                let beforePaths = (0..<(indexPath.row)).map({ row in
                    NSIndexPath(forRow: row, inSection: 1)
                })
                
                let afterPaths = ((indexPath.row + 1)..<(tableView.numberOfRowsInSection(1))).map({ row in
                    NSIndexPath(forRow: row, inSection: 1)
                })
                
                tableView.deleteRowsAtIndexPaths(beforePaths, withRowAnimation: .Top)
                tableView.deleteRowsAtIndexPaths(afterPaths, withRowAnimation: .Fade)
                
                // add the root upwards navigation row
                tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Bottom)
                
                // add the rows for the current downwards navigation
                let children = treeSourceView.dataSource?.treeSourceView(treeSourceView, numberOfChildrenAtIndexPath: treeSourceView.selectedIndexPath) ?? 0
                let downwardPaths = (0..<children).map({ row in
                    NSIndexPath(forRow: row, inSection: 2)
                })
                
                tableView.insertRowsAtIndexPaths(downwardPaths, withRowAnimation: .Fade)
                
                tableView.endUpdates()
                
                // update the navigation cell for the new category
                if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1))
                {
                    UIView.animateWithDuration(0.33, animations: {
                        treeSourceView.dataSource?.treeSourceView(
                            treeSourceView,
                            updateCell: cell,
                            forIndexPath: treeSourceView.selectedIndexPath,
                            withCellStyle: .Current
                        )
                    })
                }
            }
            else
            {
                treeSourceView.delegate?.treeSourceViewTappedSelectedItem(treeSourceView)
            }
        case 2:
            treeSourceView._selectedIndexPath = previousSelectedPath.indexPathByAddingIndex(indexPath.row)
            
            tableView.beginUpdates()
            
            // insert a new upwards navigation path
            let upwardsPaths = [NSIndexPath(forRow: treeSourceView.selectedIndexPath.length - 1, inSection: 0)]
            tableView.insertRowsAtIndexPaths(upwardsPaths, withRowAnimation: .Bottom)
            
            // remove rows for downwards navigation
            let previousChildren = treeSourceView.dataSource?.treeSourceView(treeSourceView, numberOfChildrenAtIndexPath: previousSelectedPath) ?? 0
            let previousDownwardPaths = (0..<previousChildren).map({ row in
                NSIndexPath(forRow: row, inSection: 2)
            })
            
            tableView.deleteRowsAtIndexPaths(previousDownwardPaths, withRowAnimation: .Fade)
            
            // add the rows for the current downwards navigation
            let children = treeSourceView.dataSource?.treeSourceView(treeSourceView, numberOfChildrenAtIndexPath: treeSourceView.selectedIndexPath) ?? 0
            let downwardPaths = (0..<children).map({ row in
                NSIndexPath(forRow: row, inSection: 2)
            })
            
            tableView.insertRowsAtIndexPaths(downwardPaths, withRowAnimation: .Fade)
            
            tableView.endUpdates()
            
            // update the navigation cell for the new category
            if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1))
            {
                UIView.animateWithDuration(0.33, animations: {
                    treeSourceView.dataSource?.treeSourceView(
                        treeSourceView,
                        updateCell: cell,
                        forIndexPath: treeSourceView.selectedIndexPath,
                        withCellStyle: .Current
                    )
                })
            }
            
        default:
            fatalError("Invalid tree source view section")
        }
    }
}
