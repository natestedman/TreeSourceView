// TreeSourceView
// Written in 2015 by Nate Stedman <nate@natestedman.com>
//
// To the extent possible under law, the author(s) have dedicated all copyright and
// related and neighboring rights to this software to the public domain worldwide.
// This software is distributed without any warranty.
//
// You should have received a copy of the CC0 Public Domain Dedication along with
// this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.

import Foundation
import UIKit

/// A protocol to which data sources of `TreeSourceView` instances must conform.
public protocol TreeSourceViewDataSource: class
{
    // MARK: - Child Counts
    
    /**
    Queries the data source for the number of child items at the specified index path.
    
    The index path is of variable length, so `length` and `indexAtPosition(:)` should be used to interpret it, not the
    typical `row`/`item` and `section` properties.
    
    An index path of `length` `0` indicates the root of the tree.
    
    - parameter treeSourceView: The tree source view.
    - parameter indexPath:      The index path.
    
    - returns: The number of child items at the specified index path. If this index path is a leaf, this function should
               return `0`.
    */
    func treeSourceView(treeSourceView: TreeSourceView, numberOfChildrenAtIndexPath indexPath: NSIndexPath) -> Int
    
    // MARK: - Updating Cells
    
    /**
    Instructs the data source to prepare a cell for display.
    
    To support animations correctly, `TreeSourceView` reuses cells without removing them. Therefore, all cells must be
    of the same type - although they will be passed to this function as type `UITableViewCell`, so that `TreeSourceView`
    and this protocol do not need to be generic. Implemenations of this protocol should use `guard let ...` to cast the
    cell to the correct type.
    
    - parameter treeSourceView: The tree source view.
    - parameter cell:           The cell to prepare.
    - parameter indexPath:      The index path to prepare the cell for.
    - parameter cellStyle:      The tree source view cell style to use for the cell.
    */
    func treeSourceView(
        treeSourceView: TreeSourceView,
        updateCell cell: UITableViewCell,
        forIndexPath indexPath: NSIndexPath,
        withCellStyle cellStyle: TreeSourceViewCellStyle)
}

/// A protocol to which delegates of `TreeSourceView` instances must conform.
public protocol TreeSourceViewDelegate: class
{
    // MARK: - Selection
    
    /**
    Notifies the delegate that the tree source view's selected index path has changed.
    
    - parameter treeSourceView: The tree source view.
    - parameter indexPath:      The new selected index path.
    */
    func treeSourceView(treeSourceView: TreeSourceView, selectionChangedToIndexPath indexPath: NSIndexPath)
    
    /**
     Notifies the delegate that the user tapped the current selected index path.
     
     - parameter treeSourceView: The tree source view.
     */
    func treeSourceViewTappedSelectedItem(treeSourceView: TreeSourceView)
}

/// An animated tree-style source view.
///
/// This class is backed by `UITableView` internally, so it uses `UITableViewCell` (or subclasses) to display items. Due
/// to the animation design of the tree source view, cells must be reused without removing them. Therefore, all cells
/// must be of the same type, and are provided to the data source by the tree source view, which updates their
/// appearance. To change the cell type, modify the `cellType` property.
public final class TreeSourceView: UIView
{
    // MARK: - Data Source and Delegate
    
    /// The data source for the tree source view.
    public weak var dataSource: TreeSourceViewDataSource?
    {
        didSet
        {
            tableView.reloadData()
        }
    }
    
    /// The delegate for the tree source view.
    public weak var delegate: TreeSourceViewDelegate?
    
    // MARK: - Cells
    
    /// The cell type for the tree source view.
    ///
    /// Cells are automatically initialized. As cells are reused without removal for transitions, all cells must be of
    /// the same type.
    public var cellType = UITableViewCell.self
    
    // MARK: - Current Index Path
    
    /// Backing property for `selectedIndexPath`.
    var _selectedIndexPath = NSIndexPath()
    {
        didSet
        {
            delegate?.treeSourceView(self, selectionChangedToIndexPath: selectedIndexPath)
        }
    }
    
    /// The current selected index path of the tree source view.
    public var selectedIndexPath: NSIndexPath
    {
        get
        {
            return _selectedIndexPath
        }
        set(newValue)
        {
            _selectedIndexPath = newValue
            tableView.reloadData()
        }
    }
    
    // MARK: - Table View
    
    /// The internal table view.
    let tableView = UITableView(frame: CGRectZero, style: .Plain)
    
    /// The helper object, which implement's the table view's data source and delegate.
    private let helper = TreeSourceViewHelper()
    
    // MARK: - Initialization
    private func setup()
    {
        // give the helper a reference back to the tree source view - this property is weak, so no retain cycle
        helper.treeSourceView = self
        
        // set up the table view
        tableView.backgroundColor = UIColor.clearColor()
        tableView.dataSource = helper
        tableView.delegate = helper
        tableView.separatorStyle = .None
        addSubview(tableView)
    }
    
    /**
     Initializes a tree source view with a frame.
     
     - parameter frame: The frame.
     */
    public override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    /**
     Initializes a tree source view with a coder object. Currently, this method of initialization is not properly
     supported.
     
     - parameter coder: The coder object.
     */
    public required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        setup()
    }
    
    // MARK: - Table View Integration
    private var numberOfRootSections: Int
    {
        return dataSource?.treeSourceView(self, numberOfChildrenAtIndexPath: NSIndexPath()) ?? 0
    }
    
    // MARK: - Appearance
    public var rowHeight: CGFloat
    {
        get { return tableView.rowHeight }
        set(newValue) { tableView.rowHeight = newValue }
    }
    
    // MARK: - Layout
    
    /// Used internally for layout. Do not call this function directly.
    public override func layoutSubviews()
    {
        super.layoutSubviews()
        tableView.frame = bounds
    }
}

/// Enumerates the cell styles in a `TreeSourceView`.
///
/// Cell types can use this enumeration to modify their appearance depending on their current purpose.
public enum TreeSourceViewCellStyle
{
    /// The cell is used for upward navigation - the parents of the current navigation path.
    case Upward
    
    /// The cell is used as a root navigation item.
    case Root
    
    /// The cell is used to display the current navigation path.
    case Current
    
    /// The cell is used for downward navigation - the children of the current navigation path.
    case Downward
}
