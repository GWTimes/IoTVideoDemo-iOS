//
//  IVDownloaderViewController.swift
//  IotVideoDemo
//
//  Created by JonorZhang on 2021/3/19.
//  Copyright © 2021 Tencentcs. All rights reserved.
//

import UIKit
import IoTVideo
import MBProgressHUD
import IJKMediaFramework

/// 下载状态
enum IVDownloadStatus: Equatable {
    case idle, waiting, loading, paused, failed(reason: String), finished
}

/// 下载项目
class IVDownloadItem: NSObject, IVConnectionDelegate {
    /// 设备ID
    public var deviceId: String
    
    /// 文件的开始时间（用来识别文件）ms
    public var fileTime: UInt64
    
    /// 文件总大小
    public var fileSize: IVObservable<UInt>
    
    /// 文件原始名称
    public var fileName: String?
    
    /// 已下载字节数
    public var rcvSize: IVObservable<UInt>
    
    /// 下载速度（字节/秒）
    public var speed: IVObservable<UInt>
 
    /// 下载状态
    public var status: IVObservable<IVDownloadStatus>
    
    /// 缩略图
    public var thumbnail: IVObservable<UIImage?>
    
    /// 构造方法
    public init(deviceId: String, fileTime: UInt64 = 0, fileSize: UInt = 0, rcvSize: UInt = 0, status: IVDownloadStatus = .idle) {
        self.deviceId = deviceId
        self.fileTime = fileTime
        self.fileSize = .init(fileSize)
        self.rcvSize  = .init(rcvSize)
        self.status   = .init(status)
        self.speed    = .init(0)
        self.thumbnail = .init(nil)
        super.init()
    }
    
    private var fh: FileHandle?
    private func fileHandle(at path: String) -> FileHandle {
        guard let fh = fh else {
            if !FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent,
                                                         withIntermediateDirectories: true,
                                                         attributes: nil)
                if !FileManager.default.createFile(atPath: path,
                                                   contents: nil,
                                                   attributes: nil) {
                    fatalError("createFile: \(path)")
                }
            }
            if let fh = FileHandle(forWritingAtPath: path) {
                fh.seekToEndOfFile()
                self.fh = fh
                return fh
            } else {
                fatalError("fileHandle is nil")
            }
        }
        return fh
    }
    
    /// 保存文件
    public func saveData(_ data: Data, at path: String) {
        rcvSize.value += UInt(data.count)
        fileHandle(at: path).write(data)
    }
    
    func connection(_ connection: IVConnection, didUpdateSpeed speed: UInt32) {
        if self.status.value == .loading {
            self.speed.value = UInt(speed)
        }
    }
}


/// 下载管理单例
class IVDownloadManager {
    /// 单例
    public static let shared = IVDownloadManager()
    private init() {}

    /// 下载器字典 [deviceId: downloader]
    private var downloaders: [String: IVFileDownloader] = [:]
    
    private func getDownloader(for item: IVDownloadItem) -> IVFileDownloader {
        var dlr: IVFileDownloader! = downloaders[item.deviceId]
        if dlr == nil {
            dlr = IVFileDownloader(deviceId: item.deviceId)!
            downloaders[item.deviceId] = dlr
        }
        return dlr
    }
    
    /// 所有下载项目
    public var allDownloadItems: [IVDownloadItem] { downloadingItems + downloadedItems }
    
    /// 下载中列表 ../Downloading/deviceId/filename
    public lazy var downloadingItems: [IVDownloadItem] = getDownloadItems(at: downloadingDir, as: .paused)
 
    /// 已下载列表 ../Downloaded/deviceId/filename
    public lazy var downloadedItems: [IVDownloadItem] = getDownloadItems(at: downloadedDir, as: .finished)

    private func getDownloadItems(at downloadDir: String, as status: IVDownloadStatus) -> [IVDownloadItem] {
        var dlItems: [IVDownloadItem] = []
        let deviceIds = FileManager.default.subpaths(atPath: downloadDir) ?? []
        // 根据设备名搜索目录
        for deviceId in deviceIds {
            let devicePath = downloadDir + "/" + deviceId
            let items = FileManager.default.subpaths(atPath: devicePath)?.map({ subpath -> IVDownloadItem in
                // 读取文件信息
                let filePath = devicePath + "/" + subpath
                let attr = try? FileManager.default.attributesOfItem(atPath: filePath)
                let rcvSize = (attr?[.size] as? UInt) ?? 0
                let fileTime = UInt64(subpath)!
                return IVDownloadItem(deviceId: deviceId, fileTime: fileTime, rcvSize: rcvSize, status: status)
            }) ?? []
            dlItems.append(contentsOf: items)
        }
        return dlItems
    }

    /// 下载队列变更
    var updateDownloadItemsCallback: ((_ downloadingItems: [IVDownloadItem], _ downloadedItems: [IVDownloadItem]) -> Void)?

    /// 正在下载目录
    public lazy var downloadingDir: String = getDownloadDir("Downloading")
    
    /// 已下载目录
    public lazy var downloadedDir: String = getDownloadDir("Downloaded")
      
    private func getDownloadDir(_ dirName: String) -> String {
        let docDir = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let dlDir = docDir + "/" + dirName
        do {
            try FileManager.default.createDirectory(atPath: dlDir, withIntermediateDirectories: true, attributes: nil)
        } catch {
            fatalError(error.localizedDescription)
        }
        return dlDir
    }
    
    public func downloadingPath(of item: IVDownloadItem) -> String {
        return downloadingDir + "/\(item.deviceId)/\(item.fileTime)"
    }

    public func downloadedPath(of item: IVDownloadItem) -> String {
        return downloadedDir + "/\(item.deviceId)/\(item.fileTime)"
    }
    
    /// 添加文件到下载队列
    public func addDownloadItem(_ item: IVDownloadItem) {
        if downloadedItems.contains(where: { $0.fileTime == item.fileTime }) {
            logWarning("文件已下载：\(item.fileTime)")
            return
        }
        
        if !downloadingItems.contains(where: { $0.fileTime == item.fileTime }) {
            downloadingItems.append(item)
        }

        let dlr = getDownloader(for: item)
        if dlr.status == .idle {
            item.status.value = .loading
            startDownloadItem(item)
        } else {
            item.status.value = .waiting
        }
    }
    
    /// 开始下载文件
    public func startDownloadItem(_ item: IVDownloadItem) {
        let dlpath = downloadingPath(of: item)
        let dlr = getDownloader(for: item)
        
        if dlr.status != .idle {
            dlr.cancel()
        }
        
        item.status.value = .loading
        dlr.delegate = item

        dlr.downloadPlaybackFile(item.fileTime, offset: UInt32(item.rcvSize.value)) { (fileSize) in
            item.fileSize.value = UInt(fileSize)
        } progress: { (data) in
            item.saveData(data, at: dlpath)
        } canceled: {
            logInfo("下载暂停 文件名：\(item.fileTime)（已下载\(item.rcvSize.value)字节）")
            item.status.value = .paused
        } success: {[weak self] in
            logInfo("下载完成 文件名：\(item.fileTime)（共\(item.rcvSize.value)字节）")
            item.status.value = .finished
            self?.finishedHandler(item)
        } failure: { [weak self](err) in
            item.status.value = .failed(reason: err.localizedDescription)
            self?.failureHandler(item, error: err as NSError)
        }
    }

    /// 下载下一个等待的文件
    public func startDownloadNextWaitingItem() {
        if let nextItem = downloadingItems.first(where: { $0.status.value == .waiting }) {
            startDownloadItem(nextItem)
        }
    }
    
    /// 暂停下载文件
    public func pauseItem(_ item: IVDownloadItem) {
        item.status.value = .paused
        getDownloader(for: item).cancel()
        startDownloadNextWaitingItem()
    }

    /// 移除下载（包括数据）
    public func removeItem(_ item: IVDownloadItem) {
        getDownloader(for: item).cancel()
        if item.status.value != .finished {
            downloadingItems.removeAll(where: { $0.fileTime == item.fileTime })
            removeFile(at: downloadingPath(of: item))
        } else {
            downloadedItems.removeAll(where: { $0.fileTime == item.fileTime })
            removeFile(at: downloadedPath(of: item))
        }
        updateDownloadItemsCallback?(downloadingItems, downloadedItems)
    }
    
    /// 清除数据，但保留item
    public func clearData(_ item: IVDownloadItem) {
        if item.status.value == .loading {
            getDownloader(for: item).cancel()
        }
        
        if item.status.value != .finished {
            removeFile(at: downloadingPath(of: item))
        } else {
            downloadedItems.removeAll(where: { $0.fileTime == item.fileTime })
            removeFile(at: downloadedPath(of: item))
        }
        item.status.value = .idle
        item.rcvSize.value = 0
    }

    private func removeFile(at path: String) {
        do {
            if FileManager.default.fileExists(atPath: path) {
                logDebug("移除文件：\(path)")
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func finishedHandler(_ item: IVDownloadItem) {
        try? FileManager.default.createDirectory(atPath: (downloadedPath(of: item) as NSString).deletingLastPathComponent,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
        try? FileManager.default.moveItem(atPath: downloadingPath(of: item), toPath: downloadedPath(of: item))
        downloadingItems.removeAll { $0.fileTime == item.fileTime }
        downloadedItems.append(item)
        startDownloadNextWaitingItem()
        updateDownloadItemsCallback?(downloadingItems, downloadedItems)
    }

    private func failureHandler(_ item: IVDownloadItem, error: NSError) {
        if let errCode = IVDownloadError(rawValue: UInt(error.code)) {
            switch errCode {
            case .devUnknownError, .dataSizeAbnormal, .incorrectOffset:
//                removeFile(at: downloadingPath(of: item))
//                item.rcvSize.value = 0
                logError(item.fileTime, error)
            default:
                // do nothing here
                break
            }
        } else if let _ = IVConnError(rawValue: UInt(error.code)) {
            // do nothing here
        }
        
        downloadingItems.removeAll { $0.fileTime == item.fileTime }
        startDownloadNextWaitingItem()
        updateDownloadItemsCallback?(downloadingItems, downloadedItems)
    }
}


/// 下载列表视图控制器
class IVDownloadTableViewController: IVDeviceAccessableTVC {
    
    /// 下载管理单例
    let dlrMgr = IVDownloadManager.shared
        
    /// 文件列表
    var allItems: [IVDownloadItem] = [] {
        didSet { tableView.reloadData() }
    }
        
    /// 是否【我的下载】页面
    var isMineDownload: Bool {
        return device == nil
    }
    
    var largeThumbMode: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = (isMineDownload ? "我的下载(\(allItems.count))" : "文件列表(\(allItems.count))")
        tableView.delaysContentTouches = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "小图⇌大图", style: .plain, target: self, action: #selector(toggleThumbMode))

        if allItems.isEmpty {
            IVPopupView.showConfirm(title: "提示",
                                    message: isMineDownload ? "下载列表为空，可以去【录像回放】页面添加文件下载" : "当天没有回放文件，请选择其他日期")
        }
        
        dlrMgr.updateDownloadItemsCallback = { [weak self](downloadingItems, downloadedItems) in
            DispatchQueue.main.async {
                if self?.isMineDownload == true {
                    self?.allItems = downloadingItems + downloadedItems
                } else {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    @objc func toggleThumbMode() {
        largeThumbMode.toggle()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IVDownloadTableViewCell", for: indexPath) as! IVDownloadTableViewCell
        cell.dlItem = allItems[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return [UITableViewRowAction(style: isMineDownload ? .destructive : .normal,
                                     title: isMineDownload ? "删除" : "清除",
                                     handler: { [unowned self](_, indexPath) in
            let dlItem = self.allItems[indexPath.row]

            if dlItem.status.value == .loading {
                self.dlrMgr.pauseItem(dlItem)
            }
            
            if self.isMineDownload == true {
                self.dlrMgr.removeItem(dlItem)
            } else {
                self.dlrMgr.clearData(dlItem)
            }
        })]
    }
        
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = allItems[indexPath.row]
        switch item.status.value {
        case .idle, .paused, .failed:
            dlrMgr.addDownloadItem(item)
        case .waiting:
            dlrMgr.startDownloadItem(item)
        case .loading:
            dlrMgr.pauseItem(item)
            dlrMgr.startDownloadNextWaitingItem()
        case .finished:
            let playerVC = IVMediaPlayerViewController(mediaPath: self.dlrMgr.downloadedPath(of: item))
            self.navigationController?.pushViewController(playerVC, animated: true)
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return largeThumbMode ? 120 : 60
    }
}

class IVDownloadTableViewCell: UITableViewCell {
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var rateLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusDescLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    
    override func prepareForReuse() {
        dlItem.thumbnail.removeAllObserves()
        super.prepareForReuse()
    }
    
    public var dlItem: IVDownloadItem! {
        didSet {
            fileNameLabel.text = "\(dlItem.fileTime)"
            thumbnail.image = dlItem.thumbnail.value ?? UIImage(named: "placeholder")
            
            setupDownloadObserver()
            updateStatusUI()
            updateProgressUI()
            updateSpeedUI()
        }
    }
    
    private func setupDownloadObserver() {
        dlItem.status.observe { (new, old) in
            self.updateStatusUI()
        }
        dlItem.rcvSize.observe { (new, old) in
            self.updateProgressUI()
        }
        dlItem.fileSize.observe { (new, old) in
            self.updateProgressUI()
        }
        dlItem.speed.observe { (new, old) in
            self.updateSpeedUI()
        }
        dlItem.thumbnail.observe { (new, old) in
            DispatchQueue.main.async {
                self.thumbnail.image = new
            }
        }
    }
    
    private func updateProgressUI() {
        let sizeText: String
        let rateText: String
        
        switch dlItem.status.value {
        case .idle, .waiting:
            sizeText = ""
            rateText = ""
        case .finished:
            sizeText = byteLengthDescribe(dlItem.rcvSize.value)
            rateText = "100%"
        default:
            if dlItem.fileSize.value > 0 {
                sizeText = byteLengthDescribe(dlItem.rcvSize.value) + "/" + byteLengthDescribe(dlItem.fileSize.value)
                rateText = String(format: "%.1f%%", Float(dlItem.rcvSize.value) / Float(dlItem.fileSize.value) * 100)
            } else {
                sizeText = byteLengthDescribe(dlItem.rcvSize.value) + "/" + "??"
                rateText = "??%"
            }
        }
        
        DispatchQueue.main.async {
            self.sizeLabel.text = sizeText
            self.rateLabel.text = rateText
        }
    }

    private func updateStatusUI() {
        DispatchQueue.main.async {
            self.statusLabel.text = self.dlItem.status.value.string
            self.statusLabel.textColor = self.dlItem.status.value.color
            if case let .failed(reason) = self.dlItem.status.value {
                self.statusDescLabel.text = reason
            } else {
                self.statusDescLabel.text = ""
            }

            self.sizeLabel.isHidden = self.dlItem.status.value.isEqual(oneOf: .idle, .waiting)
            self.rateLabel.isHidden = self.dlItem.status.value.isEqual(oneOf: .idle, .waiting)
            self.speedLabel.isHidden = (self.dlItem.status.value != .loading)
        }
    }
    
    private func updateSpeedUI() {
        DispatchQueue.main.async {
            self.speedLabel.text = self.byteLengthDescribe(self.dlItem.speed.value) + "/S"
        }
    }
    
    private func byteLengthDescribe(_ byteLen: UInt) -> String {
        if byteLen > 1024 * 1024 {
            return String(format: "%.2fMB", Float(byteLen) / (1024 * 1024))
        } else if byteLen > 1024 {
            return String(format: "%.2fKB", Float(byteLen) / 1024)
        } else {
            return String(format: "%zdB", byteLen)
        }
    }
}

extension IVDownloadStatus {
    var string: String {
        switch self {
        case .idle:      return "⬇️下载"
        case .waiting:   return "🕙等待"
        case .loading:   return "⏸️暂停"
        case .paused:    return "▶️恢复"
        case .failed:    return "💔失败"
        case .finished:  return "✅完成"
        }
    }

    var color: UIColor {
        switch self {
        case .idle:     return .blue
        case .waiting:  return .gray
        case .loading:  return .cyan
        case .paused:   return .orange
        case .failed:   return .red
        case .finished: return .green
        }
    }
}

class IVMediaPlayerViewController: UIViewController {
    /// 播放器
    private var mediaPlayer: IJKFFMoviePlayerController?
    /// 媒体文件路径
    var mediaPath: String
    
    var currTimeLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 10)
        $0.textAlignment = .center
    }
    var totalTimeLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 10)
        $0.textAlignment = .center
    }
    var slider = UISlider()
    
    init(mediaPath: String) {
        self.mediaPath = mediaPath
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .black
        self.title = (mediaPath as NSString).lastPathComponent

        view.addSubview(slider)
        view.addSubview(currTimeLabel)
        view.addSubview(totalTimeLabel)

        slider.snp.makeConstraints { (make) in
            make.height.equalTo(30)
            make.bottom.equalTo(view.snp.bottomMargin).offset(-20)
            make.left.equalTo(currTimeLabel.snp.right)
            make.right.equalTo(totalTimeLabel.snp.left)
        }

        currTimeLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(44)
            make.height.equalTo(30)
            make.centerY.equalTo(slider)
        }

        totalTimeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.width.equalTo(44)
            make.height.equalTo(30)
            make.centerY.equalTo(slider)
        }
             
        slider.addEvent(.valueChanged) { [weak self] _ in
            guard let `self` = self, let mediaPlayer = self.mediaPlayer else { return }
            mediaPlayer.currentPlaybackTime = Double(self.slider.value) * mediaPlayer.duration
        }
        play()
    }
            
    func play() {
        let url = URL(fileURLWithPath: mediaPath)
        if let newMediaPlayer = IJKFFMoviePlayerController(contentURL: url, with: IJKFFOptions.byDefault()) {
            newMediaPlayer.scalingMode = .aspectFit
            newMediaPlayer.shouldAutoplay = true
            newMediaPlayer.playbackVolume = 1.0
            newMediaPlayer.prepareToPlay()
            
            view.insertSubview(newMediaPlayer.view, at: 0)
            newMediaPlayer.view.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            
            mediaPlayer = newMediaPlayer
            mediaPlayer?.play()
            updateProgress()
        }
    }
        
    @objc func updateProgress() {
        guard let player = mediaPlayer else { return }
        logInfo("currentTime: \(player.currentPlaybackTime) duration:\(player.duration)")
        if player.duration > 0 {
            slider.value = Float(player.currentPlaybackTime / player.duration)
            currTimeLabel.text = String(format: "%02d:%02d", UInt(player.currentPlaybackTime) / 60, UInt(player.currentPlaybackTime) % 60)
            totalTimeLabel.text = String(format: "%02d:%02d", UInt(player.duration) / 60, UInt(player.duration) % 60)
        }
        
        self.perform(#selector(updateProgress), with: nil, afterDelay: 0.5)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        mediaPlayer?.shutdown()
        mediaPlayer = nil
    }

}

