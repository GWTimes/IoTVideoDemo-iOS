//
//  IVCloudStorageViewController.swift
//  IotVideoDemoTX
//
//  Created by ZhaoYong on 2020/3/18.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo.IVMessageMgr
import SwiftyJSON
import IVVAS

class IVCloudStorageViewController: IVDeviceAccessableTVC {
    @IBOutlet weak var currentPkg: UILabel!
    @IBOutlet weak var endTime: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetDes()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        getCurrentPgk()
    }
    
    private func getCurrentPgk() {
        IVVAS.shared.getServiceDetailInfo(withDeviceId: device.deviceID) { (json, error) in
            if let error = error {
                logError("查询云存状态失败",error)
                self.resetDes()
                return
            }
            if let json = json {
                let parseJson = JSON(parseJSON: json)["data"]
                if let utcExpire = parseJson["endTime"].int, let serviceType = parseJson["curOrderPkgType"].int , let status = parseJson["status"].int, let day = parseJson["curOrderStorageDays"].int {
                    let fmt = DateFormatter()
                    fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let expireString = fmt.string(from: Date(timeIntervalSince1970: TimeInterval(utcExpire)))
                    self.endTime.text = expireString
                    var showText = serviceType == 1 ? "\(day)天 全时云存":"\(day)天 事件云存"
                    if Int(Date().timeIntervalSince1970) > utcExpire {
                        showText +=  "(已过期\(status == 2 ? "云端数据未过期，续费仍可查看":""))"
                    } else if status != 1 {
                        showText += "(已转移/退订)"
                    }
                    
                    self.currentPkg.text = showText
                }
            } else {
                self.resetDes()
            }
        }
    }
    
    func resetDes() {
        DispatchQueue.main.async {
            self.currentPkg.text = "暂无可用套餐"
            self.endTime.text = ""
        }
    }
}


