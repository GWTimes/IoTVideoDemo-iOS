//
//  IVPlaybackViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2019/12/11.
//  Copyright © 2019 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import MBProgressHUD
import IVDevTools

class IVPlaybackViewController: IVDevicePlayerViewController {
    
    @IBOutlet weak var timelineView: IVTimelineView?
    @IBOutlet weak var indicatorLabel: UILabel!
    @IBOutlet weak var deviceRecordBtn: UIButton!
    @IBOutlet weak var speedView: UIStackView!
    @IBOutlet weak var speedButton: UIButton!
      
    var thumbdlr: IVThumbnailDownloader!
    
    var playbackPlayer: IVPlaybackPlayer? {
        get { return player as? IVPlaybackPlayer }
        set { player = newValue }
    }
    
    deinit {
        thumbdlr?.cancel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        thumbdlr = IVThumbnailDownloader(deviceId: device.deviceID)
        playbackPlayer = IVPlaybackPlayer(deviceId: device.deviceID)
                
        IVConfigMgr.addCfgObserverInvoke(forKey: "IOT_PLAYBACK_STRATEGY", observer: { [weak self](cfg) in
            if let strategy = IVPlaybackStrategy(rawValue: UInt(cfg.value) ?? 0) {
                self?.playbackPlayer?.playbackStrategy = cfg.enable ? strategy : .ascending
            }
        })
        
        timelineView?.delegate = self
        deviceRecordBtn.isSelected = UserDefaults.standard.bool(forKey: "\(device.deviceID).isSelected")
        speedView.isHidden = true
    }
        
    /// 获取回放列表
    func loadPlaybackItems(timeRange: IVTime, completionHandler: @escaping ([IVPlaybackItem]?) -> Void) {
        indicatorLabel.isHidden = true
        IVPlaybackPlayer.getPlaybackList(ofDevice: device.deviceID, pageIndex: 0, countPerPage: 10000, startTime: timeRange.start, endTime: timeRange.end, filterType: nil, ascendingOrder: true) { (page, err) in
            guard let items = page?.items else {
                completionHandler(nil)
                if let err = err as NSError? {
                    IVPopupView.showConfirm(title: err.localizedDescription, message: "\(err.userInfo["debugInfo"] ?? "")" , in: self.view)
                }
                return
            }
            
            completionHandler(items)
        }
    }

    /// 获取日期列表
    func loadDateList(timeRange: IVTime, completionHandler: @escaping ([NSNumber]?) -> Void) {
        IVPlaybackPlayer.getDateList(ofDevice: device.deviceID, pageIndex: 0, countPerPage: 10000, startTime: timeRange.start, endTime: timeRange.end) { (page, err) in
            guard let items = page?.items else {
                completionHandler(nil)
                if let err = err as NSError? {
                    IVPopupView.showConfirm(title: err.localizedDescription, message: "\(err.userInfo["debugInfo"] ?? "")" , in: self.view)
                }
                return
            }
            
            completionHandler(items)
        }
    }

    @IBAction func deviceRecordClicked(_ sender: UIButton) {
        let data: Data
        if !sender.isSelected {
            data = "record_start".data(using: .utf8)!
        } else {
            data = "record_stop".data(using: .utf8)!
        }
        
        sender.isEnabled = false
        let hud = ivLoadingHud()
        IVMessageMgr.sharedInstance.sendData(toDevice: device.deviceID, data: data, withoutResponse: { [weak self]_, err in
            hud.hide()
            guard let `self` = self else { return }
            if let err = err {
                IVPopupView.showAlert(message: err.localizedDescription, in: self.view)
            } else {
                IVPopupView.showAlert(message: "发送成功", in: self.view)
                sender.isSelected = !sender.isSelected
                UserDefaults.standard.set(sender.isSelected, forKey: "\(self.device.deviceID).isSelected")
            }
            
            sender.isEnabled = true
        })
    }
    
    override func playClicked(_ sender: UIButton) {
        guard let playbackPlayer = playbackPlayer else { return }
                
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            var dstitem: IVPlaybackItem?
            var dsttime: TimeInterval?
            if let pts = timelineView?.viewModel.pts.value,
               let item = timelineView?.viewModel.anyRawItem?.rawValue as? IVPlaybackItem {
                dsttime = (item.startTime <= pts && pts <= item.endTime) ? pts : item.startTime
                dstitem = item
            } else if let item = timelineView?.viewModel.current.rawItems.last?.rawValue as? IVPlaybackItem {
                dsttime = item.startTime
                dstitem = item
            } else {
                sender.isSelected = !sender.isSelected
                IVPopupView.showAlert(title: "当前日期无可播放文件", in: self.view)
                return
            }
            
            if let item = dstitem, let time = dsttime {
                if playbackPlayer.status == .paused {
                    playbackPlayer.resume()
                } else if playbackPlayer.connStatus == .connected {
                    playbackPlayer.seek(toTime: time, playbackItem: item)
                } else {
                    playbackPlayer.setPlaybackItem(item, seekToTime: time)
                    playbackPlayer.play()
                }
            }
        } else {
            playbackPlayer.pause()
        }
    }
    
    @IBAction func sliderTouchUp(_ sender: UISlider) {
        indicatorLabel.isHidden = true
        sender.isEnabled = false
        let speed = (sender.value < 1.0 ? 0.5 : round(sender.value))
        playbackPlayer?.setPlaybackSpeed(speed, completionHandler: { [weak self](err) in
            guard let `self` = self else { return }
            sender.isEnabled = true
            if let err = err {
                logError(err)
                IVPopupView.showAlert(title: "设置倍速失败", message: err.localizedDescription)
                sender.value = self.playbackPlayer?.playbackSpeed ?? 1.0
            }
        })
    }

    @IBAction func sliderCancel(_ sender: UISlider) {
        indicatorLabel.isHidden = true
        sender.value = self.playbackPlayer?.playbackSpeed ?? 1.0
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        indicatorLabel.isHidden = false
        let speed = (sender.value < 1.0 ? 0.5 : round(sender.value))
        indicatorLabel.text = String(format: "%.1fX", speed)
        speedButton.setTitle(indicatorLabel.text, for: .normal)
    }
    
    @IBAction func speedClicked(_ sender: UIButton) {
        speedView.isHidden = !speedView.isHidden
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dstVC = segue.destination as? IVDownloadTableViewController {
            let allDownloadItems = IVDownloadManager.shared.allDownloadItems
            dstVC.device = device
            dstVC.allItems = timelineView?.viewModel.current.rawItems.compactMap({
                let fileTime = UInt64($0.start * 1000)
                return allDownloadItems.first(where: { $0.fileTime ==  fileTime }) ??
                    IVDownloadItem(deviceId: device.deviceID, fileTime: fileTime)
            }) ?? []
            
            if dstVC.allItems.count > 0 {
                let files: [UInt64] = dstVC.allItems.map { $0.fileTime }
                thumbdlr.cancel()
                thumbdlr.downloadThumbnails(files, progress: { (file, data, err) in
                    let item = dstVC.allItems.first(where: { $0.fileTime == file })
                    if let data = data {
                        logInfo("dlthumb ok, file:\(item?.fileTime ?? 0) \(Float(data.count)/1024.0)KB")
                        item?.thumbnail.value = UIImage(data: data) ?? UIImage(named: "bad_image")
                    } else {
                        item?.thumbnail.value = UIImage(named: "notfound_image")
                    }
                }, canceled: {
                    logDebug("downloadThumbnails task canceled.")
                }, finished: { (err) in
                    if let err = err {
                        dstVC.allItems.forEach { (item) in
                            if item.thumbnail.value == nil {
                                item.thumbnail.value = UIImage(named: "bad_image")
                            }
                        }
                        showAlert(msg: "\(err)", title:"缩略图下载出错")
                    }
                    logDebug("downloadThumbnails task finished: \(err as Any)")
                })
            }
        }
    }
    
    override func player(_ player: IVPlayer, didEndOfFile fileTime: TimeInterval, error: Error?) {
        super.player(player, didEndOfFile: fileTime, error: error)
        if let err = error as NSError? {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let datetime = fmt.string(from: Date(timeIntervalSince1970: fileTime))
            showAlert(msg: "文件：\(datetime) \n 原因：\(err.localizedDescription)", title: "播放错误")
        }
    }
}

extension IVPlaybackViewController: IVTimelineViewDelegate {
    func timelineView(_ timelineView: IVTimelineView, markListForCalendarAt time: IVTime, completionHandler: @escaping ([IVCSMarkItem]?) -> Void) {
        logDebug("loadDateList", Date(timeIntervalSince1970: time.start), Date(timeIntervalSince1970: time.end))
        loadDateList(timeRange: time) { (dates) in
            let markItems = dates?.compactMap({ $0.intValue }) ?? []
            completionHandler(markItems)
        }
    }
        
    func timelineView(_ timelineView: IVTimelineView, itemsForTimelineAt timeRange: IVTime, completionHandler: @escaping ([IVTimelineItem]?) -> Void) {
        loadPlaybackItems(timeRange: timeRange) { (playbackItems) in
            let timelineItems = playbackItems?.compactMap({ IVTimelineItem(start: $0.startTime,
                                                                          end: $0.endTime,
                                                                          type: $0.type,
                                                                          rawValue: $0) })
            completionHandler(timelineItems)
        }
    }
    
    func timelineView(_ timelineView: IVTimelineView, didSelectItem item: IVTimelineItem?, at time: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {[weak self] in
            self?.indicatorLabel.isHidden = true
        }
        guard let playbackPlayer = playbackPlayer else { return }
        if let playbackItem = item?.rawValue as? IVPlaybackItem {
            if playbackPlayer.status == .stopped {
                playbackPlayer.setPlaybackItem(playbackItem, seekToTime: time)
                playbackPlayer.play()
            } else {
                playbackPlayer.seek(toTime: time, playbackItem: playbackItem)
            }
            activityIndicatorView.startAnimating()
        }
    }
    
    func timelineView(_ timelineView: IVTimelineView, didSelectDateAt time: IVTime) {
        logInfo("select at date \(Date(timeIntervalSince1970: time.start))")
    }

    func timelineView(_ timelineView: IVTimelineView, didSelectRangeAt time: IVTime, longest: Bool) {
        
    }

    func timelineView(_ timelineView: IVTimelineView, didScrollTo time: TimeInterval) {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let date = Date(timeIntervalSince1970: round(time))
        indicatorLabel.text = fmt.string(from: date)
        indicatorLabel.isHidden = false
    }
    
    override func player(_ player: IVPlayer, didUpdatePTS PTS: TimeInterval) {
        super.player(player, didUpdatePTS: PTS)
        
        let sec = UInt(PTS + 0.5)
        if UInt(timelineView?.viewModel.pts.value ?? 0) != sec {
            DispatchQueue.main.async { [weak self] in
                self?.timelineView?.viewModel.pts.value = TimeInterval(sec)
            }
        }
    }
}

