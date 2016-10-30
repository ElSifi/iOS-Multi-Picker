//
//  PickerDialog.swift
//
//  Created by Mohamed ElSifi on 25/10/2016.
//

import Foundation
import UIKit
import QuartzCore
import ObjectiveC


class MultiPickerDialog: UIView, UITableViewDelegate, UITableViewDataSource {
    
    typealias MultiPickerCallback = (values: [[String: String]]) -> Void
    
    /* Constants */
    private let kPickerDialogDefaultButtonHeight:       CGFloat = 50
    private let kPickerDialogDefaultButtonSpacerHeight: CGFloat = 1
    private let kPickerDialogCornerRadius:              CGFloat = 7
    private let kPickerDialogDoneButtonTag:             Int     = 1
    
    /* Views */
    private var dialogView:   UIView!
    private var titleLabel:   UILabel!
    private var picker:       UITableView!
    private var cancelButton: UIButton!
    private var doneButton:   UIButton!
    
    /* Variables */
    private var pickerData =         [[String: String]]()
    private var selectedPickerValues: [String]?
    private var callback:            MultiPickerCallback?
    
    
    /* Overrides */
    init() {
        super.init(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height))
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.dialogView = createContainerView()
        
        self.dialogView!.layer.shouldRasterize = true
        self.dialogView!.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.mainScreen().scale
        
        self.dialogView!.layer.opacity = 0.5
        self.dialogView!.layer.transform = CATransform3DMakeScale(1.3, 1.3, 1)
        
        self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        
        picker.delegate = self
        picker.dataSource = self
        picker.allowsMultipleSelection = true
        

        /*
         NSIndexPath* selectedCellIndexPath= [NSIndexPath indexPathForRow:0 inSection:0];
         [self tableView:tableViewList didSelectRowAtIndexPath:selectedCellIndexPath];
         [tableViewList selectRowAtIndexPath:selectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
         */
        
        self.addSubview(self.dialogView!)
        
        
    }
    
    /* Handle device orientation changes */
    func deviceOrientationDidChange(notification: NSNotification) {
        close() // For now just close it
    }
    
    /* Helper to find row of selected value */
    func findIndicesForValues(values: [String], array: [[String: String]]) -> [Int] {
        var selectedIndices : [Int] = []
        for (index, dictionary) in array.enumerate() {
            for selectedOption in values {
                if dictionary["value"] == selectedOption {
                    selectedIndices.append(index)
                }
            }
            
        }
        return selectedIndices
    }
    
    /* Create the dialog view, and animate opening the dialog */
    func show(title: String, doneButtonTitle: String = "Select", cancelButtonTitle: String = "Cancel", options: [[String: String]], selected: [String]? = nil, callback: MultiPickerCallback) {
        self.titleLabel.text = title
        self.pickerData = options
        self.doneButton.setTitle(doneButtonTitle, forState: .Normal)
        self.cancelButton.setTitle(cancelButtonTitle, forState: .Normal)
        self.callback = callback
        
        if selected != nil {
            self.selectedPickerValues = selected
            let selectedIndices = findIndicesForValues(selected!, array: options)
            print("selectedIndices \(selectedIndices)")
            for index in selectedIndices{
                let selectedCellIndexPath = NSIndexPath.init(forRow: index, inSection: 0)
                self.tableView(picker, didSelectRowAtIndexPath: selectedCellIndexPath)
                picker.selectRowAtIndexPath(selectedCellIndexPath, animated: true, scrollPosition: .None)
            }
        }
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.window?.addSubview(self)
        appDelegate.window?.bringSubviewToFront(self)
        appDelegate.window?.endEditing(true)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MultiPickerDialog.deviceOrientationDidChange(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
        
        /* Anim */
        UIView.animateWithDuration(
            0.2,
            delay: 0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: { () -> Void in
                self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
                self.dialogView!.layer.opacity = 1
                self.dialogView!.layer.transform = CATransform3DMakeScale(1, 1, 1)
            },
            completion: nil
        )
    }
    
    /* Dialog close animation then cleaning and removing the view from the parent */
    private func close() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        let currentTransform = self.dialogView.layer.transform
        
        let startRotation = (self.valueForKeyPath("layer.transform.rotation.z") as? NSNumber) as? Double ?? 0.0
        let rotation = CATransform3DMakeRotation((CGFloat)(-startRotation + M_PI * 270 / 180), 0, 0, 0)
        
        self.dialogView.layer.transform = CATransform3DConcat(rotation, CATransform3DMakeScale(1, 1, 1))
        self.dialogView.layer.opacity = 1
        
        UIView.animateWithDuration(
            0.2,
            delay: 0,
            options: UIViewAnimationOptions.TransitionNone,
            animations: { () -> Void in
                self.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
                self.dialogView.layer.transform = CATransform3DConcat(currentTransform, CATransform3DMakeScale(0.6, 0.6, 1))
                self.dialogView.layer.opacity = 0
        }) { (finished: Bool) -> Void in
            for v in self.subviews {
                v.removeFromSuperview()
            }
            
            self.removeFromSuperview()
        }
    }
    
    /* Creates the container view here: create the dialog, then add the custom content and buttons */
    private func createContainerView() -> UIView {
        let screenSize = countScreenSize()
        let dialogSize = CGSizeMake(
            300,
            230
                + kPickerDialogDefaultButtonHeight
                + kPickerDialogDefaultButtonSpacerHeight)
        
        // For the black background
        self.frame = CGRectMake(0, 0, screenSize.width, screenSize.height)
        
        // This is the dialog's container; we attach the custom content and the buttons to this one
        let dialogContainer = UIView(frame: CGRectMake((screenSize.width - dialogSize.width) / 2, (screenSize.height - dialogSize.height) / 2, dialogSize.width, dialogSize.height))
        
        // First, we style the dialog to match the iOS8 UIAlertView >>>
        let gradient: CAGradientLayer = CAGradientLayer(layer: self.layer)
        gradient.frame = dialogContainer.bounds
        gradient.colors = [UIColor(red: 218/255, green: 218/255, blue: 218/255, alpha: 1).CGColor,
                           UIColor(red: 233/255, green: 233/255, blue: 233/255, alpha: 1).CGColor,
                           UIColor(red: 218/255, green: 218/255, blue: 218/255, alpha: 1).CGColor]
        
        let cornerRadius = kPickerDialogCornerRadius
        gradient.cornerRadius = cornerRadius
        dialogContainer.layer.insertSublayer(gradient, atIndex: 0)
        
        dialogContainer.layer.cornerRadius = cornerRadius
        dialogContainer.layer.borderColor = UIColor(red: 198/255, green: 198/255, blue: 198/255, alpha: 1).CGColor
        dialogContainer.layer.borderWidth = 1
        dialogContainer.layer.shadowRadius = cornerRadius + 5
        dialogContainer.layer.shadowOpacity = 0.1
        dialogContainer.layer.shadowOffset = CGSizeMake(0 - (cornerRadius + 5) / 2, 0 - (cornerRadius + 5) / 2)
        dialogContainer.layer.shadowColor = UIColor.blackColor().CGColor
        dialogContainer.layer.shadowPath = UIBezierPath(roundedRect: dialogContainer.bounds, cornerRadius: dialogContainer.layer.cornerRadius).CGPath
        
        // There is a line above the button
        let lineView = UIView(frame: CGRectMake(0, dialogContainer.bounds.size.height - kPickerDialogDefaultButtonHeight - kPickerDialogDefaultButtonSpacerHeight, dialogContainer.bounds.size.width, kPickerDialogDefaultButtonSpacerHeight))
        lineView.backgroundColor = UIColor(red: 198/255, green: 198/255, blue: 198/255, alpha: 1)
        dialogContainer.addSubview(lineView)
        // ˆˆˆ
        
        //Title
        self.titleLabel = UILabel(frame: CGRectMake(10, 10, 280, 30))
        self.titleLabel.textAlignment = NSTextAlignment.Center
        self.titleLabel.textColor = UIColor(hex: 0x333333)
        self.titleLabel.font = UIFont(name: "AvenirNext-Medium", size: 18)
        dialogContainer.addSubview(self.titleLabel)
        
        self.picker = UITableView(frame: CGRectMake(0, 30,100, 100))
        //self.picker.setValue(UIColor(hex: 0x333333), forKeyPath: "textColor")
        self.picker.autoresizingMask = UIViewAutoresizing.FlexibleRightMargin
        self.picker.frame.size.width = 300
        self.picker.frame.size.height = 200
        self.picker.backgroundColor = UIColor.clearColor()
        dialogContainer.addSubview(self.picker)
        
        // Add the buttons
        addButtonsToView(dialogContainer)
        
        return dialogContainer
    }
    
    /* Add buttons to container */
    private func addButtonsToView(container: UIView) {
        let buttonWidth = container.bounds.size.width / 2
        
        self.cancelButton = UIButton(type: UIButtonType.Custom) as UIButton
        self.cancelButton.frame = CGRectMake(
            0,
            container.bounds.size.height - kPickerDialogDefaultButtonHeight,
            buttonWidth,
            kPickerDialogDefaultButtonHeight
        )
        self.cancelButton.setTitleColor(UIColor(hex: 0x555555), forState: UIControlState.Normal)
        self.cancelButton.setTitleColor(UIColor(hex: 0x555555), forState: UIControlState.Highlighted)
        self.cancelButton.titleLabel!.font = UIFont(name: "AvenirNext-Medium", size: 15)
        self.cancelButton.layer.cornerRadius = kPickerDialogCornerRadius
        self.cancelButton.addTarget(self, action: #selector(MultiPickerDialog.buttonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        container.addSubview(self.cancelButton)
        
        self.doneButton = UIButton(type: UIButtonType.Custom) as UIButton
        self.doneButton.frame = CGRectMake(
            buttonWidth,
            container.bounds.size.height - kPickerDialogDefaultButtonHeight,
            buttonWidth,
            kPickerDialogDefaultButtonHeight
        )
        self.doneButton.tag = kPickerDialogDoneButtonTag
        self.doneButton.setTitleColor(UIColor(hex: 0x555555), forState: UIControlState.Normal)
        self.doneButton.setTitleColor(UIColor(hex: 0x555555), forState: UIControlState.Highlighted)
        self.doneButton.titleLabel!.font = UIFont(name: "AvenirNext-Medium", size: 15)
        self.doneButton.layer.cornerRadius = kPickerDialogCornerRadius
        self.doneButton.addTarget(self, action: #selector(MultiPickerDialog.buttonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        container.addSubview(self.doneButton)
    }
    
    func buttonTapped(sender: UIButton!) {
        if sender.tag == kPickerDialogDoneButtonTag {
            var theSelectedValues : [[String: String]] = []
            
            if let indexPathsForSelectedRows = self.picker.indexPathsForSelectedRows{
                for indexPath  in indexPathsForSelectedRows{
                    let cell = self.picker.cellForRowAtIndexPath(indexPath)
                    theSelectedValues.append(["value":(cell?.contnetIdentifier)!, "display":(cell?.textLabel?.text)!])
                }
            }
            
            self.callback?(values: theSelectedValues)
        }
        
        close()
    }
    
    func countScreenSize() -> CGSize {
        let screenWidth = UIScreen.mainScreen().applicationFrame.size.width
        let screenHeight = UIScreen.mainScreen().bounds.size.height
        
        return CGSizeMake(screenWidth, screenHeight)
    }
    
    /* Helper function: count and return the screen's size */
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell =  tableView.dequeueReusableCellWithIdentifier("cell")
        if ((cell == nil)) {
            cell = UITableViewCell.init(style: .Default, reuseIdentifier: "cell")
        }
        
        let theCell = cell!
        
        theCell.textLabel?.text = self.pickerData[indexPath.row]["display"]
        theCell.contnetIdentifier = self.pickerData[indexPath.row]["value"]
        theCell.textLabel?.textAlignment = .Left
        theCell.backgroundColor = UIColor.clearColor()
        theCell.selectionStyle = .None
        
        let selectedIndexPaths = tableView.indexPathsForSelectedRows
        let rowIsSelected = selectedIndexPaths != nil && selectedIndexPaths!.contains(indexPath)
        theCell.accessoryType = rowIsSelected ? .Checkmark : .None
        
        
        return theCell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.pickerData.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //tableView.cellForRowAtIndexPath(indexPath)?.selected = true
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.Checkmark
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        //tableView.cellForRowAtIndexPath(indexPath)?.selected = false
        tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = UITableViewCellAccessoryType.None
    }
    
    
    
}

var AssociatedObjectHandleOfCellContnetIdentifier: UInt8 = 0

extension UITableViewCell {
    var contnetIdentifier:String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectHandleOfCellContnetIdentifier) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectHandleOfCellContnetIdentifier, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: Float = 1.0){
        let r = Float((hex >> 16) & 0xFF)
        let g = Float((hex >> 8) & 0xFF)
        let b = Float((hex) & 0xFF)
        
        self.init(red: CGFloat(r / 255.0), green: CGFloat(g / 255.0), blue:CGFloat(b / 255.0), alpha: CGFloat(alpha))
    }
    
}

