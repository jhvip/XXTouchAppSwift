//
//  AuthorizationCell.swift
//  XXTouchApp
//
//  Created by mcy on 16/6/21.
//  Copyright © 2016年 mcy. All rights reserved.
//

import UIKit

class AuthorizationCell: UITableViewCell {
  private let titleLabel = UILabel()
  private let icon = UIImageView(image: UIImage(named: "vip_01"))
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
    makeConstriants()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    self.selectionStyle = .None
    titleLabel.text = "正在获取设备授权信息.."
    titleLabel.font = UIFont.systemFontOfSize(Sizer.valueForDevice(phone: 17, pad: 21))
    titleLabel.textColor = ThemeManager.Theme.tintColor
    contentView.addSubview(icon)
    contentView.addSubview(titleLabel)
  }
  
  private func makeConstriants() {
    icon.snp_makeConstraints { (make) in
      make.centerY.equalTo(titleLabel)
      make.leading.equalTo(contentView).offset(Sizer.valueForDevice(phone: 15, pad: 20))
      make.width.height.equalTo(Sizer.valueForDevice(phone: 25, pad: 33))
    }
    
    titleLabel.snp_makeConstraints { (make) in
      make.center.equalTo(contentView)
    }
  }
  
  func bind(title: String) {
    titleLabel.text = title
  }
  
  func iconVip() {
    icon.image = UIImage(named: "vip_02")
  }
  
  func iconNoVip() {
    icon.image = UIImage(named: "vip_01")
  }
  
}
