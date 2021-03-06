//
//  PhotoViewController.swift
//  XXTouchApp
//
//  Created by mcy on 16/7/1.
//  Copyright © 2016年 mcy. All rights reserved.
//

import UIKit

class PhotoViewController: UIViewController {
  var funcCompletionHandler: FuncCompletionHandler
  private let image: UIImage
  private var photoView: XXTPhotoView!
  private var modelDic = [[String: AnyObject]]()
  private let type: FuncListType
  private var pixelImage: XXTPixelImage!
  private var originalPixelImage: XXTPixelImage!
  private let touchContentView = TouchContentView()
  private var posNumber = 0
  //  private var mposHeight: CGFloat = 45
  //  private let customHeight: CGFloat = 35
  private var originalHeight: CGFloat = 0
  
  init(type: FuncListType, image: UIImage, funcCompletionHandler: FuncCompletionHandler) {
    self.type = type
    self.funcCompletionHandler = funcCompletionHandler
    self.image = image
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // 隐藏电池栏
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    makeConstriants()
    setupAction()
    bind()
  }
  
  private func setupUI() {
    automaticallyAdjustsScrollViewInsets = false
    view.backgroundColor = UIColor.whiteColor()
    
    photoView = XXTPhotoView(frame: view.bounds, andImage: self.image)
    photoView.backgroundColor = UIColor.blackColor()
    view.addSubview(photoView)
    
    touchContentView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.85)
    touchContentView.hidden = true
    view.addSubview(touchContentView)
    
    originalPixelImage = XXTPixelImage(UIImage: self.image)
    pixelImage = XXTPixelImage(UIImage: self.image)
  }
  
  private func makeConstriants() {
    //    switch self.type {
    //    case .Pos:
    //      touchContentView.snp_makeConstraints { (make) in
    //        make.top.equalTo(snp_topLayoutGuideBottom)
    //        make.leading.trailing.equalTo(view)
    //        make.height.equalTo(customHeight)
    //      }
    //    case .MPos:
    //      touchContentView.snp_makeConstraints { (make) in
    //        make.top.equalTo(snp_topLayoutGuideBottom)
    //        make.leading.trailing.equalTo(view)
    //        make.height.equalTo(mposHeight)
    //      }
    //    default: break
    //    }
  }
  
  private func setupAction() {
    photoView.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    touchContentView.insertButton.addTarget(self, action: #selector(insert), forControlEvents: .TouchUpInside)
    touchContentView.copyButton.addTarget(self, action: #selector(copyText), forControlEvents: .TouchUpInside)
    touchContentView.clearButton.addTarget(self, action: #selector(clear), forControlEvents: .TouchUpInside)
  }
  
  private func bind() {
    navigationItem.title = self.funcCompletionHandler.titleNames.first
  }
}

extension PhotoViewController {
  private func setData(point: CGPoint, title: String = "选择完成") {
    guard let imgSize = photoView.imageView.image?.size else { return }
    let frameSize = photoView.imageView.frame.size
    let scale = (imgSize.width/frameSize.width)
    let x = point.x * scale
    let y = point.y * scale
    touchContentView.buttonStatusUpdate(touchContentView.insertButton, enabled: true, backgroundColor: ThemeManager.Theme.tintColor, titleColor: UIColor.whiteColor())
    touchContentView.buttonStatusUpdate(touchContentView.copyButton, enabled: true, backgroundColor: ThemeManager.Theme.tintColor, titleColor: UIColor.whiteColor())
    touchContentView.buttonStatusUpdate(touchContentView.clearButton, enabled: true, backgroundColor: ThemeManager.Theme.tintColor, titleColor: UIColor.whiteColor())
    navigationItem.title = title
    touchContentView.hidden = false
    let color = pixelImage.getColorOfPoint(CGPoint(x: Int(x),y: Int(y)))
    let dic = [
      "x" : Int(x),
      "y" : Int(y),
      "r": Int(color.red),
      "g": Int(color.green),
      "b": Int(color.blue),
      "c": NSNumber(unsignedInt: color.getColor()),
      "color": color.getColorHex()
    ]
    self.modelDic.append(dic)
    let content = JsManager.sharedManager.getCustomFunction(self.funcCompletionHandler.id, models: self.modelDic)
    touchContentView.addContent(content)
    pixelImage.setColor(XXTColor(red: 255, green: 0, blue: 0, alpha: 255), ofPoint: CGPointMake(x, y))
    photoView.imageView.image = pixelImage.getUIImage()
  }
  
  @objc private func handleTap(tap: UITapGestureRecognizer) {
    let point = tap.locationInView(tap.view)
    switch self.type {
    case .Pos:
      if self.funcCompletionHandler.titleNames.count > 1 {
        posNumber += 1
        switch posNumber {
        case 1:
          setData(point, title: self.funcCompletionHandler.titleNames[posNumber])
        case 2:
          setData(point)
        default: break
        }
      } else {
        posNumber += 1
        switch posNumber {
        case 1:
          setData(point)
        default: break
        }
      }
    case .MPos:
      setData(point, title: "可继续选择")
    default: break
    }
    touchContentView.snp_remakeConstraints { (make) in
      make.top.equalTo(snp_topLayoutGuideBottom)
      make.leading.trailing.equalTo(view)
      make.height.equalTo(touchContentView.getContentHeight() + 22)
    }
    if originalHeight == 0 {
      originalHeight = touchContentView.getContentHeight() + 22
    }
  }
  
  @objc private func insert(button: UIButton) {
    funcCompletionHandler.completionHandler?(touchContentView.label.text!)
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  @objc private func copyText(button: UIButton) {
    UIPasteboard.generalPasteboard().string = touchContentView.label.text!
    self.view.showHUD(.Success, text: Constants.Text.copy)
  }
  
  @objc private func clear(button: UIButton) {
    touchContentView.label.text = ""
    touchContentView.buttonStatusUpdate(touchContentView.insertButton, enabled: false, backgroundColor: ThemeManager.Theme.separatorColor, titleColor: ThemeManager.Theme.lightTextColor)
    touchContentView.buttonStatusUpdate(touchContentView.copyButton, enabled: false, backgroundColor: ThemeManager.Theme.separatorColor, titleColor: ThemeManager.Theme.lightTextColor)
    touchContentView.buttonStatusUpdate(touchContentView.clearButton, enabled: false, backgroundColor: ThemeManager.Theme.separatorColor, titleColor: ThemeManager.Theme.lightTextColor)
    photoView.imageView.image = originalPixelImage.getUIImage()
    pixelImage = nil
    pixelImage = XXTPixelImage(UIImage: self.image)
    posNumber = 0
    self.modelDic.removeAll()
    navigationItem.title = self.funcCompletionHandler.titleNames.first
    switch self.type {
    case .Pos:
      touchContentView.snp_remakeConstraints { (make) in
        make.top.equalTo(snp_topLayoutGuideBottom)
        make.leading.trailing.equalTo(view)
        make.height.equalTo(originalHeight)
      }
    case .MPos:
      touchContentView.snp_remakeConstraints { (make) in
        make.top.equalTo(snp_topLayoutGuideBottom)
        make.leading.trailing.equalTo(view)
        make.height.equalTo(originalHeight)
      }
    default: break
    }
  }
}

class TouchContentView: UIView {
  let label = UILabel()
  lazy var insertButton: Button = {
    let button = Button(type: .Custom)
    button.setTitle("插入", forState: .Normal)
    button.backgroundColor = ThemeManager.Theme.tintColor
    button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    button.titleLabel?.font = UIFont.systemFontOfSize(14)
    button.layer.cornerRadius = 4.0
    return button
  }()
  
  lazy var copyButton: Button = {
    let button = Button(type: .Custom)
    button.setTitle("拷贝", forState: .Normal)
    button.backgroundColor = ThemeManager.Theme.tintColor
    button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    button.titleLabel?.font = UIFont.systemFontOfSize(14)
    button.layer.cornerRadius = 4.0
    return button
  }()
  
  lazy var clearButton: Button = {
    let button = Button(type: .Custom)
    button.setTitle("清除", forState: .Normal)
    button.backgroundColor = ThemeManager.Theme.tintColor
    button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
    button.titleLabel?.font = UIFont.systemFontOfSize(14)
    button.layer.cornerRadius = 4.0
    return button
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    makeConstriants()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    label.textColor = UIColor.blackColor()
    label.numberOfLines = 0
    label.lineBreakMode = .ByWordWrapping
    label.font = UIFont.systemFontOfSize(11)
    
    self.addSubview(label)
    self.addSubview(insertButton)
    self.addSubview(copyButton)
    self.addSubview(clearButton)
  }
  
  private func makeConstriants() {
    label.snp_makeConstraints { (make) in
      make.leading.equalTo(self).offset(5)
      make.trailing.equalTo(self).offset(-120)
      make.centerY.equalTo(self)
      make.top.equalTo(self).offset(2)
    }
    
    clearButton.snp_makeConstraints { (make) in
      make.trailing.equalTo(self).offset(-5)
      make.centerY.equalTo(self)
      make.width.equalTo(35)
      make.height.equalTo(25)
    }
    
    copyButton.snp_makeConstraints { (make) in
      make.trailing.equalTo(clearButton.snp_leading).offset(-5)
      make.centerY.equalTo(self)
      make.width.equalTo(35)
      make.height.equalTo(25)
    }
    
    insertButton.snp_makeConstraints { (make) in
      make.trailing.equalTo(copyButton.snp_leading).offset(-5)
      make.centerY.equalTo(self)
      make.width.equalTo(35)
      make.height.equalTo(25)
    }
  }
  
  func buttonStatusUpdate(button: UIButton, enabled: Bool, backgroundColor: UIColor, titleColor: UIColor) {
    button.enabled = enabled
    button.backgroundColor = backgroundColor
    button.setTitleColor(titleColor, forState: .Normal)
  }
  
  func addContent(content: String) {
    label.text = content
  }
  
  func getContentHeight() -> CGFloat {
    let text: NSString = NSString(CString: label.text!.cStringUsingEncoding(NSUTF8StringEncoding)!,
                                  encoding: NSUTF8StringEncoding)!
    let attributes = [NSFontAttributeName: label.font]
    let option = NSStringDrawingOptions.UsesLineFragmentOrigin
    let rect = text.boundingRectWithSize(CGSize(width: 0, height: 1000), options: option, attributes: attributes, context: nil)
    return rect.size.height
  }
}
