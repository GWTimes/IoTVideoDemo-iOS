//
//  IJKMoviePlayer.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2020/1/12.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import UIKit
import IJKMediaFramework
import IoTVideo
import IVVAS
import IVDevTools


class IJKMediaViewController: UIViewController, IVDeviceAccessable {
    var device: IVDevice!
    
    @IBOutlet weak var timelineView: IVTimelineView?
    @IBOutlet weak var seekTimeLabel: UILabel!
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var alarmList: UITableView!
    var mediaPlayer: IJKFFMoviePlayerController?
    
    var csItem: IVCSPlaybackItem? = nil
    
    var seekTime: TimeInterval = 0
    
    var eventsInfo: IVCSEventsInfo? {
        didSet {
            if let newEvents = eventsInfo?.list {
                events = newEvents
            }
        }
    }
    var events: [IVCSEvent] = []
    var autoPlayNextMedia = true
    
    lazy var timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(refreshProgressSlider), userInfo: nil, repeats: true)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "云回放"
        setupNavBar()
        
        IVVAS.shared.serviceId = IVConfigMgr.cfgValue(forKey: "IOT_VAS_SERVICE_ID")

        addMediaObservers()
        timelineView?.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mediaPlayer?.shutdown()
        NotificationCenter.default.removeObserver(self)
        timer.invalidate()
    }

    func setupNavBar() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: UITextField().then({
            $0.borderStyle = .roundedRect
            $0.placeholder = "Open URL ..."
            $0.returnKeyType = .go
            $0.enablesReturnKeyAutomatically = true
            $0.addEvent(.editingReturn) { [unowned self] v in
                guard let text = (v as! UITextField).text, !text.isEmpty else { return }
                if let url = URL(string: text), UIApplication.shared.canOpenURL(url) {
                    self.openURL(url)
                } else {
                    showAlert(msg: text, title: "无效URL")
                }
            }
        }))
    }
    
    func openURL(_ url: URL, item: IVCSPlaybackItem? = nil) {
        self.csItem = item
        if self.csItem == nil {
            var starttime: Int = 0
            var endtime  : Int = starttime + 60*60
            
            let regExp1 = try! NSRegularExpression(pattern: #"starttime_epoch=(\d+)&endtime_epoch=(\d+)$"#, options: .caseInsensitive)
            let regExp2 = try! NSRegularExpression(pattern: #"(\d+)_(\d+).ts$"#, options: .caseInsensitive)
            for regExp in [regExp1, regExp2] {
                if let matche = regExp.matches(in: url.absoluteString, options: .reportCompletion, range: NSMakeRange(0, url.absoluteString.count)).first {
                    if matche.numberOfRanges > 2 {
                        starttime = Int(url.absoluteString[Range(matche.range(at: 1))!])!
                        endtime   = Int(url.absoluteString[Range(matche.range(at: 2))!])!
                        break
                    }
                }
            }
            self.csItem = IVCSPlaybackItem(start: starttime, end: endtime)
            self.csItem?.url = url
        }
        
        logDebug("Open URL:", url, self.csItem)
        
        let oldMediaPlayer = self.mediaPlayer
        DispatchQueue.main.async {
            oldMediaPlayer?.shutdown()
            
            if let newMediaPlayer = IJKFFMoviePlayerController(contentURL: url, with: IJKFFOptions.byDefault()) {
                newMediaPlayer.scalingMode = .aspectFit
                newMediaPlayer.shouldAutoplay = true
                newMediaPlayer.playbackVolume = 1.0
                newMediaPlayer.prepareToPlay()

                newMediaPlayer.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                newMediaPlayer.view.frame = self.videoView.bounds
                self.videoView.autoresizesSubviews = true
                self.videoView.addSubview(newMediaPlayer.view)

                let oldview = oldMediaPlayer?.view
                DispatchQueue.main.asyncAfter(deadline: .now()+5) {
                    oldview?.removeFromSuperview()
                }
                self.timer.fireDate = .distantPast
                self.activityIndicatorView.startAnimating()

                self.mediaPlayer = newMediaPlayer
                self.mediaPlayer?.play()
            }
        }
    }
    
    func getMarkList(time: IVTime, completionHandler: @escaping ([IVCSMarkItem]?) -> Void) {
        let hud = ivLoadingHud()
        let timezone = TimeZone.current.secondsFromGMT()
        
        IVVAS.shared.getVideoDateList(withDeviceId: device.deviceID, timezone: timezone) { (json, error) in
            hud.hide()
            guard let json = json else {
                logError("\(String(describing: error))")
                completionHandler(nil)
                return
            }
            logDebug(json)

            let jsonModel = json.decode(IVModel<IVCSMarkItems>.self)
            guard jsonModel?.code == 0 else {
                logError("\(String(describing: error))")
                completionHandler([])
                return
            }
            
            let list = jsonModel?.data?.list ?? []
            return completionHandler(list)
        }
    }

    func getPlaybackList(time: IVTime, completionHandler: @escaping ([IVCSPlaybackItem]?) -> Void) {
        let hud = ivLoadingHud()
        
        IVVAS.shared.getVideoPlayList(withDeviceId: device.deviceID, startTime: time.start, endTime: time.end) { [weak self](json, error) in
            hud.hide()
            guard let `self` = self else { return }
            guard let json = json, error == nil else {
                logError("\(String(describing: error))")
                IVPopupView.showAlert(message: "\(String(describing: error))", in: self.view)
                completionHandler([])
                return
            }
            
            let jsonModel = json.decode(IVModel<IVCSPlayListInfo>.self)
            
            guard jsonModel?.code == 0 else {
                logError("\(String(describing: jsonModel?.msg))")
                completionHandler([])
                return
            }
            let list = jsonModel?.data?.list ?? []
            return completionHandler(list)
        }
    }

    func getEventList(at time: IVTime) {
        IVVAS.shared.getEventList(withDeviceId: device.deviceID, startTime: time.start, endTime: time.end, pageSize: 50, filterTypeMask: [0x8000], validCloudStorage: true) { [weak self](json, error) in
            guard let `self` = self else { return }
            logInfo("event list: \(json ?? "") , error: \(String(describing: error))")
            guard let json = json, error == nil else {
                logError("\(String(describing: error))")
                return
            }
            
            let jsonModel = json.decode(IVModel<IVCSEventsInfo>.self)
            
            guard jsonModel?.code == 0 else {
                self.alarmList.isHidden = true
                if jsonModel?.code == 10010 {
                    logInfo(jsonModel?.msg ?? "无记录")
                } else {
                    logError("\(String(describing: jsonModel?.msg))")
                }
                return
            }
            
            self.eventsInfo = jsonModel?.data
            if self.events.count == 0 {
                self.alarmList.isHidden = true
            } else {
                self.alarmList.isHidden = false
                self.alarmList.reloadData()
            }
        }
    }

    func getPlayUrl(_ item: IVCSPlaybackItem, responseHandler: ((_ url: URL?) -> Void)? = nil) {
        if let url = item.url {
            responseHandler?(url)
        } else {
            IVVAS.shared.getVideoPlayAddress(withDeviceId: device.deviceID, startTime: TimeInterval(item.start), endTiem: TimeInterval(item.end)) { (json, error) in
                guard let json = json else {
                    if (error! as NSError).code != 21000 {
                        logError("getPlayUrl error \(item.start) \(String(describing: error))")
                        showAlert(msg: "getPlayUrl error", title: "\(item.start) \(String(describing: error))")
                    }
                    responseHandler?(nil)
                    return
                }
                
                if let playInfo = json.decode(IVModel<IVCSPlayInfo>.self)?.data,
                    let urlstr = playInfo.url, let url = URL(string: urlstr) {
                    item.url = url
                    logDebug("getPlayUrl", item.start, item.end, item.url)
                    responseHandler?(url)
                } else {
                    logError("getPlayUrl empty \(item.start) \(String(describing: error))")
                    showAlert(msg: "getPlayUrl empty", title: "\(item.start) \(String(describing: error))")
                    responseHandler?(nil)
                }
            }
        }
    }
    
    private func prepareToPlay(_ item: IVCSPlaybackItem) {
        logDebug("prepareToPlay", item.start)
        self.timer.fireDate = .distantFuture

        getPlayUrl(item) { [weak self](url) in
            if let url = url {
                self?.openURL(url, item: item)
            }
        }
        
        if let nextCSItem = self.timelineView?.viewModel.nextRawItem?.rawValue as? IVCSPlaybackItem {
            getPlayUrl(nextCSItem)
        }
    }
        
    @objc func refreshProgressSlider() {
        guard let mediaPlayer = mediaPlayer, mediaPlayer.playbackState == .playing, seekTime == 0 else { return }
        if mediaPlayer.duration > 0, let csItem = csItem {
            let newPTS = Int64(mediaPlayer.currentPlaybackTime + Double(csItem.start) + 0.5)
            print("refreshProgressSlider csItemStart:\(csItem.start) currentPlaybackTime:\(mediaPlayer.currentPlaybackTime) duration:\(mediaPlayer.duration) playableDuration:\(mediaPlayer.playableDuration)")
            timelineView?.viewModel.pts.value = TimeInterval(newPTS)
        }
    }
    
    func seek(toTime time: TimeInterval, playbackItem item: IVCSPlaybackItem) {
        logDebug("seekToTime", time, item)
        if item.start != csItem?.start {
            seekTime = time
            prepareToPlay(item)

        } else {
            mediaPlayer?.currentPlaybackTime = time - TimeInterval(item.start)
        }
    }

    // MARK: - 点击事件
    
    @IBAction func playClicked(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            var dstitem: IVCSPlaybackItem?
            var dsttime: Int?
            if let pts = timelineView?.viewModel.pts.value,
               let item = timelineView?.viewModel.anyRawItem?.rawValue as? IVCSPlaybackItem {
                dsttime = (item.start <= Int(pts) && Int(pts) <= item.end) ? Int(pts) : item.start
                dstitem = item
            } else if let item = timelineView?.viewModel.current.rawItems.last?.rawValue as? IVCSPlaybackItem {
                dsttime = item.start
                dstitem = item
            } else {
                sender.isSelected = !sender.isSelected
                IVPopupView.showAlert(title: "当前日期无可播放文件", in: self.view)
                return
            }
            
            if let mediaPlayer = mediaPlayer, mediaPlayer.playbackState == .paused {
                mediaPlayer.play()
            } else if let item = dstitem, let time = dsttime {
                seek(toTime: TimeInterval(time), playbackItem: item)
                mediaPlayer?.play()
            }
         } else {
            mediaPlayer?.pause()
        }
        refreshProgressSlider()
    }
        
    // MARK: - 播放器代理
    
    func addMediaObservers() {
        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerLoadStateDidChange, object: nil, queue: nil) { (noti) in
//            logDebug(noti)
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerPlaybackDidFinish, object: nil, queue: nil) { [weak self] (noti) in
            guard let `self` = self else { return }
            logDebug("IJKMPMoviePlayerPlaybackDidFinish:", self.mediaPlayer?.playbackState.rawValue, noti.object, self.seekTime)
            if self.autoPlayNextMedia, self.seekTime == 0,
               self.mediaPlayer == (noti.object as? IJKFFMoviePlayerController),
               let nextCSItem = self.timelineView?.viewModel.nextRawItem?.rawValue as? IVCSPlaybackItem {
                self.prepareToPlay(nextCSItem)
            }
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMediaPlaybackIsPreparedToPlayDidChange, object: nil, queue: nil) {[weak self] (noti) in
            guard let `self` = self else { return }
            logDebug("IJKMPMediaPlaybackIsPreparedToPlayDidChange:", self.mediaPlayer?.playbackState.rawValue, noti.object)
            if self.seekTime != 0, let csItem = self.csItem {
                logDebug("seekOffset:", self.seekTime - TimeInterval(csItem.start))
                self.mediaPlayer?.currentPlaybackTime = self.seekTime - TimeInterval(csItem.start)
                self.seekTime = 0
            }
            self.refreshProgressSlider()
        }

        NotificationCenter.default.addObserver(forName: .IJKMPMoviePlayerPlaybackStateDidChange, object: nil, queue: nil) { [weak self](noti) in
            guard let `self` = self else { return }
            logDebug("IJKMPMoviePlayerPlaybackStateDidChange:", self.mediaPlayer?.playbackState.rawValue, noti.object)
            guard let mediaPlayer = self.mediaPlayer else { return }
            mediaPlayer.isPreparedToPlay ? self.activityIndicatorView.stopAnimating() : self.activityIndicatorView.startAnimating()
            self.playBtn.isSelected = mediaPlayer.isPlaying()
        }
    }

}

extension IJKMediaViewController: IVTimelineViewDelegate {
    
    func timelineView(_ timelineView: IVTimelineView, markListForCalendarAt time: IVTime, completionHandler: @escaping ([IVCSMarkItem]?) -> Void) {
        getMarkList(time: time, completionHandler: completionHandler)
    }
    
    func timelineView(_ timelineView: IVTimelineView, itemsForTimelineAt time: IVTime, completionHandler: @escaping ([IVTimelineItem]?) -> Void) {
        getPlaybackList(time: time) { (playbackList) in
            let timelineItems = playbackList?.compactMap({ IVTimelineItem(start: TimeInterval($0.start),
                                                                          end: TimeInterval($0.end),
                                                                          type: "",
                                                                          rawValue: $0) })
            completionHandler(timelineItems)
        }
    }
    
    func timelineView(_ timelineView: IVTimelineView, didSelectItem item: IVTimelineItem?, at time: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {[weak self] in
            self?.seekTimeLabel.isHidden = true
        }
        if let playbackItem = item?.rawValue as? IVCSPlaybackItem {
            seek(toTime: time, playbackItem: playbackItem)
            activityIndicatorView.startAnimating()
        }
        refreshProgressSlider()
    }
    
    func timelineView(_ timelineView: IVTimelineView, didSelectDateAt time: IVTime) {
        getEventList(at: time)
        mediaPlayer?.pause()
    }

    func timelineView(_ timelineView: IVTimelineView, didSelectRangeAt time: IVTime, longest: Bool) {
        
    }

    func timelineView(_ timelineView: IVTimelineView, didScrollTo time: TimeInterval) {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let date = Date(timeIntervalSince1970: round(time))
        seekTimeLabel.text = fmt.string(from: date)
        seekTimeLabel.isHidden = false
    }
}

//MARK: 事件列表
extension IJKMediaViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell? = nil
        cell = tableView.dequeueReusableCell(withIdentifier: "alarmListCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "alarmListCell")
            cell?.imageView?.contentMode = .scaleAspectFit
            cell?.imageView?.snp.updateConstraints({ (make) in
                make.height.equalTo(55)
                make.width.equalTo(cell!.snp.height).multipliedBy(16.0/9.0)
            })
        }
        let event = events[indexPath.row]
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        let date0 = Date(timeIntervalSince1970: TimeInterval(event.startTime))
        let date1 = Date(timeIntervalSince1970: TimeInterval(event.endTime))
        cell?.textLabel?.text = "\(fmt.string(from: date0)) - \(fmt.string(from: date1)) type: \(event.firstAlarmType)"
        cell?.tag = event.startTime
        cell?.imageView?.image = UIImage(named: "placeholder")
        if let prefix = self.eventsInfo?.imgUrlPrefix, let suffix = event.imgUrlSuffix,
           let imgUrl = URL(string: prefix + suffix) {
            DispatchQueue.global().async {[weak cell] in
                do {
                    let imgDat = try Data(contentsOf: imgUrl)
                    if let img = UIImage(data: imgDat) {
                        DispatchQueue.main.async {
                            if cell?.tag == event.startTime {
                                logDebug("image loaded", event.startTime, imgUrl)
                                cell?.imageView?.image = img
                            }
                        }
                    } else {
                        logWarning("image is corrupted", imgUrl)
                    }
                } catch {
                    logWarning("image download failed", error)
                }
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let event = self.events[indexPath.row]
        if let item = timelineView?.viewModel.current.rawItems.first(where: {$0.start <= TimeInterval(event.startTime) && TimeInterval(event.endTime) <= $0.end}) {
            seek(toTime: TimeInterval(event.startTime), playbackItem: IVCSPlaybackItem(start: Int(item.start), end: Int(item.end)))
        } else {
            seek(toTime: TimeInterval(event.startTime), playbackItem: IVCSPlaybackItem(start: event.startTime, end: event.endTime))
        }
        refreshProgressSlider()
    }
    
    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "删除") { (action, view, completion) in
            let event = self.events[indexPath.row]
            IVVAS.shared.deleteEvents(withDeviceId: self.device.deviceID, eventIds: [event.alarmId]) { [weak self](json, error) in
                guard let `self` = self else { return }
                logInfo("devent delete \(String(describing: json))")
                guard error == nil else {
                    logDebug("event delete error  \(String(describing: error))")
                    completion(false)
                    return
                }
                self.events.remove(at: indexPath.row)
                completion(true)
                self.alarmList.reloadData()
            }
        }
        let config = UISwipeActionsConfiguration(actions: [delete])
        return config
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
