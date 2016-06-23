//
//  ScriptViewController.swift
//  OneFuncApp
//
//  Created by mcy on 16/5/31.
//  Copyright © 2016年 mcy. All rights reserved.
//

import UIKit
import WebKit

class ScriptViewController: UIViewController {
  
  private let tableView = UITableView(frame: CGRectZero, style: .Grouped)
  private var scriptList = [ScriptModel]()
  private var oldNameTitle = ""
  private let renameView = RenameView()
  private let blurView = JCRBlurView()
  private let animationDuration = 0.5
  private var extensionName = ""
  private var oldExtensionName = ""
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    makeConstriants()
    setupAction()
    fetchScriptList()
  }
  
  private func setupUI() {
    navigationItem.title = "脚本"
    view.backgroundColor = UIColor.whiteColor()
    
    let rightImage = UIImage(named: "new")!.imageWithRenderingMode(.AlwaysOriginal)
    navigationItem.rightBarButtonItem = UIBarButtonItem(image: rightImage, style: .Plain, target: self, action: #selector(addScript(_:)))
    let leftImage = UIImage(named: "sweep")!.imageWithRenderingMode(.AlwaysOriginal)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftImage, style: .Plain, target: self, action: #selector(sweep(_:)))
    
    tableView.registerClass(ScriptCell.self, forCellReuseIdentifier: NSStringFromClass(ScriptCell))
    tableView.delegate = self
    tableView.dataSource = self
    tableView.contentInset.bottom = Constants.Size.tabBarHeight
    tableView.scrollIndicatorInsets.bottom = tableView.contentInset.bottom
    tableView.backgroundColor = UIColor.whiteColor()
    //    tableView.separatorStyle = .None
    let header = MJRefreshNormalHeader.init(refreshingBlock: { [weak self] _ in
      guard let `self` = self else { return }
      self.fetchScriptList()
      })
    header.lastUpdatedTimeLabel.hidden = true
    
    tableView.mj_header = header
    
    renameView.hidden = true
    blurView.hidden = true
    blurView.alpha = 0
    renameView.layer.cornerRadius = 5
    
    renameView.layer.shadowOffset = CGSize(width: 0, height: 3)
    renameView.layer.shadowRadius = 3.0
    renameView.layer.shadowColor = UIColor.blackColor().CGColor
    renameView.layer.shadowOpacity = 0.4
    
    view.addSubview(tableView)
    view.addSubview(blurView)
    view.addSubview(renameView)
  }
  
  private func makeConstriants() {
    tableView.snp_makeConstraints { (make) in
      make.edges.equalTo(view)
    }
    
    renameView.snp_makeConstraints{ (make) in
      make.center.equalTo(view)
      make.leading.trailing.equalTo(view).inset(Sizer.valueForPhone(inch_3_5: 20, inch_4_0: 20, inch_4_7: 42, inch_5_5: 62))
      make.height.equalTo(80)
    }
    
    blurView.snp_makeConstraints { (make) in
      make.edges.equalTo(view)
    }
  }
  
  private func setupAction() {
    renameView.submitButton.addTarget(self, action: #selector(submit), forControlEvents: .TouchUpInside)
    blurView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(blurTap)))
    renameView.luaButton.addTarget(self, action: #selector(luaClick(_:)), forControlEvents: .TouchUpInside)
    renameView.txtButton.addTarget(self, action: #selector(txtClick(_:)), forControlEvents: .TouchUpInside)
    renameView.newNameTextField.addTarget(self, action: #selector(editingChanged), forControlEvents: .EditingChanged)
  }
  
  private func getSelectedScriptFile() {
    let request = Network.sharedManager.post(url: ServiceURL.Url.getSelectedScriptFile, timeout:Constants.Timeout.request)
    let session = Network.sharedManager.session()
    let task = session.dataTaskWithRequest(request) { [weak self] data, _, error in
      guard let `self` = self else { return }
      self.view.hideHUD()
      if let data = data {
        let json = JSON(data: data)
        switch json["code"].intValue {
        case 0:
          for cell in self.tableView.visibleCells {
            let indexPath = self.tableView.indexPathForCell(cell)
            if self.scriptList[indexPath!.row].name == json["data"]["filename"].stringValue {
              self.tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: .None)
              let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as! ScriptCell
              cell.scriptSelectedHidden(false)
              cell.backgroundColor = ThemeManager.Theme.lightGrayBackgroundColor
              let model = self.scriptList[indexPath!.row]
              model.isSelected = true
            }
          }
        default:
          self.alert(title: Constants.Text.prompt, message: json["message"].stringValue, delegate: nil, cancelButtonTitle: Constants.Text.ok)
        }
      }
      if error != nil {
        self.alert(title: Constants.Text.prompt, message: Constants.Error.failure, delegate: nil, cancelButtonTitle: Constants.Text.ok)
      }
    }
    task.resume()
  }
  
  private func fetchScriptList() {
    self.view.showHUD()
    let request = Network.sharedManager.post(url: ServiceURL.Url.getFileList, timeout:Constants.Timeout.dataRequest, parameters: ["directory":"lua/scripts/"])
    let session = Network.sharedManager.session()
    let task = session.dataTaskWithRequest(request) { [weak self] data, _, error in
      guard let `self` = self else { return }
      if let data = data {
        self.scriptList.removeAll()
        let json = JSON(data: data)
        switch json["code"].intValue {
        case 0:
          let list = json["data"]["list"]
          for item in list.dictionaryValue {
            if item.1["mode"].stringValue != "directory" {
              let model = ScriptModel(item.1, name: item.0)
              self.scriptList.append(model)
            }
          }
        default:break
        }
        self.scriptList.sortInPlace({ $0.time > $1.time })
        self.tableView.reloadData()
        self.getSelectedScriptFile()
      }
      if error != nil {
        self.alert(title: Constants.Text.prompt, message: Constants.Error.failure, delegate: nil, cancelButtonTitle: Constants.Text.ok)
      }
      self.tableView.mj_header.endRefreshing()
    }
    task.resume()
  }
  
  /// 重命名
  private func renameFile() {
    let parameters = [
      "filename": ServiceURL.scriptsPath + self.oldNameTitle + self.oldExtensionName,
      "newfilename": ServiceURL.scriptsPath + renameView.newNameTextField.text! + self.extensionName
    ]
    let request = Network.sharedManager.post(url: ServiceURL.Url.renameFile, timeout:Constants.Timeout.request, parameters: parameters)
    let session = Network.sharedManager.session()
    let task = session.dataTaskWithRequest(request) { [weak self] data, _, error in
      guard let `self` = self else { return }
      if let data = data {
        let json = JSON(data: data)
        switch json["code"].intValue {
        case 0:
          self.view.showHUD(.Message, text: Constants.Text.editSuccessful, autoHide: true, autoHideDelay: 0.5,completionHandler: {
            self.closeRenameViewAnimator()
            self.fetchScriptList()
          })
        default:
          self.alert(title: Constants.Text.prompt, message: json["message"].stringValue, delegate: nil, cancelButtonTitle: Constants.Text.ok)
        }
      }
      if error != nil {
        self.alert(title: Constants.Text.prompt, message: Constants.Error.failure, delegate: nil, cancelButtonTitle: Constants.Text.ok)
      }
    }
    task.resume()
  }
  
  @objc private func addScript(button: UIBarButtonItem) {
    let newScriptViewController = NewScriptViewController()
    newScriptViewController.delegate = self
    self.navigationController?.pushViewController(newScriptViewController, animated: true)
  }
  
  /// 扫一扫
  @objc private func sweep(button: UIBarButtonItem) {
    button.enabled = false
    self.view.showHUD()
    let request = Network.sharedManager.post(url: ServiceURL.Url.bindQrcode, timeout:Constants.Timeout.request)
    let session = Network.sharedManager.session()
    let task = session.dataTaskWithRequest(request) { [weak self] data, _, error in
      guard let `self` = self else { return }
      if let data = data {
        let json = JSON(data: data)
        switch json["code"].intValue {
        case 0:
          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            self.view.hideHUD()
            button.enabled = true
          })
        case 3:
          self.view.hideHUD()
          button.enabled = true
          self.alert(title: Constants.Text.prompt, message: json["message"].stringValue, delegate: nil, cancelButtonTitle: Constants.Text.ok)
        default:
          self.alert(title: Constants.Text.prompt, message: json["message"].stringValue, delegate: nil, cancelButtonTitle: Constants.Text.ok)
        }
      }
      if error != nil {
        self.alert(title: Constants.Text.prompt, message: Constants.Error.failure, delegate: nil, cancelButtonTitle: Constants.Text.ok)
      }
    }
    task.resume()
  }
  
  @objc private func editingChanged() {
    if (self.oldNameTitle + self.oldExtensionName) != (renameView.newNameTextField.text! + self.extensionName) && renameView.newNameTextField.text?.characters.count != 0{
      renameView.submitButton.enabled = true
      renameView.submitButton.backgroundColor = ThemeManager.Theme.tintColor
    } else {
      renameView.submitButton.enabled = false
      renameView.submitButton.backgroundColor = ThemeManager.Theme.lightTextColor
    }
  }
  
  @objc private func info(button: UIButton) {
    let indexPath = NSIndexPath(forRow: button.tag, inSection: 0)
    let string = scriptList[indexPath.row].name as NSString
    self.oldNameTitle = string.substringWithRange(NSMakeRange(0, string.length-4))
    self.oldExtensionName = Suffix.haveSuffix(scriptList[indexPath.row].name)
    self.extensionName = self.oldExtensionName
    updateButtonStatus(self.oldExtensionName)
    /// ActionSheet
    let actionSheet = UIActionSheet()
    actionSheet.title = self.oldNameTitle+self.oldExtensionName
    actionSheet.delegate = self
    if self.oldExtensionName != Suffix.Section.Txt.title {
      actionSheet.destructiveButtonIndex = 0
      actionSheet.cancelButtonIndex = 3
      actionSheet.addButtonWithTitle("运行")
      actionSheet.addButtonWithTitle("停止")
    } else {
      actionSheet.cancelButtonIndex = 1
    }
    actionSheet.addButtonWithTitle("重命名")
    actionSheet.addButtonWithTitle(Constants.Text.cancel)
    actionSheet.showInView(view)
    
    guard self.oldExtensionName != Suffix.Section.Txt.title else { return }
    
    for cell in tableView.visibleCells {
      let cell = cell as! ScriptCell
      cell.scriptSelectedHidden(true)
      cell.backgroundColor = UIColor.whiteColor()
    }
    for model in scriptList {
      model.isSelected = false
    }
    
    let cell = tableView.cellForRowAtIndexPath(indexPath) as! ScriptCell
    cell.scriptSelectedHidden(false)
    let model = scriptList[indexPath.row]
    model.isSelected = true
    cell.backgroundColor = ThemeManager.Theme.lightGrayBackgroundColor
    selectScriptFile(scriptList[indexPath.row].name)
  }
  
  @objc private func submit() {
    renameView.newNameTextField.resignFirstResponder()
    renameFile()
  }
  
  @objc private func blurTap() {
    if !renameView.newNameTextField.resignFirstResponder() {
      closeRenameViewAnimator()
    } else {
      renameView.newNameTextField.resignFirstResponder()
    }
  }
  
  @objc private func luaClick(button: UIButton) {
    buttonCustomStatus(selectedButton: button, unselectedButton: renameView.txtButton)
    extensionName = button.titleLabel!.text!
    editingChanged()
  }
  
  @objc private func txtClick(button: UIButton) {
    buttonCustomStatus(selectedButton: button, unselectedButton: renameView.luaButton)
    extensionName = button.titleLabel!.text!
    editingChanged()
  }
  
  private func buttonCustomStatus(selectedButton selectedButton: UIButton, unselectedButton: UIButton) {
    selectedButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    selectedButton.backgroundColor = ThemeManager.Theme.redBackgroundColor
    unselectedButton.setTitleColor(ThemeManager.Theme.lightTextColor, forState: .Normal)
    unselectedButton.backgroundColor = ThemeManager.Theme.separatorColor
  }
  
  private func updateButtonStatus(extensionName: String) {
    if extensionName == renameView.luaButton.titleLabel?.text {
      buttonCustomStatus(selectedButton: renameView.luaButton, unselectedButton: renameView.txtButton)
    } else if extensionName == renameView.txtButton.titleLabel?.text {
      buttonCustomStatus(selectedButton: renameView.txtButton, unselectedButton: renameView.luaButton)
    }
  }
  
  private func closeRenameViewAnimator() {
    navigationController?.tabBarController?.tabBar.hidden = false
    navigationController?.setNavigationBarHidden(false, animated: true)
    UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 15, options: [], animations: {
      self.blurView.alpha = 0
      self.renameView.alpha = 0
      }, completion: { (_) in
        self.renameView.hidden = true
        self.blurView.hidden = true
        self.renameView.transform = CGAffineTransformIdentity
    })
  }
  
  private func openRenameViewAnimator() {
    navigationController?.tabBarController?.tabBar.hidden = true
    navigationController?.setNavigationBarHidden(true, animated: true)
    renameView.newNameTextField.text = self.oldNameTitle
    renameView.hidden = false
    blurView.hidden = false
    renameView.alpha = 1
    renameView.transform = CGAffineTransformTranslate(renameView.transform, 0, self.view.frame.height/2)
    UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 15, options: [], animations: {
      self.renameView.transform = CGAffineTransformIdentity
      self.blurView.alpha = 1
      }, completion: { (_) in
        
    })
  }
}

extension ScriptViewController: UIActionSheetDelegate {
  func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
    guard buttonIndex != actionSheet.cancelButtonIndex else { return }
    if self.oldExtensionName != Suffix.Section.Txt.title {
      switch buttonIndex {
      /// 运行
      case 0: launchScriptFile()
      /// 停止
      case 1: isRunning()
      /// 重命名
      case 2: openRenameViewAnimator()
      default:break
      }
    } else {
      /// 重命名
      if buttonIndex == 0 {
        openRenameViewAnimator()
      }
    }
  }
  
  private func launchScriptFile() {
    self.view.showHUD()
    let request = Network.sharedManager.post(url: ServiceURL.Url.launchScriptFile, timeout: Constants.Timeout.request)
    let session = Network.sharedManager.session()
    let task = session.dataTaskWithRequest(request) { [weak self] data, _, error in
      guard let `self` = self else { return }
      self.view.hideHUD()
      if let data = data {
        let json = JSON(data: data)
        switch json["code"].intValue {
        case 0:
          self.view.showHUD(.Message, text: json["message"].stringValue, autoHide: true, autoHideDelay: 0.5)
        case 2:
          let messgae = json["message"].stringValue + "\n" + json["detail"].stringValue
          self.alert(title: Constants.Text.prompt, message: messgae, delegate: nil, cancelButtonTitle: Constants.Text.ok)
        default:
          self.alert(title: Constants.Text.prompt, message: json["message"].stringValue, delegate: nil, cancelButtonTitle: Constants.Text.ok)
        }
      }
      if error != nil {
        self.alert(title: Constants.Text.prompt, message: Constants.Error.failure, delegate: nil, cancelButtonTitle: Constants.Text.ok)
      }
    }
    task.resume()
  }
  
  private func stopScriptFile() {
    let request = Network.sharedManager.post(url: ServiceURL.Url.recycle, timeout: Constants.Timeout.request)
    let session = Network.sharedManager.session()
    let task = session.dataTaskWithRequest(request) { [weak self] data, _, error in
      guard let `self` = self else { return }
      if let data = data {
        let json = JSON(data: data)
        switch json["code"].intValue {
        case 0:
          self.view.showHUD(.Message, text: json["message"].stringValue, autoHide: true, autoHideDelay: 0.5)
        default:
          self.alert(title: Constants.Text.prompt, message: json["message"].stringValue, delegate: nil, cancelButtonTitle: Constants.Text.ok)
        }
      }
      if error != nil {
        self.alert(title: Constants.Text.prompt, message: Constants.Error.failure, delegate: nil, cancelButtonTitle: Constants.Text.ok)
      }
    }
    task.resume()
  }
  
  private func selectScriptFile(name: String) {
    let request = Network.sharedManager.post(url: ServiceURL.Url.selectScriptFile, timeout: Constants.Timeout.request, parameters: ["filename" : name])
    let session = Network.sharedManager.session()
    let task = session.dataTaskWithRequest(request) { [weak self] data, _, error in
      guard let `self` = self else { return }
      if let data = data {
        let json = JSON(data: data)
        switch json["code"].intValue {
        case 0: break
        default:
          self.alert(title: Constants.Text.prompt, message: json["message"].stringValue, delegate: nil, cancelButtonTitle: Constants.Text.ok)
        }
      }
      if error != nil {
        self.alert(title: Constants.Text.prompt, message: Constants.Error.failure, delegate: nil, cancelButtonTitle: Constants.Text.ok)
      }
    }
    task.resume()
  }
  
  private func isRunning() {
    self.view.showHUD()
    let request = Network.sharedManager.post(url: ServiceURL.Url.isRunning, timeout: Constants.Timeout.request)
    let session = Network.sharedManager.session()
    let task = session.dataTaskWithRequest(request) { [weak self] data, _, error in
      guard let `self` = self else { return }
      self.view.hideHUD()
      if let data = data {
        let json = JSON(data: data)
        switch json["code"].intValue {
        case 0: self.view.showHUD(.Message, text: Constants.Text.notRuningScript, autoHide: true, autoHideDelay: 0.7)
        default: self.stopScriptFile()
        }
      }
      if error != nil {
        self.alert(title: Constants.Text.prompt, message: Constants.Error.failure, delegate: nil, cancelButtonTitle: Constants.Text.ok)
      }
    }
    task.resume()
  }
}

/// 左右侧边滑动按钮
extension ScriptViewController {
  private func customButton(title: String, titleColor: UIColor = UIColor.whiteColor(), backgroundColor: UIColor) -> UIButton {
    let button = UIButton(type: .Custom)
    button.setTitle(title, forState: .Normal)
    button.backgroundColor = backgroundColor
    button.setTitleColor(titleColor, forState: .Normal)
    return button
  }
  
  private func leftButtons() -> [AnyObject] {
    return [customButton("编辑", backgroundColor: ThemeManager.Theme.tintColor)]
  }
  
  private func rightButtons() -> [AnyObject] {
    return [customButton("删除", backgroundColor: UIColor.redColor())]
  }
}

extension ScriptViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.scriptList.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(NSStringFromClass(ScriptCell), forIndexPath: indexPath) as! ScriptCell
    cell.bind(scriptList[indexPath.row])
    cell.leftUtilityButtons = leftButtons()
    cell.rightUtilityButtons = rightButtons()
    cell.delegate = self
    cell.infoButton.addTarget(self, action: #selector(info(_:)), forControlEvents: .TouchUpInside)
    cell.infoButton.tag = indexPath.row
    
    let isSelected = scriptList[indexPath.row].isSelected
    cell.scriptSelectedHidden(!isSelected)
    if isSelected {
      cell.backgroundColor = ThemeManager.Theme.lightGrayBackgroundColor
    } else {
      cell.backgroundColor = UIColor.whiteColor()
    }
    
    return cell
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let suffix = Suffix.haveSuffix(scriptList[indexPath.row].name)
    guard suffix != Suffix.Section.Txt.title else {
      self.view.showHUD(.Message, text: Constants.Text.notSelected, autoHide: true, autoHideDelay: 0.7)
      return
    }
    
    for cell in tableView.visibleCells {
      let cell = cell as! ScriptCell
      cell.scriptSelectedHidden(true)
      cell.backgroundColor = UIColor.whiteColor()
    }
    for model in scriptList {
      model.isSelected = false
    }
    
    let cell = tableView.cellForRowAtIndexPath(indexPath) as! ScriptCell
    cell.scriptSelectedHidden(false)
    let model = scriptList[indexPath.row]
    model.isSelected = true
    cell.backgroundColor = ThemeManager.Theme.lightGrayBackgroundColor
    selectScriptFile(scriptList[indexPath.row].name)
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 60
  }
  
  func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 0.01
  }
  
  func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return 0.01
  }
}

extension ScriptViewController: SWTableViewCellDelegate {
  func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
    switch index {
    case 0:
      if let indexPath = tableView.indexPathForCell(cell) {
        let fileName = scriptList[indexPath.row].name
        let suffix = Suffix.haveSuffix(fileName)
        guard suffix != Suffix.Section.Xxt.title else {
          self.view.showHUD(.Message, text: Constants.Text.notEnScript, autoHide: true, autoHideDelay: 0.7)
          return
        }
        let scriptDetailViewController = ScriptDetailViewController(fileName: fileName)
        self.navigationController?.pushViewController(scriptDetailViewController, animated: true)
      }
    default:break
    }
  }
  
  func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
    switch index {
    case 0:
      /// 删除文件
      if let indexPath = tableView.indexPathForCell(cell) {
        let parameters = ["filename" : scriptList[indexPath.row].name]
        let request = Network.sharedManager.post(url: ServiceURL.Url.removeFile, timeout:Constants.Timeout.request, parameters: parameters)
        let session = Network.sharedManager.session()
        let task = session.dataTaskWithRequest(request) { [weak self] data, _, error in
          guard let `self` = self else { return }
          if let data = data {
            let json = JSON(data: data)
            switch json["code"].intValue {
            case 0:
              self.scriptList.removeAtIndex(indexPath.row)
              self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Left)
              self.tableView.setEditing(false, animated: true)
              self.view.showHUD(.Message, text: Constants.Text.removeSuccessful, autoHide: true, autoHideDelay: 0.5)
            default:
              self.alert(title: Constants.Text.prompt, message: json["message"].stringValue, delegate: nil, cancelButtonTitle: Constants.Text.ok)
            }
          }
          if error != nil {
            self.alert(title: Constants.Text.prompt, message: Constants.Error.failure, delegate: nil, cancelButtonTitle: Constants.Text.ok)
          }
        }
        task.resume()
      }
    default:break
    }
  }
  
  func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
    return true
  }
}

extension ScriptViewController: NewScriptViewControllerDelegate {
  func reloadScriptList() {
    fetchScriptList()
  }
}
